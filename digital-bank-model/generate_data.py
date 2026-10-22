"""Generate the synthetic digital-bank star schema as CSV files.

Default scale matches the working session: 50,000 applications over 12 months
and about 1 million payment attempts, including retries.

Run from this folder:
    python generate_data.py
"""

from __future__ import annotations

import argparse
import csv
import hashlib
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

import numpy as np

from model_schema import (
    ABANDONED,
    AS_OF,
    BANK_TIMEOUT,
    BANKS,
    BILLER_DOWNTIME,
    CALENDAR_END,
    CALENDAR_START,
    CHANNELS,
    CITIES,
    CLOSED_BEFORE,
    CURRENT_APPS,
    DOCUMENT_UNCLEAR,
    DUPLICATE,
    EID_ADHA,
    EID_FITR,
    FAILURE_REASONS,
    FRAUD_BLOCK,
    HIGH_RISK_BANKS,
    INSUFFICIENT_FUNDS,
    LEGACY_APPS,
    LIMIT_EXCEEDED,
    LIVENESS_FAILED,
    NADRA_MISMATCH,
    OLDER_ANDROID_BRANDS,
    ONBOARDING_STEPS,
    OTP_EXPIRED,
    PEAK_HOURS,
    RAIL_TIMEOUT,
    RAMADAN_END,
    RAMADAN_START,
    REJECT_REASONS,
    RETRYABLE_REASONS,
    SANCTIONS,
    TABLES,
    WRONG_ACCOUNT,
    date_key,
    datediff_minutes,
    headers,
    in_range,
)
from validate_csvs import validate

EPOCH = datetime(CALENDAR_START.year, CALENDAR_START.month, CALENDAR_START.day)
AS_OF_ORD = (AS_OF - CALENDAR_START).days
CAL_END_ORD = (CALENDAR_END - CALENDAR_START).days
MAX_MINUTE = (CAL_END_ORD + 1) * 1440 - 1

HOUR_WEIGHTS = np.array(
    [1, 1, 1, 1, 1, 2, 4, 6, 8, 9, 8, 7, 10, 11, 10, 8, 7, 8, 9, 12, 13, 12, 8, 4],
    dtype=np.float64,
)

CHANNEL_AMOUNT_MEDIAN = {1: 800, 2: 650, 3: 5000, 4: 3000, 5: 2200, 6: 300, 7: 1500}
HIGH_RISK_KEYS = {row[0] for row in BANKS if row[1] in HIGH_RISK_BANKS}
BENEFICIARY = [(key, weight) for key, _name, _kind, weight in BANKS if weight > 0]
BILLERS = [key for key, _name, kind, _w in BANKS if kind == "Biller" and key <= 25]
TELCOS = [26, 27, 28, 29]
QR_MERCHANTS = [30, 31, 32]
CARD_MERCHANTS = [33, 34]


def norm(weights) -> np.ndarray:
    arr = np.asarray(weights, dtype=np.float64)
    total = arr.sum()
    if total <= 0:
        raise ValueError("weights must sum to a positive number")
    return arr / total


def choice(rng: np.random.Generator, options, weights, size=None):
    options = list(options)
    pick = rng.choice(len(options), size=size, p=norm(weights))
    if size is None:
        return options[int(pick)]
    return [options[int(i)] for i in np.atleast_1d(pick)]


def dt_from_minute(minute: int) -> datetime:
    return EPOCH + timedelta(minutes=int(minute))


def fmt_dt(minute: int) -> str:
    return dt_from_minute(minute).strftime("%Y-%m-%d %H:%M:%S")


def fmt_date(minute: int) -> str:
    return dt_from_minute(minute).strftime("%Y-%m-%d")


def ymd(minute: int) -> int:
    value = dt_from_minute(minute)
    return date_key(value.date())


def hour_of(minute: int) -> int:
    return (int(minute) % 1440) // 60


def blank(value) -> str:
    if value is None or value == "":
        return ""
    return str(value)


def write_csv(path: Path, header: list[str], rows) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        for row in rows:
            if any(isinstance(cell, str) and ("," in cell or '"' in cell or "\n" in cell) for cell in row):
                raise ValueError(f"comma or quote in {path.name}: {row}")
            writer.writerow(row)
            count += 1
    return count


