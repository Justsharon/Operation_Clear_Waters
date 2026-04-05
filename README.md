# Operation Clearwater — Project Documentation
**NorthAxis Bank plc | Risk Intelligence Division**
**Reference:** NAB-RI-2024-09 | **Period:** January – September 2024 | **Status:** Complete

---

## 1. Executive Summary

NorthAxis Bank experienced a 340% spike in fraud-related complaints during Q3 2024, prompting an urgent investigation by the Risk Intelligence Division ahead of an emergency Board Risk Committee meeting. This report documents the end-to-end analytical investigation conducted under Operation Clearwater — from raw data ingestion through to a board-ready risk dashboard.

The investigation identified **26 high-risk accounts** responsible for **728 suspicious transactions** totalling an estimated **$24.35 million** in at-risk exposure across the January to September 2024 period. Four fraud signals were confirmed through data analysis: velocity anomalies, off-hours activity, geographic mismatch, and statistical amount outliers. Mobile Banking and Web Banking were identified as the primary channels of suspicious activity, with the highest concentration occurring between 2AM and 3AM.

---

## 2. Background & Business Problem

NorthAxis Bank is a mid-sized commercial bank operating across 12 countries, serving over 80,000 customers through branch, ATM, mobile banking, and web channels. The bank processes approximately 400,000 transactions per month spanning card payments, wire transfers, POS transactions, and online purchases.

In Q3 2024, the bank's compliance hotline received a disproportionate volume of fraud-related complaints. Internal audit flagged an estimated $2.3M in suspicious outflows concentrated within a 6-week window. The CFO escalated the matter to the Board Risk Committee, requiring a data-backed investigation to be completed within 72 hours.

The Risk Intelligence team was tasked with answering four questions before the board convened:

- **Who** — which customers and accounts are high risk?
- **What** — what types of transactions are suspicious?
- **When** — what time patterns characterise the fraud?
- **Where** — which channels, merchants, and geographies are implicated?

---

## 3. Data Sources & Schema

The investigation used NorthAxis Bank's Gold layer data warehouse. Because data at the Gold layer has already been cleaned, validated, and standardised upstream, no additional data cleaning was required. The schema follows a standard star schema with one fact table and five dimension tables.

| Table | Description |
|---|---|
| `fact_transactions` | Core transaction ledger — one row per transaction |
| `dim_customer` | Customer profile including registered country |
| `dim_merchant` | Merchant details including category |
| `dim_location` | Transaction location including country |
| `dim_date` | Date dimension including month and hour |
| `dim_account` | Account-level details |

**Data Period:** January 2024 – September 2024

**Tools Used:**
- MySQL 8.0 — data exploration, flagging, and aggregation
- Python (pandas) — fraud risk scoring and tier assignment
- Power BI Desktop — executive dashboard and report

---

## 4. Methodology

The investigation was structured across six analytical phases.

### Phase 1 — Transaction Baseline & KPIs
Aggregate baselines were established across all transactions to define what "normal" looks like before anomaly detection. Metrics calculated included total volume and value by month, channel, country, and merchant category. This phase established the baseline against which suspicious activity was measured.

### Phase 2 — Anomaly Detection & Flag Creation
Four binary fraud flags were created for every transaction in the dataset. A transaction was only classified as suspicious if it met **three or more** of the following four conditions simultaneously. This threshold was deliberately strict to minimise false positives and ensure only genuinely anomalous behaviour was surfaced.

**Flag 1 — Velocity Anomaly (`is_velocity_flag`)**
Triggered when the same customer made another transaction within 10 minutes AND the transaction amount exceeded the channel mean by more than 3 standard deviations. Implemented using the `LAG()` window function and `TIMESTAMPDIFF()` in MySQL.

**Flag 2 — Off-Hours Activity (`is_offhours_flag`)**
Triggered for transactions occurring between 01:00 and 03:59 AM, consistent with the brief's flagged signal of unusual digital activity during overnight hours.

**Flag 3 — Geographic Mismatch (`is_geomismatch_flag`)**
Triggered when the transaction country (from `dim_location`) did not match the customer's registered country (from `dim_customer`), indicating account access from an unregistered jurisdiction.

**Flag 4 — Statistical Amount Outlier (`is_outlier_flag`)**
Triggered when the transaction amount exceeded the customer's channel-adjusted mean by more than 3 standard deviations — identifying spend abnormal relative to that customer's own history and their channel peer group.

All four flags were combined into a `total_flag_count` column per transaction. The flagging logic was saved as a reusable database view:

### Phase 3 — Customer Risk Profiling
Customer-level behavioural baselines were constructed including total transactions, total spend, average transaction value, most common channel, most common merchant category, and most common transaction hour.

Customers were then ranked by the total number of flags accumulated across all their transactions. Only customers whose transactions met the `total_flag_count >= 3` threshold were included in the high-risk watchlist, ensuring that only accounts with confirmed multi-signal suspicious behaviour were surfaced:

### Phase 4 — Merchant & Channel Risk Scoring
Merchants and channels were ranked by the **proportion** of their activity that was flagged — isolating where fraud is concentrated rather than where volume is simply high. A cross-tabulation of channel × transaction hour identified the highest-risk time and channel combinations.

### Phase 5 — Fraud Risk Scoring Model
Risk tiers were assigned to each customer based on their `total_fraud_flags` count. Customers who accumulated flags across three or more distinct fraud signal types were classified as High Risk. The tier boundaries are as follows:

