# Digital bank onboarding and payments model

Synthetic star schema for a Pakistani digital bank. Customers onboard in a mobile app, through NADRA, and then pay by Raast, 1LINK IBFT, bill pay, top-up, or card. The institution the customers belong to is **Own Digital Bank**. The other names in `DimBank` are beneficiary banks, billers, and merchants. Nothing here is a production extract.

`DATA_DICTIONARY.md` lists every column. `GENERATION_REPORT.md` is the measured funnel and the check results from this CSV set.

## Shape

Eight dimensions and three facts. Geography and device sit on the customer. Product and tier sit on the account. Facts store integer surrogate keys. Date keys are `yyyymmdd`. `CustomerID`, `AccountID`, and `PaymentID` are business codes, not the join keys. `CNICToken` is a 16-character hash, not a CNIC.

| Table | Grain | Rows in this set |
| --- | --- | ---: |
| DimCustomer | One applicant | 50,000 |
| DimAccount | One opened account. Abandoned and rejected customers have none | 36,366 |
| DimChannel | One payment rail | 7 |
| DimOnboardingStep | One funnel step | 8 |
| DimFailureReason | One reason a step or a payment failed | 14 |
| DimBank | Own bank, a beneficiary bank, a biller, or a merchant group | 34 |
| DimDate | One day, 1 Oct 2025 through 30 Sep 2026 | 365 |
| DimTime | One hour, 0–23 | 24 |
| FactOnboardingEvents | One attempt of one step by one customer, including retries | 339,338 |
| FactApplication | One customer. Summary of the journey, plus the first payment | 50,000 |
| FactPayments | One payment attempt, including retries. One file, `csv/FactPayments.csv` | 100,871 |

## How the tables join

Each fact has one active date role. Leave the other date keys inactive in a Tabular model so a date filter does not also filter on signup, account open, journey end, or activation.

- `FactOnboardingEvents` joins `DimCustomer`, `DimOnboardingStep`, `DimFailureReason` (null on a pass), `DimDate` on `DateKey`, and `DimTime` on `TimeKey`.
- `FactApplication` joins `DimCustomer` (`ApplicationKey` equals `CustomerKey`), `DimAccount` (null unless the journey completed), `DimOnboardingStep` on `FailedStepKey` (null when completed), and `DimDate` on `StartDateKey`. `EndDateKey`, `ActivationDateKey`, and `FirstPaymentDateKey` are the other date roles.
- `FactPayments` joins `DimAccount`, `DimChannel`, `DimBank`, `DimFailureReason` (null on success), `DimDate` on `DateKey`, and `DimTime` on `TimeKey`. `OriginalPaymentKey` points at the first attempt of the same payment, and only on a retry row.
- `DimAccount.CustomerKey` points at `DimCustomer`. `DimCustomer.SignupDateKey` and `DimAccount.OpenDateKey` point at `DimDate`.

## What a journey looks like

Every customer starts at **Download app**. Steps 2 through 6 are reached only by customers who passed the previous step:

1. Download app
2. Mobile OTP
3. CNIC capture
4. NADRA biometric and selfie liveness
5. Address and profile
6. Account opened

A pass has no failure reason. A fail has one. Customers can retry liveness, an unclear document, or an expired OTP. NADRA mismatch, a sanctions/AML hit, or a duplicate account ends the journey as **Rejected**. Any other unrecovered onboarding failure ends as **Abandoned**. **Completed** means step 6 passed, and that customer has exactly one account.

Steps 7 and 8 are not required to finish onboarding. **First login** exists only if the customer logged in. **First payment** exists only if they attempted a payment, and that row matches the earliest `FactPayments` row for the account: Success maps to Pass, Failed maps to Fail.

`FactApplication` is that journey on one row: start, end, `FinalStatus`, minutes to open, retries, the step they stopped on, and the first-payment outcome. `MinutesToOpen` is `DATEDIFF(MINUTE, StartDateTime, EndDateTime)` for a completed application. `ActivationDateKey` is the date of the first successful payment, which can be a later retry after a failed first attempt. `FirstPaymentDateKey` is the date of the first attempt, successful or not.

## Payments

A payment belongs to an opened account and is never timestamped before `OpenDateTime`. `IsRetry = 0` is the original attempt. `IsRetry = 1` points `OriginalPaymentKey` at that original row, on the same account. Channels:

| Key | Channel | Counterparty in DimBank |
| --- | --- | --- |
| 1 | Raast P2P | A beneficiary bank |
| 2 | Raast QR | A merchant group |
| 3 | 1LINK IBFT | A beneficiary bank |
| 4 | Intra-bank transfer | Own Digital Bank |
| 5 | Bill pay | A utility or 1Bill |
| 6 | Mobile top-up | Jazz, Telenor, Zong, or Ufone |
| 7 | Card | E-commerce or card acceptance |

