"""Validate the generated CSVs against the star-schema rules and built-in behavior.

The same rules are implemented in sql/04_validate.sql for SSMS. Thresholds live here
and are copied into that script; change both together.
"""

from __future__ import annotations

import csv
import statistics
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path

from model_schema import (
    AS_OF,
    CALENDAR_END,
    CALENDAR_START,
    CLOSED_BEFORE,
    CURRENT_APPS,
    EID_ADHA,
    EID_FITR,
    HIGH_RISK_BANKS,
    LEGACY_APPS,
    PEAK_HOURS,
    RAMADAN_END,
    RAMADAN_START,
    REJECT_REASONS,
    TABLES,
    datediff_minutes,
    headers,
    in_range,
)

FULL_SCALE_CUSTOMERS = 50_000
PAYMENT_MIN = 900_000
PAYMENT_MAX = 1_150_000


class Report:
    def __init__(self):
        self.rows: list[tuple[str, str, str]] = []
        self.funnel: list[tuple[int, str, int, int, int]] = []

    def add(self, name: str, status: str, detail: str) -> None:
        self.rows.append((name, status, detail))

    def check(self, name: str, passed: bool, detail: str) -> None:
        self.add(name, "PASS" if passed else "FAIL", detail)

    def info(self, name: str, detail: str) -> None:
        self.add(name, "INFO", detail)

    @property
    def failed(self) -> bool:
        return any(status == "FAIL" for _name, status, _detail in self.rows)

    def text(self) -> str:
        lines = [f"{status:<6}  {name}: {detail}" for name, status, detail in self.rows]
        fails = sum(1 for _n, status, _d in self.rows if status == "FAIL")
        passes = sum(1 for _n, status, _d in self.rows if status == "PASS")
        lines.append(f"{passes} passed, {fails} failed")
        return "\n".join(lines)

    def markdown(self) -> str:
        lines = [
            "# Generation report",
            "",
            "Synthetic digital-bank star schema. Checks mirror `sql/04_validate.sql`.",
            "",
            "| Status | Check | Detail |",
            "| --- | --- | --- |",
        ]
        for name, status, detail in self.rows:
            safe = detail.replace("|", "/")
            lines.append(f"| {status} | {name} | {safe} |")
        if self.funnel:
            lines.extend(
                [
                    "",
                    "## Onboarding funnel",
                    "",
                    "| Step | Name | Attempted | Passed | Drop from previous pass |",
                    "| --- | --- | ---: | ---: | ---: |",
                ]
            )
            for order, name, attempted, passed, drop in self.funnel:
                lines.append(f"| {order} | {name} | {attempted:,} | {passed:,} | {drop:,} |")
        lines.append("")
        return "\n".join(lines)


