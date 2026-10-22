# Data dictionary

Grain and column names follow the flattened onboarding-and-payments model. Facts store surrogate keys. Business codes (`CustomerID`, `AccountID`, `PaymentID`) stay on the dimension or on the payment row and are not the join keys.

Blank CSV fields load as NULL. `EidName` is NULL when the day is not Eid.

## DimCustomer

One row per applicant. Geography and device sit on the customer so the model does not snowflake.

| Column | Description |
| --- | --- |
| CustomerKey | Surrogate key, 1…N |
| CustomerID | Business code, `CUS` + 8 digits |
| CNICToken | SHA-256 prefix. Not a CNIC and not reversible to one |
| AgeBand | 18-24, 25-34, 35-44, 45-54, 55+ |
| Gender | Male, Female |
| Occupation | Salaried, Self-employed, Student, Housewife, Freelancer |
| Province | Province or territory, including Islamabad |
| City | City consistent with Province |
| UrbanRural | Urban or Rural |
| MobileNetwork | Jazz, Telenor, Zong, Ufone |
| DeviceOS | Android or iOS |
| DeviceBrand | Android brands, or Apple |
| AppVersion | 3.2.0 and 3.8.1 are the older builds |
| SignupDate | Date of the first onboarding event |
| SignupDateKey | `yyyymmdd` |

## DimAccount

One row per completed application. Customers who abandon or are rejected have no account. Product and tier sit here.

| Column | Description |
| --- | --- |
| AccountKey | Surrogate key |
| AccountID | `ACC` + 8 digits |
| CustomerKey | The customer who opened it |
| Product | Current account, Savings, Virtual debit card, Term deposit, Micro-loan |
| Tier | basic or standard |
| Status | active (at least one successful payment), dormant (none), closed (opened before 1 Apr 2026 and since closed) |
| OpenDateTime | Timestamp of the passed "Account opened" step |
| OpenDate | Date of OpenDateTime |
| OpenDateKey | `yyyymmdd` |
| RaastIDLinked | Y or N. Y whenever the account has a successful Raast P2P or Raast QR payment |

## DimChannel

| ChannelKey | ChannelName | ChannelGroup |
| --- | --- | --- |
| 1 | Raast P2P | Raast |
| 2 | Raast QR | Raast |
| 3 | 1LINK IBFT | IBFT |
| 4 | Intra-bank transfer | Internal |
| 5 | Bill pay | Bills |
| 6 | Mobile top-up | Top-up |
| 7 | Card | Card |

## DimOnboardingStep

`StepKey` equals `StepOrder`.

| StepOrder | StepName | FunnelStage |
| --- | --- | --- |
| 1 | Download app | Acquisition |
| 2 | Mobile OTP | Verification |
| 3 | CNIC capture | Verification |
| 4 | NADRA biometric and selfie liveness | Verification |
| 5 | Address and profile | Opening |
| 6 | Account opened | Opening |
| 7 | First login | Activation |
| 8 | First payment | Activation |

Steps 7 and 8 exist only when the customer actually logged in or attempted a payment. Missing rows are the drop, not a failed attempt.

## DimFailureReason

| Key | Reason | Category | Retryable | Applies to |
| --- | --- | --- | --- | --- |
| 1 | NADRA mismatch | fraud/compliance | No | Onboarding |
| 2 | Liveness failed | customer | Yes | Onboarding |
| 3 | Document unclear | customer | Yes | Onboarding |
| 4 | Abandoned | customer | No | Onboarding |
| 5 | Sanctions/AML screening hit | fraud/compliance | No | Onboarding |
| 6 | Duplicate account | fraud/compliance | No | Onboarding |
| 7 | Insufficient funds | customer | Yes | Payment |
| 8 | Wrong account or IBAN | customer | Yes | Payment |
| 9 | Limit exceeded | customer | No | Payment |
| 10 | OTP expired | customer | Yes | Both |
| 11 | Rail timeout | network/rail | Yes | Payment |
| 12 | Beneficiary bank timeout | network/rail | Yes | Payment |
| 13 | Fraud-rule block | fraud/compliance | No | Payment |
| 14 | Biller downtime | bank-side | Yes | Payment |

NADRA mismatch, sanctions/AML, and duplicate account end the journey as `Rejected`. Other onboarding failures that are not recovered end as `Abandoned`.

## DimBank

`BankType` is Internal, Bank, Biller, or Merchant.

- Intra-bank transfer uses Own Digital Bank.
- Raast P2P and 1LINK IBFT use the beneficiary banks (HBL, UBL, MCB, Meezan, Allied, and the rest of the list).
- Bill pay uses billers (K-Electric, LESCO, IESCO, SNGPL, SSGC, PTCL, Nayatel, 1Bill).
- Mobile top-up uses Jazz, Telenor, Zong, Ufone.
- Raast QR and card use merchant groups.

