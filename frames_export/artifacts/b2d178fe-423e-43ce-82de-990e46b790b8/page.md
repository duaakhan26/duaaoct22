# Digital Banking Analytics Use Cases: Primary Bank Share and Thin-File Credit Risk

<!-- tab: Digital Banking Analytics Use Cases: Primary Bank Share and Thin-File Credit Risk -->

# Digital Banking Analytics Use Cases: Primary Bank Share and Thin-File Credit Risk

## 1. Primary Bank Share

### What it is

A customer's primary bank is where their salary lands and most day-to-day spending happens. Primary-bank share (or share-of-wallet) is the portion of a customer's financial activity held with your bank versus other banks.

### Why it matters

Primary customers hold higher balances, use more products, cost less to serve, and rarely leave. Customers who only use a card or occasional transfers are the most likely to churn.

### Pain point

Many digital bank customers open an account but keep their salary elsewhere. The bank holds a small slice of their financial life and cannot cross-sell effectively.

### Example

A customer has accounts at three banks. Salary goes to Bank A, but they use your app for a card and occasional transfers. You hold roughly 15% of their financial activity. Analytics flags them as a salary-switch candidate, and the bank offers cashback for moving their salary over.

### Signals analytics looks at

- Salary-like recurring inflows, including inflows from other banks
- Month-over-month growth in transaction count and value
- Bill payments and standing orders starting to route through the bank
- Share of card spend versus total estimated spend
- App engagement frequency

### KPIs and outputs

- Primary-bank rate: % of active customers with salary credited
- Share-of-wallet estimate by segment
- Salary-switch conversion rate after a nudge
- Balance and product holding per primary vs. non-primary customer
- Churn rate: primary vs. non-primary

### Real-world reference

Monzo and Starling target salary switchers explicitly, with early-pay and salary-sorter features.

### Power BI / Tableau view

- Funnel: opened account → active → salary detected → primary
- Segment view: age band, channel, city
- Campaign view: nudge sent → salary switched, with cost vs. incremental balance

## 2. Thin-File Credit Risk

### What it is

A credit bureau records a person's borrowing track record: loans, credit cards, repayments, and defaults. In Pakistan this includes eCIB (run by SBP) and private bureaus. A thin file means the person has little or no history there.

### Pain point

Gen Z and first-time earners have never borrowed, so there is nothing to assess. Traditional models decline them by default, locking out creditworthy young customers and losing the bank a growth segment.

### Solution: alternative data

Judge behavior instead of past loans:

- Regularity and size of income
- Balance behavior: positive balance vs. dropping to zero each month
- On-time mobile, utility, and rent payments
- Spending consistency and volatility
- Account tenure and activity level

### How it works in practice

1. Score the customer on cash-flow and behavior data.
2. Offer a small starting limit (micro-loan, BNPL, or low-limit card).
3. Monitor repayment.
4. Raise the limit gradually. Once they repay, the file is no longer thin.

### KPIs and outputs

- Approval rate for thin-file applicants
- Default / delinquency rate by score band
- Limit-increase rate and time to graduate to a standard score
- Share of thin-file customers converted to active borrowers
- Score stability and bias monitoring across segments

### Real-world reference

Kuda and Tala-style lenders, and Jupiter and Fi in India, use cash-flow and wallet or telco data for first-time borrowers.

### Power BI / Tableau view

- Score distribution and approval funnel for thin-file applicants
- Vintage (cohort) delinquency curves by score band
- Limit-growth path per cohort

## 3. How the Two Connect

Primary-bank behavior is the best input for thin-file credit. A customer whose salary lands with the bank gives the richest cash-flow data, so a stronger primary relationship enables safer lending, and early lending deepens the relationship.

## 4. BRD to Report to LLM Flow (for both)

| Stage | Primary Bank Share | Thin-File Credit Risk |
| --- | --- | --- |
| **BRD** | Objective: raise salary-primary rate. KPIs: primary-bank rate, switch conversion. Dimensions: age, channel, city. | Objective: safely lend to thin-file Gen Z. KPIs: approval rate, delinquency by score band. Dimensions: score band, cohort, product. |
| **Self-service layer** | Certified measures such as "Primary Rate" and "Salary Inflow Flag" in the semantic model. | Certified measures such as "Thin-File Approval Rate" and "30+ DPD Rate". |
| **Regular data model** | Add a salary-detection rule or new inflow dimension if missing. | Add alt-data features (utility/telco payment history) and vintage logic if missing. |
| **LLM drag-and-drop** | LLM maps BRD KPIs to measures, flags gaps, and drafts the report spec and any new DAX. | Same, with a human review gate on any scoring-related measure. |

### Guardrails

- Definitions (what counts as a salary, what counts as a thin file) must be certified in the semantic layer, not inferred by the LLM.
- Row-level security and PII masking are enforced in the model.
- Credit-scoring measures and fairness metrics require human approval.
- Log which BRD produced which report for lineage and audit.

