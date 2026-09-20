# Diagnosing the Revenue Slowdown at NovaByte Solutions

**A cross-functional business analytics project** — cleaning, SQL, statistical testing, and an executive Power BI dashboard, built to diagnose a revenue slowdown across Sales, Marketing, Support, and Finance for a case-study company.

> Personal project, built to demonstrate end-to-end analytics skills — from raw data to executive-ready recommendations.
> **Author:** Satyabrata Sahoo | [LinkedIn](https://linkedin.com/in/imsatya16/) | [GitHub](https://github.com/imsatya16/)

---

## The Business Problem

NovaByte Solutions, a mid-sized IT services company, saw revenue growth flatten starting Q3-2024 — despite Sales reporting a healthy pipeline, Marketing reporting rising lead volume, and Finance approving higher quarterly budgets. Client satisfaction was dipping and Support escalations were climbing. Leadership needed a data-driven, cross-functional diagnosis: **where exactly is the breakdown happening, and what should be done about it?**

Five raw datasets (Clients, Sales_Deals, Marketing_Campaigns, Support_Tickets, Finance_Expenses — ~8,000 rows combined) were explored, cleaned, queried, statistically tested, and finally consolidated into a 5-page executive dashboard.

## Key Findings

| Finding | Detail |
|---|---|
| **Revenue is down 33.5%** | ₹2.33 Cr (Q1-2023) → ₹1.55 Cr (Q1-2025) — a 9-quarter decline, not a blip |
| **Not a sales execution problem** | Win rate is healthy (61–67%) and consistent across every region; statistically confirmed unrelated to lead channel (χ²=0.037, p=0.848) |
| **A real marketing channel goes untracked** | "Cold Outreach" generated ₹2.07 Cr in closed deals with zero recorded marketing spend |
| **Support fails hardest exactly where it matters most** | Critical-priority tickets have the *worst* SLA compliance (34.6%) of any priority level |
| **Finance's aggregate health hides a real backlog** | ₹8.99 Cr sitting in 181 unresolved high-value expense approvals |
| **High ticket volume predicts churn** | 3 of the top 5 highest-ticket-volume clients have already churned, regardless of contract size |

Full statistical validation (chi-square, t-test, correlation, ANOVA, trend analysis) is in [`04_Statistics/`](https://github.com/imsatya16/novabyte_revenue_analytics/tree/main/04_Statistics) — including the null results, reported honestly rather than forced into a convenient narrative.

## Dashboard Preview

**Page 1 — Revenue Overview**
![Revenue Overview](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/Screenshots/01%20Revenue%20Overview.png)

**Page 2 — Marketing Effectiveness**
![Marketing Effectiveness](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/Screenshots/02 Marketing Effectiveness.png)

**Page 3 — Support Health**
![Support Health](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/Screenshots/03 Support Health.png)

**Page 4 — Finance Watch**
![Finance Watch](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/Screenshots/04 Finance Watch.png)

**Page 5 — Cross-Functional View**
![Cross-Functional View](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/Screenshots/05 Cross-Functional View.png)

> The full interactive file is [`05_PowerBI/NovaByte_Dashboard.pbix`](https://github.com/imsatya16/novabyte_revenue_analytics/blob/main/05_PowerBI/NovaByte_Dashboard.pbix) — open in [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (free) to explore it live, since `.pbix` files can't be previewed directly on GitHub.

## Approach

| Stage | What Was Done | Tools |
|---|---|---|
| **1. Exploration** | Column inventory, data quality audit, relationship mapping, KPI definitions | Manual review |
| **2. Cleaning & Sales/Finance Analysis** | Deduplication, mixed date-format resolution, outlier flagging, pivot analysis | Excel, Power Query |
| **3. Cross-Functional SQL** | 8 queries across Marketing and Support, joined on Client_ID and mapped lead sources | MySQL |
| **4. Statistical Testing** | 4 hypothesis tests + descriptive stats, distribution fit, ANOVA — built manually, not just Toolpak output | Excel (manual formulas) |
| **5. Dashboard & Recommendations** | 5-page executive dashboard; 7 evidence-backed recommendations with named owners | Power BI |

## Repository Structure

```
├── 00_Raw_Data/              Original uncleaned CSVs
├── 01_Exploration/           Data quality findings, relationship diagram, KPIs
├── 02_Excel_Analysis/        Cleaned Sales & Finance workbook, pivots, charts
├── 03_SQL/                   Schema setup + 8 analysis queries, findings report
├── 04_Statistics/            Hypothesis tests, workbook, detailed report
├── 05_PowerBI/                Dashboard (.pbix), data model, findings report, screenshots
├── 06_Recommendations/        7 evidence-backed business recommendations
└── 07_Clean_Dataset/          Final cleaned versions of all 5 tables
```

## A Note on the Process

A meaningful part of this project was catching and fixing subtle data issues that don't announce themselves — two different date formats mixed in the same column, a trailing character silently breaking exact-match filters, a flag column that mislabeled 61 records without changing the total count. Each is documented where it was found, because a wrong number that looks right is a worse problem than one that's obviously broken.

---

*Questions or feedback? Reach out on [LinkedIn](https://linkedin.com/in/imsatya16/).*