Allied Bank, JS Bank, and Bank of Punjab are the timeout-prone beneficiary banks. They are a small share of payment volume.

## DimDate

One row per day from 1 Oct 2025 through 3 Oct 2026. The extra days cover payment retries that fall just after 30 Sep 2026. Measures and the salary/Eid checks use 1 Oct 2025–30 Sep 2026.

| Column | Rule |
| --- | --- |
| DateKey | `yyyymmdd` |
| FullDate | Calendar date |
| CalendarYear, Quarter, MonthNumber, MonthName, YearMonth | Calendar attributes for the Year → Quarter → Month → Day hierarchy |
| DayOfMonth, DayOfWeek, DayName | DayOfWeek is ISO: Monday = 1 … Sunday = 7 |
| IsWeekend | Saturday or Sunday |
| IsSalaryWeek | Day is the 1st, or the 25th through the end of the month |
| IsRamadan | 18 Feb 2026–19 Mar 2026 |
| IsEid, EidName | 20–22 Mar 2026 Eid ul Fitr; 27–29 May 2026 Eid ul Adha |
| IsMonthEnd | Day number is 28 or later |

## DimTime

One row per hour. `TimeKey` is the hour 0–23.

`IsPeakHour` is 1 for 12, 13, 14, 19, 20, and 21. `TimeBand` is Night (0–5), Morning (6–11), Afternoon (12–17), Evening (18–23).

## FactOnboardingEvents

One row per customer per step attempt, including retries. `RetryNumber` 0 is the first attempt.

| Column | Description |
| --- | --- |
| EventKey | Surrogate key |
| CustomerKey | Applicant |
| StepKey | DimOnboardingStep |
| EventDateTime | When this attempt happened |
| DateKey, TimeKey | Hour of EventDateTime |
| Outcome | Pass or Fail |
| FailureReasonKey | NULL on Pass |
| RetryNumber | 0, 1, or 2 |
| ReferralSource | Organic, Facebook, Google, Friend referral, Campus, or Branch QR. Same value on every event for a customer |

A customer reaches step N (2 through 6) only after passing step N−1. Pass rows have no failure reason.

## FactApplication

One row per customer. This is the summary of FactOnboardingEvents, plus the first-payment outcome from FactPayments.

| Column | Description |
| --- | --- |
| ApplicationKey | Same value as CustomerKey |
| CustomerKey | Applicant |
| AccountKey | NULL unless FinalStatus is Completed |
| StartDateTime | First event |
| StartDateKey, StartTimeKey | Hour of the start |
| EndDateTime | Account-opened time when completed; otherwise the last event |
| EndDateKey, EndTimeKey | Hour of the end |
| FinalStatus | Completed, Abandoned, or Rejected |
| MinutesToOpen | SQL `DATEDIFF(MINUTE, StartDateTime, EndDateTime)` for completed applications; otherwise NULL |
| TotalRetries | Count of event rows with RetryNumber > 0 |
| FailedStepKey | NULL when completed; otherwise the step they stopped on |
| ActivationDateKey | Date of the first successful payment. NULL if they never succeed |
| FirstPaymentDateKey | Date of the first payment attempt |
| FirstPaymentStatus | Success, Failed, or Not attempted |
| ReferralSource | Acquisition source for the journey |

`Conversion %` is completed applications divided by all applications. Activation within 30 days is a successful payment on or before the 30th day after `OpenDate`. First-payment success uses the first attempt, not a later retry. A later retry can still set `ActivationDateKey` when the first attempt failed.

## FactPayments

One row per payment attempt. Retries are extra rows. All attempts for the year are in `FactPayments.csv`.

| Column | Description |
| --- | --- |
| PaymentKey | Surrogate key |
| PaymentID | `P` + 10 digits |
| AccountKey | Account that paid |
| ChannelKey | DimChannel |
| BankKey | Beneficiary bank, biller, or merchant |
| PaymentDateTime | Attempt timestamp, never before the account was opened |
| DateKey, TimeKey | Hour of PaymentDateTime |
| AmountPKR | 50 to 1,000,000. Most values are small; the mean is well above the median |
| Status | Success or Failed |
| FailureReasonKey | NULL on Success |
| LatencyMs | Higher on timeouts and at peak hours |
| IsRetry | 0 for the original attempt, 1 for a retry |
| OriginalPaymentKey | NULL when IsRetry is 0; otherwise the original attempt's PaymentKey, not the intermediate retry |

The earliest row for an account is the first attempt (`IsRetry = 0`). That row is what FactApplication and the "First payment" onboarding step describe.