`RaastIDLinked` is Y when the account has any successful Raast P2P or Raast QR payment. Some accounts are also linked without one. Account status is **active** after at least one successful payment, **dormant** when the account opened and never had one, and **closed** only for accounts opened before 1 Apr 2026.

Amounts are whole rupees from 50 to 1,000,000. Most are small. The mean sits well above the median.

## What the year is built to show

The window is 1 Oct 2025 through 30 Sep 2026.

- The largest onboarding loss is NADRA biometric / selfie liveness, and customers retry there.
- Android builds `3.2.0` and `3.8.1` fail that step more often than `4.4.2` and `4.6.0`. About three quarters of devices are Android.
- IBFT and bill pay fail more often than Raast P2P.
- Failures rise at peak hours (12:00–14:00 and 19:00–21:00), on salary week (the 1st, and the 25th through month-end), and on Eid.
- Beneficiary bank timeouts concentrate on Allied Bank, JS Bank, and Bank of Punjab, which are a small share of volume.
- Some failed payments are retried and succeed. The first payment fails more often than later ones.
- A material share of opened accounts never have a successful payment.
- Most payments are small Raast P2P or bill payments.
- Ramadan is 18 Feb 2026 through 19 Mar 2026. Eid ul Fitr is 20–22 Mar 2026. Eid ul Adha is 27–29 May 2026.

On this set the funnel is: 50,000 downloads, 49,893 passed download, 49,084 passed OTP, 47,548 passed CNIC, 38,051 passed NADRA, 36,843 passed profile, 36,366 accounts opened. NADRA drops 9,497 customers, more than any earlier step. Conversion is 72.7%. Median time to open is 16 minutes. Of the opened accounts, 27,532 attempt a payment.

## Checks

Script 2 prints these after the row counts. `PASS` means the rule held. `INFO` is a measurement with no pass line. Any `FAIL` raises error 50010 after the grid. The numbers below are this CSV set.

### Rules that must hold

| Check | What it tests | Pass when | This set |
| --- | --- | --- | --- |
| Android-heavy device mix | Share of customers on Android | 75% to 82% | 77.9% |
| CNIC tokens | Every token is 16 hex characters | Zero bad tokens | 0 |
| City belongs to one province | A city name is not used in two provinces | Zero cities span provinces | 0 |
| Calendar flags | Salary week is the 1st or the 25th onward. Weekend is Saturday and Sunday. Month-end is day 28 onward. Ramadan is 18 Feb 2026–19 Mar 2026. Eid ul Fitr is 20–22 Mar 2026. Eid ul Adha is 27–29 May 2026 | Zero dates break a flag | 0 |
| Peak hours | `DimTime` has 24 hours, and peak is 12, 13, 14, 19, 20, 21 | Zero mismatches | 0 |
| Every customer starts at download | Every customer has a step-1 event, and applications equal customers | Zero missing, 50,000 = 50,000 | Pass |
| Funnel is sequential through account opening | Customers who attempt step 2–6 are exactly those who passed the previous step | Zero broken steps | 0 |
| Heaviest drop is NADRA liveness | The biggest loss from one step's passes to the next is step 4 | The largest drop is step 4 | Step 4 drops 9,497 |
| Older Android app builds fail NADRA more often | Pass rate on Android `3.2.0` and `3.8.1` versus `4.4.2` and `4.6.0` | Current apps pass at least 8 points more often | 67.4% legacy, 85.0% current |
| Onboarding failure reasons match the step | A pass has no reason. A fail on steps 1–7 uses an onboarding reason, or OTP expired. Step 8 uses a payment reason, or OTP expired | Zero events | 0 |
| Application matches onboarding events | Start, end, retries, referral, status, minutes to open, failed step, and account agree with the events. Rejected is only NADRA mismatch, sanctions/AML, or duplicate | Zero applications disagree | 0 |
| Signup date matches journey start | `SignupDate` is the date of the first event | Zero mismatches | 0 |
| Onboarding date and time keys match the timestamp | `DateKey` is `yyyymmdd` of the event, `TimeKey` is the hour | Zero events | 0 |
| Application payment summary matches FactPayments | First-payment status and date are the earliest payment. Activation date is the first success. Customers who never opened an account did not pay | Zero mismatches | 0 |
| First-payment step matches the first attempt | The step-8 event is the earliest payment: same time, Success/Failed mapped to Pass/Fail, same reason | Zero mismatches | 27,532 on both sides |
| Payments stay inside opened accounts | Every payment has an account and is at or after `OpenDateTime` | Zero payments | 0 |
| Payment date and time keys match the timestamp | Same rule as the onboarding date check | Zero payments | 0 |
| Failure reasons match payment status | Success has no reason. A failure uses a payment reason, or OTP expired | Zero payments | 0 |
| Retries point at the original attempt | `IsRetry = 1` points at an `IsRetry = 0` row on the same account. An original row has no `OriginalPaymentKey` | Zero broken links | 0 |
| Account status matches payment activity | Active accounts have a success. Dormant accounts have none. The application completed, and its end time is the open time | Zero mismatches | 0 |
| Closed accounts were opened before 1 Apr 2026 | A closed account opened on or after that date is wrong | Zero closed too recently | 0 |
| Raast ID is linked after a successful Raast payment | A successful Raast P2P or Raast QR payment has `RaastIDLinked = Y` | Zero accounts missing the link | 0 |
| Dormancy is material | Share of opened accounts with status dormant | 12% to 40% | 27.5% |
| IBFT fails more often than Raast P2P | Failed share on channel 3 versus channel 1 | IBFT is at least 3 points higher | 31.1% vs 8.5% |
| Bill pay fails more often than Raast P2P | Failed share on channel 5 versus channel 1 | Bill pay is at least 3 points higher | 26.1% vs 8.5% |
| First payment fails more often than later payments | Fail rate of each account's earliest payment versus every later row | First is at least 3 points higher | 20.3% vs 13.1% |
| Failures are higher at peak hours | Fail rate in peak hours versus the other hours | Peak is at least 1.12 times off-peak | 17.1% vs 13.6% |
| Some retries recover and some do not | Success rate among `IsRetry = 1` rows | 55% to 85% | 67.6% of 6,871 retries |
| Bank timeouts concentrate in a few beneficiary banks | Allied Bank, JS Bank, and Bank of Punjab versus reason 12 | They are under 15% of payments and at least half of bank timeouts | 3.2% of payments, 57.5% of 1,197 timeouts |
| Small P2P and bill payments dominate the count | The channel with the most rows, and the share of Raast P2P plus bill pay | The top channel is Raast P2P, and those two are at least 45% | 51.8% |
| Amounts are skewed, with a long tail | Median versus mean amount | The mean is more than twice the median | Median 1,193 PKR, mean 3,776 PKR |
| Salary week has more payments per day | Average payments per salary-week day versus other non-Eid days, inside the year | Salary week is at least 1.5 times a normal day | 492 vs 188 per day |
| Eid has more payments per day | Average payments per Eid day versus non-salary, non-Eid days | Eid is at least twice a normal day | 1,211 vs 188 per day |
| Scale is about 50,000 applications and 100,000 payments | Runs only when customers are at least 40,000 | Exactly 50,000 customers and 90,000 to 110,000 payments | 50,000 and 100,871 |