| Tier | Criteria |
|---|---|
| High Risk | total_fraud_flags in top tier AND met ≥ 3 flag conditions |
| Medium Risk | Met ≥ 2 flag conditions |
| Low Risk | Met < 2 flag conditions |

---

## 5. Key Findings

### Finding 1 — Scale of Exposure
The investigation identified 26 high-risk accounts with a combined 728 suspicious transactions totalling **$24.35 million** in at-risk exposure. This significantly exceeds the $2.3M initial audit estimate, suggesting the internal audit captured only a subset of the suspicious activity window.

### Finding 2 — Off-Hours Concentration Confirmed
The off-hours signal was confirmed by the data. The highest concentration of suspicious transaction value occurs at **2AM and 3AM**, almost exclusively through Mobile Banking and Web Banking channels. Physical channels show minimal activity during these hours, consistent with automated or remotely operated fraudulent activity.

### Finding 3 — Geographic Mismatch in Sanctioned Jurisdictions
Transaction activity was detected originating from high-risk and sanctioned jurisdictions including **North Korea, Iran, Syria, Cuba, Venezuela, and Russia** — countries inconsistent with the bank's operating footprint. This finding extends beyond fraud risk into potential **sanctions compliance exposure** and requires immediate escalation to the Legal and Compliance team independently of this fraud investigation.

### Finding 4 — Digital Channels Disproportionately Implicated
Mobile Banking and Web Banking account for a disproportionate share of flagged transaction value relative to their overall share of transaction volume. This suggests the fraud vector is primarily **digital account compromise** rather than physical card skimming or branch-level fraud.

### Finding 5 — Merchant Concentration
Retail, Travel, Food & Dining, Electronics, and Entertainment merchant categories show the highest counts of flagged transactions — consistent with rapid spend-out behaviour following account compromise. ATM and Wire Transfer show lower flagged counts but higher average flagged transaction values, consistent with cash-out behaviour in the later stages of fraud.

### Finding 6 — Top Risk Accounts

| Rank | Customer | Risk Tier | Total Fraud Flags | Most Common Suspicious Hour |
|---|---|---|---|---|
| 1 | Fatima Obi | High Risk | 16 | 1AM |
| 2 | Garba Osei | High Risk | 14 | 4AM |
| 3 | Gbenga Dlamini | High Risk | 14 | 3AM |
| 4 | Harry Okafor | High Risk | 14 | 3AM |
| 5 | Aisha Hughes | High Risk | 13 | 1AM |

---

## 6. Recommendations

### Immediate Actions (0–72 hours)
- **Freeze or restrict** the top High Risk accounts pending manual review — prioritise Fatima Obi, Garba Osei, Gbenga Dlamini, Harry Okafor, and Aisha Hughes
- **Escalate the sanctioned jurisdiction findings** to Legal and Compliance immediately — transactions originating from North Korea, Iran, and Syria may constitute sanctions violations requiring regulatory notification
- **Implement enhanced authentication** on Mobile Banking and Web Banking channels between 12AM and 5AM — consider step-up verification for transactions above $500 during this window

### Short-Term Actions (1–4 weeks)
- **Manually review** all Medium Risk accounts before deciding on restrictions
- **Engage flagged customers** through the bank's standard fraud review process — some may have legitimate explanations such as international travel or authorised third-party access
- **Audit Mobile Banking authentication logs** for the 6-week suspicious window — the velocity and off-hours patterns suggest possible credential compromise at scale

### Longer-Term Actions (1–3 months)
- **Operationalise velocity monitoring** as a real-time alert rule in the transaction processing system
- **Expand geographic controls** — implement step-up authentication for transactions originating from outside a customer's registered country
- **Schedule recurring fraud scoring** — run the scoring model monthly so the watchlist stays current

---

## 7. Data Caveats & Limitations

| # | Caveat | Potential Impact |
|---|---|---|
| 1 | Off-hours threshold (01:00–03:59 AM) is analytically assumed | Activity at 4:00–5:00 AM may be undercounted |
| 2 | Velocity window set at 10 minutes | A wider window may capture slower fraud patterns |
| 3 | Outlier threshold set at mean + 3σ per channel | Cases between 2σ and 3σ are not flagged |
| 4 | Risk score weights are based on analytical judgement, not a trained model | Weights should be validated by the Risk team before operational use |
| 5 | Most common channel uses arbitrary tie-breaking where usage is equal | Affects customers with equal channel usage counts |
| 6 | Customers with fewer than 5 transactions have statistically unreliable deviation scores | Manual review recommended for low-history accounts |
| 7 | Analysis covers January–September 2024 only | Activity outside this window is not reflected |
| 8 | The $24.35M figure represents total value of flagged transactions, not confirmed losses | Actual confirmed losses will be lower following manual review |

---

## 8. Technical Appendix

**Database:** MySQL 8.0
**BI Tool:** Microsoft Power BI Desktop
**Scoring:** Python 3.x, pandas

**Key SQL objects created:**
- `suspicious_transactions_view` — all transactions with four flag columns and `total_flag_count`
- Phase 2–5 queries exported as CSVs for Power BI ingestion

**Power BI Report Structure:**
- Page 1 — Executive Summary (KPI cards, top accounts, off-hours chart)
- Page 2 — Transaction Anomalies (monthly trend, channel × hour heatmap, geographic distribution)
- Page 3 — Customer Watchlist (risk-ranked table with conditional formatting)
- Page 4 — Merchant Watchlist (flagged value by channel, flagged count by merchant category)

---