def build_calendar(rng_unused=None):
    days = []
    weights = []
    current = CALENDAR_START
    while current <= CALENDAR_END:
        eid_name = ""
        is_eid = 0
        if in_range(current, EID_FITR):
            is_eid = 1
            eid_name = "Eid ul Fitr"
        elif in_range(current, EID_ADHA):
            is_eid = 1
            eid_name = "Eid ul Adha"
        is_salary = int(current.day == 1 or current.day >= 25)
        is_ramadan = int(RAMADAN_START <= current <= RAMADAN_END)
        weight = 1.0
        if is_salary:
            weight *= 2.4
        if is_eid:
            weight *= 3.2
        if is_ramadan:
            weight *= 1.15
        days.append(
            {
                "date": current,
                "key": date_key(current),
                "salary": is_salary,
                "eid": is_eid,
                "eid_name": eid_name,
                "ramadan": is_ramadan,
                "weight": weight,
            }
        )
        weights.append(weight if current <= AS_OF else 0.0)
        current += timedelta(days=1)
    return days, np.asarray(weights, dtype=np.float64)


def simulate_onboarding(rng: np.random.Generator, customer_key: int, signup_ord: int, device_os: str, brand: str, app_version: str, referral: str):
    older_app = app_version in LEGACY_APPS
    older_android = device_os == "Android" and brand in OLDER_ANDROID_BRANDS
    hour = int(rng.choice(24, p=norm(HOUR_WEIGHTS)))
    clock = signup_ord * 1440 + hour * 60 + int(rng.integers(0, 60))
    start = clock
    events = []

    def add_event(step, outcome, reason, retry):
        events.append((customer_key, step, clock, outcome, reason, retry, referral))

    def fail_reason(kind: str) -> int:
        roll = float(rng.random())
        if kind == "download":
            return ABANDONED
        if kind == "otp":
            return OTP_EXPIRED if roll < 0.80 else ABANDONED
        if kind == "cnic":
            return DOCUMENT_UNCLEAR if roll < 0.85 else ABANDONED
        if kind == "nadra":
            if roll < 0.40:
                return LIVENESS_FAILED
            if roll < 0.75:
                return NADRA_MISMATCH
            if roll < 0.92:
                return DOCUMENT_UNCLEAR
            return ABANDONED
        if kind == "profile":
            return SANCTIONS if roll < 0.18 else ABANDONED
        if roll < 0.45:
            return DUPLICATE
        return SANCTIONS

    def pass_probability(kind: str, attempt: int) -> float:
        if kind == "download":
            return 0.998
        if kind == "otp":
            return 0.965 if attempt == 0 else 0.88
        if kind == "cnic":
            return 0.945 if attempt == 0 else 0.82
        if kind == "nadra":
            if older_android and older_app:
                base = 0.40
            elif older_android or older_app:
                base = 0.56
            elif device_os == "iOS" and not older_app:
                base = 0.86
            else:
                base = 0.78
            return min(0.94, base + 0.14 * attempt)
        if kind == "profile":
            return 0.968
        return 0.986

    max_retries = {"download": 0, "otp": 2, "cnic": 1, "nadra": 2, "profile": 0, "opened": 0}
    retry_takeup = {"otp": 0.70, "cnic": 0.62, "nadra": 0.78}
    sequence = (
        (1, "download"),
        (2, "otp"),
        (3, "cnic"),
        (4, "nadra"),
        (5, "profile"),
        (6, "opened"),
    )

    open_min = None
    failed_step = None
    final_status = None
    for step_key, kind in sequence:
        attempt = 0
        passed = False
        while True:
            reason = 0
            if float(rng.random()) < pass_probability(kind, attempt):
                add_event(step_key, "Pass", 0, attempt)
                passed = True
                if step_key == 6:
                    open_min = clock
                break
            reason = fail_reason(kind)
            add_event(step_key, "Fail", reason, attempt)
            can_retry = (
                reason in RETRYABLE_REASONS
                and attempt < max_retries[kind]
                and float(rng.random()) < retry_takeup.get(kind, 0)
            )
            if not can_retry:
                failed_step = step_key
                final_status = "Rejected" if reason in REJECT_REASONS else "Abandoned"
                break
            attempt += 1
            clock += int(rng.integers(3, 18))
        if not passed:
            break
        clock += int(rng.integers(1, 6))

    login_min = None
    will_pay = False
    if open_min is not None:
        final_status = "Completed"
        failed_step = None
        open_ord = open_min // 1440
        if open_ord <= AS_OF_ORD and float(rng.random()) < 0.84:
            login_min = min(MAX_MINUTE, open_min + int(rng.integers(5, 120)))
            events.append((customer_key, 7, login_min, "Pass", 0, 0, referral))
            if float(rng.random()) < 0.90:
                will_pay = True
        end_min = open_min
    else:
        end_min = events[-1][2]

    return {
        "events": events,
        "start_min": start,
        "end_min": end_min,
        "open_min": open_min,
        "login_min": login_min,
        "final_status": final_status,
        "failed_step": failed_step,
        "will_pay": will_pay,
        "referral": referral,
        "legacy_payment": older_android or older_app,
    }