### Measurements

These rows are `INFO`. They do not pass or fail.

| Check | This set |
| --- | --- |
| Conversion % | 72.7% completed (36,366 of 50,000) |
| Median minutes to open | 16 |
| Activation rate within 30 days | 31.8% of completed applications. A success on or before the 30th day after `OpenDate` |
| First-payment success rate | 79.7% of customers who attempted a payment |
| Failed payment value | 77,288,617 PKR |
| Average latency | 1,046 ms |
| Dormancy rate | 27.5% of opened accounts |
| Failure rate by channel | Raast P2P 8.5% of 33,009. Raast QR 10.1% of 11,770. 1LINK IBFT 31.1% of 12,048. Intra-bank 4.5% of 7,801. Bill pay 26.1% of 19,279. Mobile top-up 12.8% of 11,976. Card 10.4% of 4,988 |

The Python validator also checks that each CSV has the row count in `LoadFiles.csv`, that those counts add up to `LoadManifest.csv`, and that each header matches the table. Those two files are not loaded into SQL Server. `StepKey` equals `StepOrder` on `DimOnboardingStep`.

## Load in SSMS

SQL Server 2017 or newer. Copy the data CSVs onto the SQL Server machine, for example `C:\DigitalBankData\`, so `DimCustomer.csv` sits directly in that folder. The service account has to be able to read it. `BULK INSERT` reads the path from the server, not from the laptop, when SQL Server is remote.

1. `sql/01_create_schema.sql` creates `DigitalBankDW`, the tables, and the keys.
2. Set `@DataPath` in `sql/02_load_and_validate.sql`, then execute the whole script. It loads parent dimensions before the tables that reference them, prints the row counts, then prints the grid above.

`PASS` and `INFO` are expected. To reload, run script 1 again, then script 2. The CSVs use LF line endings. The load strips a trailing CR, so a copy that was turned into CRLF still loads.

`LoadFiles.csv` and `LoadManifest.csv` are checklists for the Python validator. Script 2 does not read them. The expected counts are written into the script.

## Regenerate

```bash
cd digital-bank-model
python3 generate_data.py
```

Needs Python 3.10+ and numpy. The default seed is 42, with 50,000 customers and about 100,000 payments. A smaller set for a laptop load is:

```bash
python3 generate_data.py --customers 8000 --primary-payments 20000 --out /tmp/dbpilot
```

That smaller run writes only to the path you pass. The committed CSVs and the two SQL scripts stay as they are. Those scripts match this CSV set. Regenerating at a different size does not rewrite them.

## SSAS

`ssas/measures.dax` has the onboarding, payment, and first-payment measures. Keep relationships single-direction. One active date relationship per fact: event date, application start date, and payment date.
