# Generation report

Synthetic digital-bank star schema. Checks mirror `sql/02_load_and_validate.sql`.

| Status | Check | Detail |
| --- | --- | --- |
| PASS | File DimCustomer.csv | rows 50,000; manifest 50,000 |
| PASS | File DimAccount.csv | rows 36,366; manifest 36,366 |
| PASS | File DimChannel.csv | rows 7; manifest 7 |
| PASS | File DimOnboardingStep.csv | rows 8; manifest 8 |
| PASS | File DimFailureReason.csv | rows 14; manifest 14 |
| PASS | File DimBank.csv | rows 34; manifest 34 |
| PASS | File DimDate.csv | rows 368; manifest 368 |
| PASS | File DimTime.csv | rows 24; manifest 24 |
| PASS | File FactOnboardingEvents.csv | rows 339,338; manifest 339,338 |
| PASS | File FactApplication.csv | rows 50,000; manifest 50,000 |
| PASS | File FactPayments_202510.csv | rows 8,162; manifest 8,162 |
| PASS | File FactPayments_202511.csv | rows 20,764; manifest 20,764 |
| PASS | File FactPayments_202512.csv | rows 36,043; manifest 36,043 |
| PASS | File FactPayments_202601.csv | rows 49,127; manifest 49,127 |
| PASS | File FactPayments_202602.csv | rows 54,795; manifest 54,795 |
| PASS | File FactPayments_202603.csv | rows 91,937; manifest 91,937 |
| PASS | File FactPayments_202604.csv | rows 82,518; manifest 82,518 |
| PASS | File FactPayments_202605.csv | rows 142,592; manifest 142,592 |
| PASS | File FactPayments_202606.csv | rows 107,737; manifest 107,737 |
| PASS | File FactPayments_202607.csv | rows 128,267; manifest 128,267 |
| PASS | File FactPayments_202608.csv | rows 144,616; manifest 144,616 |
| PASS | File FactPayments_202609.csv | rows 150,765; manifest 150,765 |
| PASS | File FactPayments_202610.csv | rows 79; manifest 79 |
| PASS | Manifest DimCustomer | files sum to 50,000; manifest 50,000 |
| PASS | Manifest DimAccount | files sum to 36,366; manifest 36,366 |
| PASS | Manifest DimChannel | files sum to 7; manifest 7 |
| PASS | Manifest DimOnboardingStep | files sum to 8; manifest 8 |
| PASS | Manifest DimFailureReason | files sum to 14; manifest 14 |
| PASS | Manifest DimBank | files sum to 34; manifest 34 |
| PASS | Manifest DimDate | files sum to 368; manifest 368 |
| PASS | Manifest DimTime | files sum to 24; manifest 24 |
| PASS | Manifest FactOnboardingEvents | files sum to 339,338; manifest 339,338 |
| PASS | Manifest FactApplication | files sum to 50,000; manifest 50,000 |
| PASS | Manifest FactPayments | files sum to 1,017,402; manifest 1,017,402 |
| PASS | Header DimCustomer | column order matches the schema |
| PASS | Header DimAccount | column order matches the schema |
| PASS | Header DimChannel | column order matches the schema |
| PASS | Header DimOnboardingStep | column order matches the schema |
| PASS | Header DimFailureReason | column order matches the schema |
| PASS | Header DimBank | column order matches the schema |
| PASS | Header DimDate | column order matches the schema |
| PASS | Header DimTime | column order matches the schema |
| PASS | Header FactApplication | column order matches the schema |
| PASS | Header FactOnboardingEvents | column order matches the schema |
| PASS | Calendar flags | salary week, Ramadan, Eid, weekend, and month-end flags match the scenario calendar |
| PASS | Peak hours | flagged hours [12, 13, 14, 19, 20, 21] |
| PASS | CNIC tokens | 0 tokens are not 16-char synthetic hashes |
| PASS | City belongs to one province | 0 cities span provinces |
| PASS | Android-heavy device mix | Android share 77.9% |
| PASS | Onboarding date and time keys match the timestamp | 0 events |
| PASS | Onboarding failure reasons match the step | 0 events |
| PASS | Signup date matches journey start | 0 mismatches |
| PASS | Application matches onboarding events | 0 applications disagree with FactOnboardingEvents |
| PASS | Step key matches step order | DimOnboardingStep.StepKey is the funnel order |
| PASS | Every customer starts at download | step 1 attempted 50,000; applications 50,000 |
| PASS | Funnel is sequential through account opening | customers at each of steps 2-6 are exactly those who passed the previous step |
| PASS | Heaviest drop is NADRA liveness | step 1 drop 107; step 2 drop 809; step 3 drop 1,536; step 4 drop 9,497; step 5 drop 1,208; step 6 drop 477 |
| PASS | Older Android app builds fail NADRA more often | legacy Android pass 67.4% (11,186); current app pass 85.0% (22,832) |
| PASS | Header FactPayments_202510.csv | column order matches the schema |
| PASS | Header FactPayments_202511.csv | column order matches the schema |
| PASS | Header FactPayments_202512.csv | column order matches the schema |
| PASS | Header FactPayments_202601.csv | column order matches the schema |
| PASS | Header FactPayments_202602.csv | column order matches the schema |
| PASS | Header FactPayments_202603.csv | column order matches the schema |
| PASS | Header FactPayments_202604.csv | column order matches the schema |
| PASS | Header FactPayments_202605.csv | column order matches the schema |
| PASS | Header FactPayments_202606.csv | column order matches the schema |
| PASS | Header FactPayments_202607.csv | column order matches the schema |
| PASS | Header FactPayments_202608.csv | column order matches the schema |
| PASS | Header FactPayments_202609.csv | column order matches the schema |
| PASS | Header FactPayments_202610.csv | column order matches the schema |
| PASS | Payment date and time keys match the timestamp | 0 payments have a date or hour that does not match |
| PASS | Payments stay inside opened accounts | 0 payments missing an open account or dated before it |
| PASS | Failure reasons match payment status | 0 reason/status mismatches |
| PASS | Retries point at the original attempt | 0 broken retry links |
| PASS | Application payment summary matches FactPayments | 0 mismatches |
| PASS | First-payment step matches the first attempt | 0 step mismatches; step customers 27,532; paying customers 27,532 |
| PASS | Account status matches payment activity | 0 status mismatches |
| PASS | Closed accounts were opened before 1 Apr 2026 | 0 closed too recently |
| PASS | Raast ID is linked after a successful Raast payment | 0 accounts |
| PASS | Dormancy is material | dormant accounts 23.9% |
| PASS | IBFT fails more often than Raast P2P | IBFT 25.8%; Raast P2P 7.2% |
| PASS | Bill pay fails more often than Raast P2P | bill pay 21.9%; Raast P2P 7.2% |
| PASS | First payment fails more often than later payments | first 19.6%; later 12.2% |
| PASS | Failures are higher at peak hours | peak 14.0%; off-peak 11.3% |
| PASS | Some retries recover and some do not | retry success 66.9% of 57,402 |
| PASS | Bank timeouts concentrate in a few beneficiary banks | Allied/JS/BOP are 3.3% of payments and 60.8% of bank timeouts (10,405) |
| PASS | Small P2P and bill payments dominate the count | top channel Raast P2P; P2P+bill 52.1% |
| PASS | Amounts are skewed, with a long tail | median 1,180 PKR; mean 3,825 PKR |
| PASS | Salary week has more payments per day | salary-week 4,872/day; other days 1,910/day |
| PASS | Eid has more payments per day | Eid 12,814/day; other days 1,910/day |
| PASS | Scale is about 50,000 applications and 1M payments | 50,000 applications; 1,017,402 payments |
| INFO | Conversion % | 72.7% completed (36,366 of 50,000) |
| INFO | Median minutes to open | 16 |
| INFO | Activation rate within 30 days | 66.8% of completed applications |
| INFO | First-payment success rate | 80.4% |
| INFO | Failed payment value | 654,480,540 PKR |
| INFO | Average latency | 950 ms |
| INFO | Dormancy rate | 23.9% of opened accounts |
| INFO | Failure rate Raast P2P | 7.2% of 336,153 |
| INFO | Failure rate Raast QR | 8.2% of 119,557 |
| INFO | Failure rate 1LINK IBFT | 25.8% of 120,081 |
| INFO | Failure rate Intra-bank transfer | 3.4% of 77,608 |
| INFO | Failure rate Bill pay | 21.9% of 193,652 |
| INFO | Failure rate Mobile top-up | 10.2% of 120,622 |
| INFO | Failure rate Card | 8.9% of 49,729 |

## Onboarding funnel

| Step | Name | Attempted | Passed | Drop from previous pass |
| --- | --- | ---: | ---: | ---: |
| 1 | Download app | 50,000 | 49,893 | 107 |
| 2 | Mobile OTP | 49,893 | 49,084 | 809 |
| 3 | CNIC capture | 49,084 | 47,548 | 1,536 |
| 4 | NADRA biometric and selfie liveness | 47,548 | 38,051 | 9,497 |
| 5 | Address and profile | 38,051 | 36,843 | 1,208 |
| 6 | Account opened | 36,843 | 36,366 | 477 |