def generate(customers: int, primary_payments: int, seed: int, out_dir: Path) -> None:
    rng = np.random.default_rng(seed)
    out_dir.mkdir(parents=True, exist_ok=True)
    days, day_weight = build_calendar()

    print(f"Simulating {customers:,} applications...")
    age_opts = ["18-24", "25-34", "35-44", "45-54", "55+"]
    gender_opts = ["Male", "Female"]
    occ_opts = ["Salaried", "Self-employed", "Student", "Housewife", "Freelancer"]
    net_opts = ["Jazz", "Telenor", "Zong", "Ufone"]
    app_opts = ["3.2.0", "3.8.1", "4.1.0", "4.4.2", "4.6.0"]
    ref_opts = ["Organic", "Facebook", "Google", "Friend referral", "Campus", "Branch QR"]
    android_brands = ["Samsung", "Xiaomi", "Oppo", "Vivo", "Infinix", "Tecno", "Realme", "Huawei"]
    city_weights = [row[3] for row in CITIES]
    occ_factor = {
        "Salaried": 1.45,
        "Self-employed": 1.10,
        "Freelancer": 1.00,
        "Student": 0.65,
        "Housewife": 0.55,
    }

    profiles = []
    journeys = []
    for key in range(1, customers + 1):
        city, province, urban, _weight = choice(rng, CITIES, city_weights)
        device_os = "Android" if float(rng.random()) < 0.78 else "iOS"
        brand = "Apple" if device_os == "iOS" else choice(rng, android_brands, [28, 16, 11, 10, 12, 9, 8, 6])
        app_version = choice(rng, app_opts, [0.14, 0.16, 0.22, 0.30, 0.18])
        occupation = choice(rng, occ_opts, [0.46, 0.18, 0.15, 0.09, 0.12])
        profile = {
            "key": key,
            "age": choice(rng, age_opts, [0.30, 0.40, 0.18, 0.08, 0.04]),
            "gender": choice(rng, gender_opts, [0.58, 0.42]),
            "occupation": occupation,
            "province": province,
            "city": city,
            "urban": urban,
            "network": choice(rng, net_opts, [0.38, 0.23, 0.27, 0.12]),
            "os": device_os,
            "brand": brand,
            "app": app_version,
            "signup_ord": int(rng.integers(0, AS_OF_ORD + 1)),
            "referral": choice(rng, ref_opts, [0.34, 0.20, 0.15, 0.15, 0.08, 0.08]),
        }
        journey = simulate_onboarding(
            rng, key, profile["signup_ord"], device_os, brand, app_version, profile["referral"]
        )
        profiles.append(profile)
        journeys.append(journey)

    payers = []
    accounts = []
    for profile, journey in zip(profiles, journeys):
        if journey["open_min"] is None:
            continue
        account_key = len(accounts) + 1
        journey["account_key"] = account_key
        account = {
            "key": account_key,
            "customer_key": profile["key"],
            "open_min": journey["open_min"],
            "login_min": journey["login_min"],
            "occupation": profile["occupation"],
            "legacy": journey["legacy_payment"],
            "will_pay": journey["will_pay"],
        }
        accounts.append(account)
        if journey["will_pay"]:
            payers.append(account)

    if not payers:
        raise RuntimeError("no paying accounts were generated")

    print(f"Completed accounts: {len(accounts):,}. Paying accounts: {len(payers):,}.")
    tenure = np.array([AS_OF_ORD - (acct["open_min"] // 1440) + 1 for acct in payers], dtype=np.int32)
    if np.any(tenure < 1):
        raise RuntimeError("payer with no eligible payment day")
    factor = np.array([occ_factor[acct["occupation"]] for acct in payers], dtype=np.float64)
    activity = np.minimum(rng.pareto(1.35, size=len(payers)) + 0.45, 25)
    weights = tenure * factor * activity
    extra = primary_payments - len(payers)
    if extra < 0:
        raise RuntimeError("primary payment target is below one payment per paying account")
    extra_counts = rng.multinomial(extra, norm(weights))
    counts = extra_counts + 1
    payer_keys = np.array([acct["key"] for acct in payers], dtype=np.int32)
    acct_index_in_payers = np.repeat(np.arange(len(payers)), counts)
    n_primary = int(counts.sum())
    print(f"Building {n_primary:,} primary payments...")

    acct_keys = payer_keys[acct_index_in_payers]
    open_mins = np.array([acct["open_min"] for acct in payers], dtype=np.int64)[acct_index_in_payers]
    login_mins = np.array([acct["login_min"] for acct in payers], dtype=np.int64)[acct_index_in_payers]
    legacy = np.array([acct["legacy"] for acct in payers], dtype=bool)[acct_index_in_payers]
    open_ord = (open_mins // 1440).astype(np.int32)

    date_ord = np.empty(n_primary, dtype=np.int32)
    sort_idx = np.argsort(open_ord, kind="mergesort")
    sorted_open = open_ord[sort_idx]
    cuts = np.flatnonzero(np.diff(sorted_open)) + 1
    starts = np.r_[0, cuts]
    ends = np.r_[cuts, n_primary]
    for start_i, end_i in zip(starts, ends):
        origin = int(sorted_open[start_i])
        eligible = np.arange(origin, AS_OF_ORD + 1)
        picked = rng.choice(eligible, size=end_i - start_i, replace=True, p=norm(day_weight[origin : AS_OF_ORD + 1]))
        date_ord[sort_idx[start_i:end_i]] = picked

    hour = rng.choice(24, size=n_primary, p=norm(HOUR_WEIGHTS)).astype(np.int16)
    minute = rng.integers(0, 60, size=n_primary).astype(np.int16)
    pay_min = date_ord.astype(np.int64) * 1440 + hour.astype(np.int64) * 60 + minute.astype(np.int64)
    too_early = pay_min < login_mins
    pay_min[too_early] = login_mins[too_early]
    pay_min = np.minimum(pay_min, MAX_MINUTE)

    channel_keys = np.array([row[0] for row in CHANNELS])
    channel = rng.choice(channel_keys, size=n_primary, p=norm([row[3] for row in CHANNELS])).astype(np.int16)

    bank = np.empty(n_primary, dtype=np.int16)
    masks = {
        1: BENEFICIARY,
        2: [(key, 1) for key in QR_MERCHANTS],
        3: BENEFICIARY,
        4: [(1, 1)],
        5: [(key, 1) for key in BILLERS],
        6: [(key, 1) for key in TELCOS],
        7: [(key, 1) for key in CARD_MERCHANTS],
    }
    for channel_key, pairs in masks.items():
        mask = channel == channel_key
        size = int(mask.sum())
        if size == 0:
            continue
        keys = [pair[0] for pair in pairs]
        bank[mask] = rng.choice(keys, size=size, p=norm([pair[1] for pair in pairs]))

    payment_keys = np.arange(1, n_primary + 1, dtype=np.int64)
    first_sort = np.lexsort((payment_keys, pay_min, acct_keys))
    sorted_accounts = acct_keys[first_sort]
    first_sorted = np.empty(n_primary, dtype=bool)
    first_sorted[0] = True
    first_sorted[1:] = sorted_accounts[1:] != sorted_accounts[:-1]
    is_first = np.zeros(n_primary, dtype=bool)
    is_first[first_sort[first_sorted]] = True

    base_fail = np.array([0, 0.035, 0.045, 0.150, 0.020, 0.125, 0.055, 0.050])
    multiplier = np.ones(n_primary, dtype=np.float64)
    peak = np.isin(hour, PEAK_HOURS)
    # Recompute hour from the bumped timestamp so peak flags follow the stored time.
    hour = ((pay_min % 1440) // 60).astype(np.int16)
    peak = np.isin(hour, PEAK_HOURS)
    date_ord = (pay_min // 1440).astype(np.int32)
    multiplier[peak] *= 1.35
    salary_flag = np.array([day["salary"] for day in days], dtype=bool)
    eid_flag = np.array([day["eid"] for day in days], dtype=bool)
    multiplier[salary_flag[date_ord]] *= 1.25
    multiplier[eid_flag[date_ord]] *= 1.45
    multiplier[legacy] *= 1.50
    multiplier[is_first] *= 1.90
    fail_p = np.clip(base_fail[channel] * multiplier, 0, 0.93)
    high_risk = np.isin(bank, list(HIGH_RISK_KEYS)) & np.isin(channel, [1, 3])
    fail_p[high_risk] = np.clip(fail_p[high_risk] + 0.10, 0, 0.93)
    failed = rng.random(n_primary) < fail_p

    reason = np.zeros(n_primary, dtype=np.int16)
    normal_mix = {
        1: [(INSUFFICIENT_FUNDS, 34), (LIMIT_EXCEEDED, 16), (OTP_EXPIRED, 14), (RAIL_TIMEOUT, 16), (BANK_TIMEOUT, 8), (FRAUD_BLOCK, 12)],
        2: [(INSUFFICIENT_FUNDS, 32), (RAIL_TIMEOUT, 18), (BILLER_DOWNTIME, 16), (OTP_EXPIRED, 14), (FRAUD_BLOCK, 20)],
        3: [(WRONG_ACCOUNT, 24), (RAIL_TIMEOUT, 20), (BANK_TIMEOUT, 8), (INSUFFICIENT_FUNDS, 18), (LIMIT_EXCEEDED, 12), (OTP_EXPIRED, 10), (FRAUD_BLOCK, 8)],
        4: [(INSUFFICIENT_FUNDS, 48), (LIMIT_EXCEEDED, 24), (OTP_EXPIRED, 16), (FRAUD_BLOCK, 12)],
        5: [(BILLER_DOWNTIME, 36), (INSUFFICIENT_FUNDS, 26), (OTP_EXPIRED, 14), (RAIL_TIMEOUT, 14), (LIMIT_EXCEEDED, 10)],
        6: [(INSUFFICIENT_FUNDS, 36), (BILLER_DOWNTIME, 22), (OTP_EXPIRED, 22), (RAIL_TIMEOUT, 14), (LIMIT_EXCEEDED, 6)],
        7: [(INSUFFICIENT_FUNDS, 32), (FRAUD_BLOCK, 24), (LIMIT_EXCEEDED, 16), (RAIL_TIMEOUT, 14), (OTP_EXPIRED, 14)],
    }
    high_risk_mix = {
        1: [(BANK_TIMEOUT, 85), (RAIL_TIMEOUT, 5), (INSUFFICIENT_FUNDS, 4), (OTP_EXPIRED, 3), (FRAUD_BLOCK, 3)],
        3: [(BANK_TIMEOUT, 85), (WRONG_ACCOUNT, 5), (RAIL_TIMEOUT, 4), (INSUFFICIENT_FUNDS, 3), (LIMIT_EXCEEDED, 3)],
    }
    for channel_key in channel_keys:
        for risk_flag, mix in ((False, normal_mix), (True, high_risk_mix if channel_key in high_risk_mix else normal_mix)):
            mask = failed & (channel == channel_key) & (high_risk if risk_flag else ~high_risk)
            # high_risk is already restricted to channels 1 and 3, so other channels use normal_mix only once.
            if channel_key not in (1, 3) and risk_flag:
                continue
            size = int(mask.sum())
            if size == 0:
                continue
            pairs = mix[int(channel_key)]
            reason[mask] = rng.choice([pair[0] for pair in pairs], size=size, p=norm([pair[1] for pair in pairs]))

    latency = rng.integers(90, 650, size=n_primary).astype(np.int32)
    latency[peak] = (latency[peak] * rng.uniform(1.15, 1.65, size=int(peak.sum()))).astype(np.int32)
    timeout_mask = np.isin(reason, [RAIL_TIMEOUT, BANK_TIMEOUT, BILLER_DOWNTIME])
    latency[timeout_mask] = rng.integers(3500, 15000, size=int(timeout_mask.sum()))
    other_fail = failed & ~timeout_mask
    latency[other_fail] = rng.integers(180, 2600, size=int(other_fail.sum()))

    mu = np.log(np.array([CHANNEL_AMOUNT_MEDIAN[int(ch)] for ch in channel], dtype=np.float64))
    amount = np.clip(np.exp(rng.normal(mu, 1.28)), 50, 1_000_000)
    amount = np.round(amount).astype(np.int64)

    print("Adding payment retries...")
    retry_rows = []
    retryable = failed & np.array([code in RETRYABLE_REASONS for code in reason])
    take = np.flatnonzero(retryable & (rng.random(n_primary) < 0.58))
    next_key = n_primary + 1

    def build_retries(source_idx: np.ndarray, source_min, source_reason, source_acct, source_channel, source_bank, source_amount, source_legacy, original_keys, fail_rate_timeout, fail_rate_other, take_rate_if_failed):
        nonlocal next_key
        if len(source_idx) == 0:
            return np.array([], dtype=int)
        n = len(source_idx)
        delay = rng.integers(15, 241, size=n)
        new_min = np.minimum(source_min + delay, MAX_MINUTE)
        timeoutish = np.isin(source_reason, [RAIL_TIMEOUT, BANK_TIMEOUT, BILLER_DOWNTIME])
        fail_rate = np.where(timeoutish, fail_rate_timeout, fail_rate_other)
        retry_failed = rng.random(n) < fail_rate
        new_hour = ((new_min % 1440) // 60).astype(np.int16)
        new_latency = rng.integers(120, 900, size=n)
        new_latency[retry_failed & timeoutish] = rng.integers(3500, 15000, size=int((retry_failed & timeoutish).sum()))
        new_latency[retry_failed & ~timeoutish] = rng.integers(180, 2400, size=int((retry_failed & ~timeoutish).sum()))
        created = []
        for i in range(n):
            retry_rows.append(
                (
                    next_key,
                    int(source_acct[i]),
                    int(source_channel[i]),
                    int(source_bank[i]),
                    int(new_min[i]),
                    int(source_amount[i]),
                    "Failed" if retry_failed[i] else "Success",
                    int(source_reason[i]) if retry_failed[i] else 0,
                    int(new_latency[i]),
                    1,
                    int(original_keys[i]),
                )
            )
            created.append(next_key)
            next_key += 1
        created = np.array(created)
        if take_rate_if_failed <= 0:
            return created
        failed_local = np.flatnonzero(retry_failed & np.array([int(r) in RETRYABLE_REASONS for r in source_reason]))
        keep = failed_local[rng.random(len(failed_local)) < take_rate_if_failed] if len(failed_local) else failed_local
        if len(keep) == 0:
            return created
        build_retries(
            keep,
            new_min[keep],
            source_reason[keep],
            source_acct[keep],
            source_channel[keep],
            source_bank[keep],
            source_amount[keep],
            source_legacy[keep],
            original_keys[keep],
            0.34,
            0.22,
            0,
        )
        return created

    build_retries(
        take,
        pay_min[take],
        reason[take],
        acct_keys[take],
        channel[take],
        bank[take],
        amount[take],
        legacy[take],
        payment_keys[take],
        0.40,
        0.28,
        0.30,
    )

    print(f"Payments including retries: {n_primary + len(retry_rows):,}")

    # Account-level payment outcomes from primaries plus retries.
    success_count = defaultdict(int)
    raast_success = set()
    first_status = {}
    first_datekey = {}
    activation = {}
    first_payment_for_event = {}

    def consider(acct, minute, status, reason_code, channel_key, payment_key, is_retry):
        if status == "Success":
            success_count[acct] += 1
            activation[acct] = min(activation.get(acct, 99999999), ymd(minute))
            if channel_key in (1, 2):
                raast_success.add(acct)
        current = first_payment_for_event.get(acct)
        if current is None or (minute, payment_key) < (current[0], current[1]):
            first_payment_for_event[acct] = (minute, payment_key, status, reason_code, is_retry)
            first_status[acct] = "Success" if status == "Success" else "Failed"
            first_datekey[acct] = ymd(minute)

    for i in range(n_primary):
        consider(
            int(acct_keys[i]),
            int(pay_min[i]),
            "Failed" if failed[i] else "Success",
            int(reason[i]),
            int(channel[i]),
            int(payment_keys[i]),
            0,
        )
    for row in retry_rows:
        consider(row[1], row[4], row[6], row[7], row[2], row[0], row[9])

    for acct, payload in first_payment_for_event.items():
        if payload[4] != 0:
            raise RuntimeError(f"earliest payment for account {acct} is a retry")

    # Step 8 events and application payment fields.
    for journey in journeys:
        account_key = journey.get("account_key")
        if account_key in first_payment_for_event:
            minute, _key, status, reason_code, _retry = first_payment_for_event[account_key]
            outcome = "Pass" if status == "Success" else "Fail"
            journey["events"].append(
                (journey["events"][0][0], 8, minute, outcome, reason_code if outcome == "Fail" else 0, 0, journey["referral"])
            )
            journey["first_status"] = first_status[account_key]
            journey["first_datekey"] = first_datekey[account_key]
            journey["activation"] = activation.get(account_key)
        else:
            journey["first_status"] = "Not attempted"
            journey["first_datekey"] = None
            journey["activation"] = None

    product_opts = ["Current account", "Savings", "Virtual debit card", "Term deposit", "Micro-loan"]
    for account in accounts:
        account["product"] = choice(rng, product_opts, [0.58, 0.27, 0.08, 0.04, 0.03])
        standard_p = 0.40 if account["occupation"] == "Salaried" or account["product"] == "Term deposit" else 0.14
        account["tier"] = "standard" if float(rng.random()) < standard_p else "basic"
        account["successes"] = success_count[account["key"]]
        if account["successes"] == 0:
            account["status"] = "dormant"
        else:
            account["status"] = "active"
        if dt_from_minute(account["open_min"]).date() < CLOSED_BEFORE and float(rng.random()) < 0.06:
            account["status"] = "closed"
        if account["key"] in raast_success or float(rng.random()) < 0.28:
            account["raast"] = "Y"
        else:
            account["raast"] = "N"

    if np.any(failed & (reason == 0)) or np.any((~failed) & (reason != 0)):
        raise RuntimeError("failure reason assignment does not match payment status")

    print("Writing CSV files...")
    manifest = []

    def emit(table: str, filename: str, rows) -> None:
        count = write_csv(out_dir / filename, headers(table), rows)
        manifest.append((filename, table, count))

    customer_rows = []
    for profile, journey in zip(profiles, journeys):
        start_dt = dt_from_minute(journey["start_min"])
        customer_rows.append(
            [
                profile["key"],
                f"CUS{profile['key']:08d}",
                hashlib.sha256(f"synthetic-{seed}-{profile['key']}".encode()).hexdigest()[:16],
                profile["age"],
                profile["gender"],
                profile["occupation"],
                profile["province"],
                profile["city"],
                profile["urban"],
                profile["network"],
                profile["os"],
                profile["brand"],
                profile["app"],
                start_dt.date().isoformat(),
                date_key(start_dt.date()),
            ]
        )
    emit("DimCustomer", "DimCustomer.csv", customer_rows)

    emit(
        "DimAccount",
        "DimAccount.csv",
        (
            [
                account["key"],
                f"ACC{account['key']:08d}",
                account["customer_key"],
                account["product"],
                account["tier"],
                account["status"],
                fmt_dt(account["open_min"]),
                fmt_date(account["open_min"]),
                ymd(account["open_min"]),
                account["raast"],
            ]
            for account in accounts
        ),
    )
    emit(
        "DimChannel",
        "DimChannel.csv",
        ([key, name, group] for key, name, group, _w, _p in CHANNELS),
    )
    emit(
        "DimOnboardingStep",
        "DimOnboardingStep.csv",
        ([key, name, order, stage] for key, name, order, stage in ONBOARDING_STEPS),
    )
    emit(
        "DimFailureReason",
        "DimFailureReason.csv",
        ([key, reason_name, category, retryable, applies] for key, reason_name, category, retryable, applies in FAILURE_REASONS),
    )
    emit(
        "DimBank",
        "DimBank.csv",
        ([key, name, kind] for key, name, kind, _w in BANKS),
    )

    def date_rows():
        for day in days:
            value = day["date"]
            yield [
                day["key"],
                value.isoformat(),
                value.year,
                (value.month - 1) // 3 + 1,
                value.month,
                value.strftime("%B"),
                value.year * 100 + value.month,
                value.day,
                value.isoweekday(),
                value.strftime("%A"),
                int(value.isoweekday() >= 6),
                day["salary"],
                day["ramadan"],
                day["eid"],
                day["eid_name"],
                int(value.day >= 28),
            ]

    emit("DimDate", "DimDate.csv", date_rows())
    emit(
        "DimTime",
        "DimTime.csv",
        (
            [
                hour_value,
                hour_value,
                f"{hour_value:02d}:00",
                "Night" if hour_value <= 5 else "Morning" if hour_value <= 11 else "Afternoon" if hour_value <= 17 else "Evening",
                int(hour_value in PEAK_HOURS),
            ]
            for hour_value in range(24)
        ),
    )

    event_rows = []
    for journey in journeys:
        event_rows.extend(journey["events"])
    event_rows.sort(key=lambda item: (item[2], item[0], item[1], item[5]))

    def event_csv():
        for event_key, event in enumerate(event_rows, start=1):
            customer_key, step, minute, outcome, reason_code, retry, referral = event
            yield [
                event_key,
                customer_key,
                step,
                fmt_dt(minute),
                ymd(minute),
                hour_of(minute),
                outcome,
                blank(reason_code or None),
                retry,
                referral,
            ]

    emit("FactOnboardingEvents", "FactOnboardingEvents.csv", event_csv())

    def application_rows():
        for profile, journey in zip(profiles, journeys):
            start_dt = dt_from_minute(journey["start_min"])
            end_dt = dt_from_minute(journey["end_min"])
            retries = sum(1 for event in journey["events"] if event[5] > 0)
            minutes = datediff_minutes(start_dt, end_dt) if journey["final_status"] == "Completed" else None
            yield [
                profile["key"],
                profile["key"],
                blank(journey.get("account_key")),
                fmt_dt(journey["start_min"]),
                date_key(start_dt.date()),
                hour_of(journey["start_min"]),
                fmt_dt(journey["end_min"]),
                date_key(end_dt.date()),
                hour_of(journey["end_min"]),
                journey["final_status"],
                blank(minutes),
                retries,
                blank(journey["failed_step"]),
                blank(journey["activation"]),
                blank(journey["first_datekey"]),
                journey["first_status"],
                journey["referral"],
            ]

    emit("FactApplication", "FactApplication.csv", application_rows())

    payment_header = headers("FactPayments")
    by_month: dict[str, list] = defaultdict(list)

    def append_payment(payment_key, acct, channel_key, bank_key, minute, amount_value, status, reason_code, latency_ms, is_retry, original):
        stamp = dt_from_minute(minute)
        by_month[stamp.strftime("%Y%m")].append(
            [
                payment_key,
                f"P{payment_key:010d}",
                acct,
                channel_key,
                bank_key,
                stamp.strftime("%Y-%m-%d %H:%M:%S"),
                date_key(stamp.date()),
                hour_of(minute),
                f"{amount_value:.2f}",
                status,
                blank(reason_code or None),
                latency_ms,
                is_retry,
                blank(original),
            ]
        )

    for i in range(n_primary):
        append_payment(
            int(payment_keys[i]),
            int(acct_keys[i]),
            int(channel[i]),
            int(bank[i]),
            int(pay_min[i]),
            int(amount[i]),
            "Failed" if failed[i] else "Success",
            int(reason[i]),
            int(latency[i]),
            0,
            None,
        )
    for row in retry_rows:
        append_payment(row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], row[10])

    for token in sorted(by_month):
        emit("FactPayments", f"FactPayments_{token}.csv", by_month[token])

    write_csv(
        out_dir / "LoadFiles.csv",
        ["FileName", "TableName", "ExpectedRows"],
        manifest,
    )
    table_counts = defaultdict(int)
    for _file, table, count in manifest:
        table_counts[table] += count
    write_csv(
        out_dir / "LoadManifest.csv",
        ["TableName", "ExpectedRows"],
        ([table, table_counts[table]] for table in TABLES),
    )

    print("Validating CSV files...")
    report = validate(out_dir)
    print(report.text())
    publish = out_dir.resolve() == (Path(__file__).resolve().parent / "csv").resolve()
    if publish:
        report_path = Path(__file__).resolve().parent / "GENERATION_REPORT.md"
        report_path.write_text(report.markdown(), encoding="utf-8")
        print(f"Report written to {report_path}")
    if report.failed:
        raise SystemExit(1)


def parse_args():
    parser = argparse.ArgumentParser(description="Generate digital bank CSVs.")
    parser.add_argument("--customers", type=int, default=50_000)
    parser.add_argument("--primary-payments", type=int, default=960_000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--out", type=Path, default=Path(__file__).resolve().parent / "csv")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    generate(args.customers, args.primary_payments, args.seed, args.out)