def read_dicts(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def parse_dt(value: str) -> datetime:
    return datetime.strptime(value, "%Y-%m-%d %H:%M:%S")


def parse_date(value: str) -> datetime:
    return datetime.strptime(value, "%Y-%m-%d")


def as_int(value: str):
    if value is None or value == "":
        return None
    return int(value)


def validate(csv_dir: Path) -> Report:
    report = Report()
    csv_dir = Path(csv_dir)

    manifest = {row["TableName"]: int(row["ExpectedRows"]) for row in read_dicts(csv_dir / "LoadManifest.csv")}
    load_files = read_dicts(csv_dir / "LoadFiles.csv")
    file_counts: dict[str, int] = defaultdict(int)
    for item in load_files:
        path = csv_dir / item["FileName"]
        with path.open(encoding="utf-8") as handle:
            actual = max(sum(1 for _ in handle) - 1, 0)
        expected = int(item["ExpectedRows"])
        file_counts[item["TableName"]] += actual
        report.check(
            f"File {item['FileName']}",
            actual == expected and path.exists(),
            f"rows {actual:,}; manifest {expected:,}",
        )
    for table, expected in manifest.items():
        report.check(
            f"Manifest {table}",
            file_counts[table] == expected,
            f"files sum to {file_counts[table]:,}; manifest {expected:,}",
        )

    customers = read_dicts(csv_dir / "DimCustomer.csv")
    accounts = read_dicts(csv_dir / "DimAccount.csv")
    channels = read_dicts(csv_dir / "DimChannel.csv")
    steps = read_dicts(csv_dir / "DimOnboardingStep.csv")
    reasons = read_dicts(csv_dir / "DimFailureReason.csv")
    banks = read_dicts(csv_dir / "DimBank.csv")
    dates = read_dicts(csv_dir / "DimDate.csv")
    times = read_dicts(csv_dir / "DimTime.csv")
    applications = read_dicts(csv_dir / "FactApplication.csv")
    events = read_dicts(csv_dir / "FactOnboardingEvents.csv")

    for table, rows in (
        ("DimCustomer", customers),
        ("DimAccount", accounts),
        ("DimChannel", channels),
        ("DimOnboardingStep", steps),
        ("DimFailureReason", reasons),
        ("DimBank", banks),
        ("DimDate", dates),
        ("DimTime", times),
        ("FactApplication", applications),
        ("FactOnboardingEvents", events),
    ):
        actual_header = list(rows[0].keys()) if rows else headers(table)
        # Header-only files still need a header check. DictReader on empty yields no rows
        # but we already counted lines. Re-read the header explicitly when empty.
        if not rows:
            with (csv_dir / f"{table}.csv").open(encoding="utf-8") as handle:
                actual_header = next(csv.reader(handle))
        report.check(f"Header {table}", actual_header == headers(table), "column order matches the schema")

    step_name = {int(row["StepKey"]): row["StepName"] for row in steps}
    step_order = {int(row["StepKey"]): int(row["StepOrder"]) for row in steps}
    reason_applies = {int(row["FailureReasonKey"]): row["AppliesTo"] for row in reasons}
    channel_name = {int(row["ChannelKey"]): row["ChannelName"] for row in channels}
    bank_name = {int(row["BankKey"]): row["BankName"] for row in banks}
    date_flags = {}
    for row in dates:
        value = parse_date(row["FullDate"]).date()
        date_flags[int(row["DateKey"])] = {
            "date": value,
            "salary": row["IsSalaryWeek"] == "1",
            "eid": row["IsEid"] == "1",
            "ramadan": row["IsRamadan"] == "1",
            "weekend": row["IsWeekend"] == "1",
            "eid_name": row["EidName"],
            "month_end": row["IsMonthEnd"] == "1",
        }
    peak_hours = {int(row["TimeKey"]) for row in times if row["IsPeakHour"] == "1"}

    calendar_ok = True
    calendar_detail = "salary week, Ramadan, Eid, weekend, and month-end flags match the scenario calendar"
    for key, flag in date_flags.items():
        value = flag["date"]
        eid_name = ""
        if in_range(value, EID_FITR):
            eid_name = "Eid ul Fitr"
        elif in_range(value, EID_ADHA):
            eid_name = "Eid ul Adha"
        expected_salary = value.day == 1 or value.day >= 25
        if (
            flag["salary"] != expected_salary
            or flag["eid"] != (eid_name != "")
            or flag["eid_name"] != eid_name
            or flag["ramadan"] != (RAMADAN_START <= value <= RAMADAN_END)
            or flag["weekend"] != (value.isoweekday() >= 6)
            or flag["month_end"] != (value.day >= 28)
            or not (CALENDAR_START <= value <= CALENDAR_END)
            or key != value.year * 10000 + value.month * 100 + value.day
        ):
            calendar_ok = False
            calendar_detail = f"mismatch on {value.isoformat()}"
            break
    report.check("Calendar flags", calendar_ok, calendar_detail)
    report.check("Peak hours", peak_hours == set(PEAK_HOURS), f"flagged hours {sorted(peak_hours)}")

    customer_ids = {int(row["CustomerKey"]) for row in customers}
    account_by_key = {int(row["AccountKey"]): row for row in accounts}
    account_by_customer = {int(row["CustomerKey"]): row for row in accounts}
    cnic_bad = [
        row["CNICToken"]
        for row in customers
        if len(row["CNICToken"]) != 16 or any(ch not in "0123456789abcdef" for ch in row["CNICToken"]) or row["CNICToken"].isdigit() and len(row["CNICToken"]) == 13
    ]
    report.check("CNIC tokens", not cnic_bad, f"{len(cnic_bad)} tokens are not 16-char synthetic hashes")
    city_province: dict[str, set[str]] = defaultdict(set)
    android = 0
    for row in customers:
        city_province[row["City"]].add(row["Province"])
        android += row["DeviceOS"] == "Android"
    multi_province = [city for city, provinces in city_province.items() if len(provinces) > 1]
    report.check("City belongs to one province", not multi_province, f"{len(multi_province)} cities span provinces")
    android_share = android / len(customers)
    report.check(
        "Android-heavy device mix",
        0.75 <= android_share <= 0.82,
        f"Android share {android_share:.1%}",
    )

    # Events aggregated per customer.
    per_customer = defaultdict(list)
    event_clock_bad = 0
    event_reason_bad = 0
    for row in events:
        per_customer[int(row["CustomerKey"])].append(row)
        stamp = parse_dt(row["EventDateTime"])
        reason_key = as_int(row["FailureReasonKey"])
        order = step_order[int(row["StepKey"])]
        if int(row["DateKey"]) != int(stamp.strftime("%Y%m%d")) or int(row["TimeKey"]) != stamp.hour or int(row["DateKey"]) not in date_flags:
            event_clock_bad += 1
        applies = reason_applies.get(reason_key)
        if row["Outcome"] not in ("Pass", "Fail"):
            event_reason_bad += 1
        elif row["Outcome"] == "Pass" and reason_key is not None:
            event_reason_bad += 1
        elif row["Outcome"] == "Fail" and (reason_key is None or applies is None):
            event_reason_bad += 1
        elif reason_key is not None and order <= 7 and applies not in ("Onboarding", "Both"):
            event_reason_bad += 1
        elif reason_key is not None and order == 8 and applies not in ("Payment", "Both"):
            event_reason_bad += 1
    report.check("Onboarding date and time keys match the timestamp", event_clock_bad == 0, f"{event_clock_bad} events")
    report.check("Onboarding failure reasons match the step", event_reason_bad == 0, f"{event_reason_bad} events")

    passed = defaultdict(set)
    attempted = defaultdict(set)
    recon_mismatch = 0
    for app in applications:
        customer_key = int(app["CustomerKey"])
        rows = per_customer.get(customer_key, [])
        if not rows:
            recon_mismatch += 1
            continue
        parsed = []
        for row in rows:
            parsed.append(
                (
                    parse_dt(row["EventDateTime"]),
                    int(row["EventKey"]),
                    step_order[int(row["StepKey"])],
                    int(row["StepKey"]),
                    row["Outcome"],
                    as_int(row["FailureReasonKey"]),
                    int(row["RetryNumber"]),
                )
            )
        parsed.sort()
        for _dt, _key, order, _step, outcome, _reason, _retry in parsed:
            attempted[order].add(customer_key)
            if outcome == "Pass":
                passed[order].add(customer_key)
        start_dt = parsed[0][0]
        step6 = [item for item in parsed if item[2] == 6 and item[4] == "Pass"]
        completed = bool(step6)
        end_dt = step6[0][0] if completed else parsed[-1][0]
        terminal = parsed[-1] if not completed else None
        retries = sum(1 for item in parsed if item[6] > 0)
        minutes = datediff_minutes(start_dt, end_dt) if completed else None
        failed_step = None if completed else terminal[3]
        if completed:
            derived_status = "Completed"
        elif terminal[5] in REJECT_REASONS:
            derived_status = "Rejected"
        else:
            derived_status = "Abandoned"
        account = account_by_customer.get(customer_key)
        derived_account = int(account["AccountKey"]) if account else None
        if (
            app["FinalStatus"] != derived_status
            or as_int(app["AccountKey"]) != derived_account
            or as_int(app["MinutesToOpen"]) != minutes
            or int(app["TotalRetries"]) != retries
            or as_int(app["FailedStepKey"]) != failed_step
            or app["StartDateTime"] != start_dt.strftime("%Y-%m-%d %H:%M:%S")
            or app["EndDateTime"] != end_dt.strftime("%Y-%m-%d %H:%M:%S")
            or app["ReferralSource"] != rows[0]["ReferralSource"]
            or int(app["StartDateKey"]) != int(start_dt.strftime("%Y%m%d"))
            or int(app["StartTimeKey"]) != start_dt.hour
            or int(app["EndDateKey"]) != int(end_dt.strftime("%Y%m%d"))
            or int(app["EndTimeKey"]) != end_dt.hour
            or int(app["StartDateKey"]) not in date_flags
            or int(app["EndDateKey"]) not in date_flags
        ):
            recon_mismatch += 1
            continue
    customer_by_key = {int(row["CustomerKey"]): row for row in customers}
    app_by_customer = {int(row["CustomerKey"]): row for row in applications}
    signup_mismatch = 0
    for app in applications:
        customer = customer_by_key[int(app["CustomerKey"])]
        if customer["SignupDate"] != app["StartDateTime"][:10] or int(customer["SignupDateKey"]) != int(app["StartDateKey"]):
            signup_mismatch += 1
    report.check("Signup date matches journey start", signup_mismatch == 0, f"{signup_mismatch} mismatches")
    report.check(
        "Application matches onboarding events",
        recon_mismatch == 0,
        f"{recon_mismatch} applications disagree with FactOnboardingEvents",
    )

    all_customers = set(customer_ids)
    report.check(
        "Step key matches step order",
        all(int(row["StepKey"]) == int(row["StepOrder"]) for row in steps),
        "DimOnboardingStep.StepKey is the funnel order",
    )
    report.check(
        "Every customer starts at download",
        attempted.get(1) == all_customers and len(applications) == len(customers),
        f"step 1 attempted {len(attempted.get(1, ())):,}; applications {len(applications):,}",
    )
    continuity_bad = 0
    for order in range(2, 7):
        if attempted.get(order, set()) != passed.get(order - 1, set()):
            continuity_bad += 1
    report.check(
        "Funnel is sequential through account opening",
        continuity_bad == 0,
        "customers at each of steps 2-6 are exactly those who passed the previous step",
    )

    previous_pass = len(customers)
    drops = []
    for order in range(1, 7):
        attempt_n = len(attempted.get(order, ()))
        pass_n = len(passed.get(order, ()))
        drop = previous_pass - pass_n
        drops.append((drop, order))
        report.funnel.append((order, step_name[order], attempt_n, pass_n, drop))
        previous_pass = pass_n
    heaviest = max(drops)[1]
    report.check(
        "Heaviest drop is NADRA liveness",
        heaviest == 4,
        "; ".join(f"step {order} drop {drop:,}" for drop, order in drops),
    )

    legacy_pass = []
    current_pass = []
    for customer_key, rows in per_customer.items():
        nadra = [row for row in rows if step_order[int(row["StepKey"])] == 4]
        if not nadra:
            continue
        did_pass = any(row["Outcome"] == "Pass" for row in nadra)
        customer = customer_by_key[customer_key]
        if customer["DeviceOS"] == "Android" and customer["AppVersion"] in LEGACY_APPS:
            legacy_pass.append(did_pass)
        if customer["AppVersion"] in CURRENT_APPS:
            current_pass.append(did_pass)
    legacy_rate = sum(legacy_pass) / len(legacy_pass)
    current_rate = sum(current_pass) / len(current_pass)
    report.check(
        "Older Android app builds fail NADRA more often",
        current_rate >= legacy_rate + 0.08,
        f"legacy Android pass {legacy_rate:.1%} ({len(legacy_pass):,}); current app pass {current_rate:.1%} ({len(current_pass):,})",
    )

    # Payments.
    payment_files = sorted(csv_dir.glob("FactPayments_*.csv"))
    amounts: list[float] = []
    channel_total = defaultdict(int)
    channel_fail = defaultdict(int)
    peak_fail = peak_n = off_fail = off_n = 0
    first_fail = first_n = later_fail = later_n = 0
    retry_success = retry_n = 0
    bank_volume = defaultdict(int)
    bank_timeout = defaultdict(int)
    failed_value = 0.0
    latency_sum = 0
    payment_n = 0
    daily = defaultdict(int)
    payment_recon = 0
    orphan_retry = 0
    before_open = 0
    clock_bad = 0
    reason_domain_bad = 0
    success_by_account = defaultdict(int)
    raast_success_accounts = set()
    earliest = {}
    activation = {}
    payment_lookup = {}
    step8_bad = 0

    for path in payment_files:
        with path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            report.check(f"Header {path.name}", reader.fieldnames == headers("FactPayments"), "column order matches the schema")
            for row in reader:
                payment_n += 1
                account_key = int(row["AccountKey"])
                status = row["Status"]
                channel_key = int(row["ChannelKey"])
                bank_key = int(row["BankKey"])
                reason_key = as_int(row["FailureReasonKey"])
                stamp = parse_dt(row["PaymentDateTime"])
                amount = float(row["AmountPKR"])
                amounts.append(amount)
                if (
                    int(row["DateKey"]) != int(stamp.strftime("%Y%m%d"))
                    or int(row["TimeKey"]) != stamp.hour
                    or int(row["DateKey"]) not in date_flags
                ):
                    clock_bad += 1
                channel_total[channel_key] += 1
                bank_volume[bank_key] += 1
                latency_sum += int(row["LatencyMs"])
                date_key = int(row["DateKey"])
                daily[date_key] += 1
                failed = status == "Failed"
                if failed:
                    channel_fail[channel_key] += 1
                    failed_value += amount
                if reason_key == 12:
                    bank_timeout[bank_key] += 1
                if int(row["TimeKey"]) in peak_hours:
                    peak_n += 1
                    peak_fail += failed
                else:
                    off_n += 1
                    off_fail += failed
                if row["IsRetry"] == "1":
                    retry_n += 1
                    retry_success += status == "Success"
                if (failed and reason_key is None) or ((not failed) and reason_key is not None):
                    reason_domain_bad += 1
                elif reason_key is not None and reason_applies.get(reason_key) not in ("Payment", "Both"):
                    reason_domain_bad += 1
                account = account_by_key.get(account_key)
                if account is None or stamp < parse_dt(account["OpenDateTime"]):
                    before_open += 1
                if status == "Success":
                    success_by_account[account_key] += 1
                    activation[account_key] = min(activation.get(account_key, 99999999), date_key)
                    if channel_key in (1, 2):
                        raast_success_accounts.add(account_key)
                current = earliest.get(account_key)
                marker = (stamp, int(row["PaymentKey"]))
                if current is None or marker < current[0]:
                    earliest[account_key] = (marker, row)
                original = as_int(row["OriginalPaymentKey"])
                payment_lookup[int(row["PaymentKey"])] = (account_key, row["IsRetry"], original, stamp)

    for payment_key, (account_key, is_retry, original, _stamp) in payment_lookup.items():
        if is_retry == "1":
            parent = payment_lookup.get(original or -1)
            if parent is None or parent[1] != "0" or parent[0] != account_key:
                orphan_retry += 1
        elif original is not None:
            orphan_retry += 1

    for app in applications:
        customer_key = int(app["CustomerKey"])
        account = account_by_customer.get(customer_key)
        if app["FinalStatus"] != "Completed":
            if app["FirstPaymentStatus"] != "Not attempted" or app["FirstPaymentDateKey"] or app["ActivationDateKey"]:
                payment_recon += 1
            continue
        account_key = int(account["AccountKey"])
        first = earliest.get(account_key)
        if first is None:
            if app["FirstPaymentStatus"] != "Not attempted" or app["ActivationDateKey"] or app["FirstPaymentDateKey"]:
                payment_recon += 1
            continue
        first_row = first[1]
        act = activation.get(account_key)
        if (
            app["FirstPaymentStatus"] != first_row["Status"]
            or int(app["FirstPaymentDateKey"]) != int(first_row["DateKey"])
            or as_int(app["ActivationDateKey"]) != act
        ):
            payment_recon += 1
        # Step 8 must describe that same first attempt.
        step8 = [
            row
            for row in per_customer[customer_key]
            if step_order[int(row["StepKey"])] == 8
        ]
        if len(step8) != 1:
            step8_bad += 1
            continue
        expected_outcome = "Pass" if first_row["Status"] == "Success" else "Fail"
        if (
            step8[0]["Outcome"] != expected_outcome
            or step8[0]["EventDateTime"] != first_row["PaymentDateTime"]
            or as_int(step8[0]["FailureReasonKey"]) != as_int(first_row["FailureReasonKey"])
        ):
            step8_bad += 1

    # Customers with a step 8 and no payment, or a payment and no step 8.
    pay_customers = {int(account_by_key[key]["CustomerKey"]) for key in earliest}
    step8_customers = {key for key, rows in per_customer.items() if any(step_order[int(row["StepKey"])] == 8 for row in rows)}
    report.check("Payment date and time keys match the timestamp", clock_bad == 0, f"{clock_bad} payments have a date or hour that does not match")
    report.check("Payments stay inside opened accounts", before_open == 0, f"{before_open} payments missing an open account or dated before it")
    report.check("Failure reasons match payment status", reason_domain_bad == 0, f"{reason_domain_bad} reason/status mismatches")
    report.check("Retries point at the original attempt", orphan_retry == 0, f"{orphan_retry} broken retry links")
    report.check("Application payment summary matches FactPayments", payment_recon == 0, f"{payment_recon} mismatches")
    report.check(
        "First-payment step matches the first attempt",
        step8_bad == 0 and step8_customers == pay_customers,
        f"{step8_bad} step mismatches; step customers {len(step8_customers):,}; paying customers {len(pay_customers):,}",
    )

    status_bad = 0
    raast_bad = 0
    closed_bad = 0
    for account in accounts:
        key = int(account["AccountKey"])
        successes = success_by_account[key]
        if account["Status"] == "active" and successes < 1:
            status_bad += 1
        if account["Status"] == "dormant" and successes != 0:
            status_bad += 1
        if account["Status"] == "closed" and parse_date(account["OpenDate"]).date() >= CLOSED_BEFORE:
            closed_bad += 1
        if key in raast_success_accounts and account["RaastIDLinked"] != "Y":
            raast_bad += 1
        app = app_by_customer[int(account["CustomerKey"])]
        if app["FinalStatus"] != "Completed" or app["EndDateTime"] != account["OpenDateTime"]:
            status_bad += 1
    dormant_rate = sum(row["Status"] == "dormant" for row in accounts) / len(accounts)
    report.check("Account status matches payment activity", status_bad == 0, f"{status_bad} status mismatches")
    report.check("Closed accounts were opened before 1 Apr 2026", closed_bad == 0, f"{closed_bad} closed too recently")
    report.check("Raast ID is linked after a successful Raast payment", raast_bad == 0, f"{raast_bad} accounts")
    report.check("Dormancy is material", 0.12 <= dormant_rate <= 0.40, f"dormant accounts {dormant_rate:.1%}")

    def rate(fail, total):
        return fail / total if total else 0.0

    raast_rate = rate(channel_fail[1], channel_total[1])
    ibft_rate = rate(channel_fail[3], channel_total[3])
    bill_rate = rate(channel_fail[5], channel_total[5])
    report.check(
        "IBFT fails more often than Raast P2P",
        ibft_rate >= raast_rate + 0.03,
        f"IBFT {ibft_rate:.1%}; Raast P2P {raast_rate:.1%}",
    )
    report.check(
        "Bill pay fails more often than Raast P2P",
        bill_rate >= raast_rate + 0.03,
        f"bill pay {bill_rate:.1%}; Raast P2P {raast_rate:.1%}",
    )

    # First vs later failure, from the earliest map and overall fails.
    for _key, (_marker, row) in earliest.items():
        first_n += 1
        first_fail += row["Status"] == "Failed"
    later_n = payment_n - first_n
    later_fail = sum(channel_fail.values()) - first_fail
    first_rate = rate(first_fail, first_n)
    later_rate = rate(later_fail, later_n)
    report.check(
        "First payment fails more often than later payments",
        first_rate >= later_rate + 0.03,
        f"first {first_rate:.1%}; later {later_rate:.1%}",
    )
    report.check(
        "Failures are higher at peak hours",
        rate(peak_fail, peak_n) >= rate(off_fail, off_n) * 1.12,
        f"peak {rate(peak_fail, peak_n):.1%}; off-peak {rate(off_fail, off_n):.1%}",
    )
    recovery = rate(retry_success, retry_n)
    report.check("Some retries recover and some do not", 0.55 <= recovery <= 0.85, f"retry success {recovery:.1%} of {retry_n:,}")

    high_risk_keys = {key for key, name in bank_name.items() if name in HIGH_RISK_BANKS}
    high_volume = sum(bank_volume[key] for key in high_risk_keys)
    timeout_total = sum(bank_timeout.values())
    timeout_high = sum(bank_timeout[key] for key in high_risk_keys)
    report.check(
        "Bank timeouts concentrate in a few beneficiary banks",
        timeout_total > 0 and high_volume / payment_n < 0.15 and timeout_high / timeout_total >= 0.50,
        f"Allied/JS/BOP are {high_volume / payment_n:.1%} of payments and {timeout_high / timeout_total:.1%} of bank timeouts ({timeout_total:,})",
    )

    top_channel = max(channel_total, key=channel_total.get)
    p2p_bill_share = (channel_total[1] + channel_total[5]) / payment_n
    report.check(
        "Small P2P and bill payments dominate the count",
        top_channel == 1 and p2p_bill_share >= 0.45,
        f"top channel {channel_name[top_channel]}; P2P+bill {p2p_bill_share:.1%}",
    )
    mean_amount = statistics.fmean(amounts)
    median_amount = statistics.median(amounts)
    report.check(
        "Amounts are skewed, with a long tail",
        median_amount * 2 < mean_amount,
        f"median {median_amount:,.0f} PKR; mean {mean_amount:,.0f} PKR",
    )

    def daily_avg(predicate) -> float:
        values = []
        for key, flag in date_flags.items():
            if flag["date"] < CALENDAR_START or flag["date"] > AS_OF:
                continue
            if predicate(flag):
                values.append(daily.get(key, 0))
        return statistics.fmean(values) if values else 0.0

    normal_avg = daily_avg(lambda flag: not flag["salary"] and not flag["eid"])
    salary_avg = daily_avg(lambda flag: flag["salary"] and not flag["eid"])
    eid_avg = daily_avg(lambda flag: flag["eid"])
    report.check(
        "Salary week has more payments per day",
        salary_avg >= normal_avg * 1.50,
        f"salary-week {salary_avg:,.0f}/day; other days {normal_avg:,.0f}/day",
    )
    report.check(
        "Eid has more payments per day",
        eid_avg >= normal_avg * 2.0,
        f"Eid {eid_avg:,.0f}/day; other days {normal_avg:,.0f}/day",
    )

    if len(customers) >= 40_000:
        report.check(
            "Scale is about 50,000 applications and 1M payments",
            len(customers) == FULL_SCALE_CUSTOMERS and PAYMENT_MIN <= payment_n <= PAYMENT_MAX,
            f"{len(customers):,} applications; {payment_n:,} payments",
        )

    completed_n = sum(app["FinalStatus"] == "Completed" for app in applications)
    conversion = completed_n / len(applications)
    minutes = [int(app["MinutesToOpen"]) for app in applications if app["MinutesToOpen"]]
    activated_30 = 0
    for app in applications:
        if app["FinalStatus"] != "Completed" or not app["ActivationDateKey"]:
            continue
        account = account_by_customer[int(app["CustomerKey"])]
        opened = parse_date(account["OpenDate"]).date()
        activated = date_flags[int(app["ActivationDateKey"])]["date"]
        if (activated - opened).days <= 30:
            activated_30 += 1
    activation_rate = activated_30 / completed_n if completed_n else 0
    first_success = sum(row["Status"] == "Success" for _m, row in earliest.values()) / len(earliest) if earliest else 0
    report.info("Conversion %", f"{conversion:.1%} completed ({completed_n:,} of {len(applications):,})")
    report.info("Median minutes to open", f"{statistics.median(minutes):,.0f}" if minutes else "n/a")
    report.info("Activation rate within 30 days", f"{activation_rate:.1%} of completed applications")
    report.info("First-payment success rate", f"{first_success:.1%}")
    report.info("Failed payment value", f"{failed_value:,.0f} PKR")
    report.info("Average latency", f"{latency_sum / payment_n:,.0f} ms" if payment_n else "n/a")
    report.info("Dormancy rate", f"{dormant_rate:.1%} of opened accounts")
    for key in sorted(channel_total):
        report.info(
            f"Failure rate {channel_name[key]}",
            f"{rate(channel_fail[key], channel_total[key]):.1%} of {channel_total[key]:,}",
        )
    return report


if __name__ == "__main__":
    target = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parent / "csv")
    result = validate(target)
    print(result.text())
    sys.exit(1 if result.failed else 0)
