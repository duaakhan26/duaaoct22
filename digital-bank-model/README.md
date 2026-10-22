# Digital bank onboarding and payments model

Synthetic star schema for a Pakistani digital bank: mobile onboarding through NADRA, then Raast, IBFT, bill pay, and card payments. The shape is the flattened model from the Claude working session.

- **Dimensions:** DimCustomer (geography and device on the customer), DimAccount (product on the account), DimChannel, DimOnboardingStep, DimFailureReason, DimBank, DimDate, DimTime
- **Facts:** FactOnboardingEvents (one row per step attempt), FactApplication (one row per customer), FactPayments (one row per payment attempt, including retries)
- **Scale:** 50,000 applications from 1 Oct 2025 through 30 Sep 2026, about 1 million payment attempts
- **Keys:** integer surrogate keys. Date keys are `yyyymmdd`. Customer identifiers are 16-character hashes, not CNICs.

`GENERATION_REPORT.md` is the measured funnel, failure rates, and the check results. `DATA_DICTIONARY.md` lists every column.

## Regenerate

```bash
cd digital-bank-model
python3 generate_data.py
```

Needs Python 3.10+ and numpy. The default seed is 42. A smaller set for a laptop load is:

```bash
python3 generate_data.py --customers 8000 --primary-payments 140000 --out /tmp/dbpilot
```

That smaller run does not overwrite `csv/` or the SQL load script.

## Load in SSMS

SQL Server 2017 or newer. The files have to be on the machine where the SQL Server service runs, and the service account has to be able to read them.

1. Copy the contents of `csv/` to a folder such as `C:\DigitalBankData\`. Do not put them in a nested `csv` folder. `DimCustomer.csv` should sit directly in that folder.
2. Open `sql/00_create_database.sql` and execute it.
3. Open `sql/02_load_data.sql` and set `@DataPath` to that folder. Execute `sql/01_create_tables.sql`, then `sql/02_load_data.sql`.
4. Execute `sql/03_add_keys.sql`. This adds the primary keys, foreign keys, and check constraints. A failure here is a broken key or an illegal value.
5. Execute `sql/04_validate.sql`. The grid is one row per check. `PASS` and `INFO` are expected. Any `FAIL` raises an error after the grid.
6. Execute `sql/05_helper_views.sql`. Then browse `dbo.vw_OnboardingFunnel`, `dbo.vw_Application`, and `dbo.vw_Payments`.

`02_load_data.sql` refuses to load into a database that already has customers. To reload, run `01_create_tables.sql` again and then `02`.

The CSVs use LF line endings. The load strips a trailing CR, so a copy that was turned into CRLF still loads. `BULK INSERT` reads the path from the server, not from your laptop, when SQL Server is remote.

## What the data is built to show

- The largest onboarding loss is NADRA biometric / selfie liveness, and customers retry there.
- Older Android app builds (`3.2.0`, `3.8.1`) fail that step more often than `4.4.2` and `4.6.0`.
- About three quarters of devices are Android.
- IBFT and bill pay fail more often than Raast P2P.
- Failures rise at peak hours (12:00–14:00 and 19:00–21:00), on salary week (the 25th through the 1st), and on Eid.
- Beneficiary bank timeouts concentrate on Allied Bank, JS Bank, and Bank of Punjab, which are a small share of volume.
- Some failed payments are retried and succeed. The first payment fails more often than later ones.
- A material share of opened accounts never have a successful payment (dormant).
- Most payments are small Raast P2P or bill payments. The amount distribution has a long tail.
- Salary week and Eid have more payments per day. Ramadan is 18 Feb 2026 through 19 Mar 2026. Eid ul Fitr is 20–22 Mar 2026. Eid ul Adha is 27–29 May 2026.

## SSAS

`ssas/measures.dax` has the onboarding, payment, and first-payment measures from the working session. Keep relationships single-direction. One active date relationship per fact: event date, application start date, and payment date. Leave the other date keys inactive so a date filter does not also filter on account-open date.

FactPayments is already split by month in `csv/FactPayments_YYYYMM.csv`, which matches a monthly partition.
