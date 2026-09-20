USE novabyte_capstone;


-- Query 26: Calculate total spend, total MQLs, total conversions,
-- and average Customer Acquisition Cost (CAC) by Channel.

/*
 Groups every campaign by its Channel (Google Ads, Email, etc.) and
rolls up four separate measures for each one:
- Total_Spend: sum of all budgets spent on that channel
- Total_MQLs / Total_Conversions: total leads and closed conversions generated through that channel
- Avg_CAC: average cost to acquire one customer on that channel (this is an AVERAGE of each campaign's own CAC value, 
  not Total_Spend divided by Total_Conversions those can differ slightly if campaigns vary a lot in size)
*/

SELECT
    Channel,
    SUM(Budget_INR) AS Total_Spend,
    SUM(MQLs) AS Total_MQLs,
    SUM(Conversions) AS Total_Conversions,
    ROUND(AVG(Customer_Acquisition_Cost), 2) AS Avg_CAC
FROM marketing_campaigns
GROUP BY Channel
ORDER BY Total_Spend DESC;

/*
Finding: Google Ads has the largest spend (₹1.89 crore) AND the lowest
CAC (₹14,957) of any channel — it's both the biggest and the most
cost-efficient. Email is the opposite extreme: the smallest total spend
of any channel (₹1.05 crore) but by far the worst CAC (₹95,675) — over
6x more expensive per acquired customer than Google Ads.
*/


-- Query 27: Rank campaigns by ROI (Conversions / Budget).
-- Which campaign types consistently outperform?


/*
Part 1: Every individual campaign, ranked from best ROI to worst.
- ROI here = Conversions per Rupee spent, so a higher number is better.
- RANK() OVER (...) assigns 1 to the best campaign, 2 to the next, etc.
- NULLIF(Budget_INR, 0) guards against a divide-by-zero error, 
  in case any campaign somehow has a budget of exactly 0. 
*/

SELECT
    RANK() OVER (ORDER BY Conversions / NULLIF(Budget_INR, 0) DESC) AS ROI_Rank,
    Campaign_ID,
    Campaign_Name,
    Campaign_Type,
    Channel,
    Conversions,
    Budget_INR,
    ROUND(Conversions / NULLIF(Budget_INR, 0), 6) AS ROI
FROM marketing_campaigns
ORDER BY ROI_Rank;


/*
Part 2: Same idea, but rolled up to the Campaign_Type level, so we can 
		answer the actual question asked: which TYPE of campaign (not which
		single campaign) tends to perform best on average.
- AVG(Conversions / Budget) here means "average ROI across all campaigns
  of this type" — not total conversions divided by total budget.
*/

SELECT
    RANK() OVER (ORDER BY AVG(Conversions / NULLIF(Budget_INR, 0)) DESC) AS Type_Rank,
    Campaign_Type,
    ROUND(AVG(Conversions / NULLIF(Budget_INR, 0)), 6) AS Avg_ROI,
    COUNT(*) AS Campaign_Count  # how many campaigns of this type exist,
							    # so a "best" type based on just 1-2
								# campaigns can be spotted as less reliable
FROM marketing_campaigns
GROUP BY Campaign_Type
ORDER BY Type_Rank;

/*
Finding: Brand Awareness campaigns have the highest average ROI
(0.000553 conversions per Rupee spent, across 34 campaigns) — roughly
double the next-best type, Lead Generation (0.000274, also 34
campaigns). Event Promotion, Retargeting, and Product Launch all trail
meaningfully behind, in that order. Since both top types have the same
sample size (34 campaigns each), this isn't just one lucky outlier
dragging the average up — Brand Awareness genuinely, consistently
outperforms.
*/

-- Query 28: Join Marketing_Campaigns with Sales_Deals on Lead_Source to see
-- which marketing channels generate deals that actually close. What is the
-- closed-deal value attributed to each channel?

/*
sales_deals.Lead_Source and marketing_campaigns.Channel don't use identical
names, so a straight JOIN would miss real matches. Mapping used below:
  Google Ads, Trade Show, Webinar   -> exact name match, no change needed
  Email Campaign   -> Email
  LinkedIn Campaign -> LinkedIn
  Organic Search    -> SEO
  Cold Outreach, Referral, Unknown  -> no tracked-campaign equivalent
    (kept as-is; these leads simply didn't come from a tracked campaign,
    which is itself a finding worth reporting, not an error to fix)
*/

SELECT
    CASE
        WHEN Lead_Source = "Email Campaign"    THEN "Email"
        WHEN Lead_Source = "LinkedIn Campaign"  THEN "LinkedIn"
        WHEN Lead_Source = "Organic Search"      THEN "SEO"
        ELSE Lead_Source
    END AS Mapped_Channel,
    COUNT(*) AS Total_Deals,   # every deal from this channel, won or lost
    COUNT(CASE WHEN Deal_Stage = 'Closed Won' THEN 1 END) AS Deals_Won,
    SUM(CASE WHEN Deal_Stage = 'Closed Won' THEN Deal_Value_INR ELSE 0 END)
        AS Closed_Deal_Value
FROM sales_deals
GROUP BY Mapped_Channel
ORDER BY Closed_Deal_Value DESC;

/*
Finding: Trade Show tops closed-deal value (₹2.87 crore from 95 wins)
even though it isn't the spend or ROI leader in Queries 26/27 — offline,
in-person leads are converting well despite a smaller marketing push.
Cold Outreach (₹2.07 crore, 79 wins) — a channel with zero tracked
marketing spend at all — outperforms LinkedIn and Referral in raw closed
value, suggesting Sales is generating real revenue outside the
Marketing-tracked funnel entirely. Unknown lead source is smallest at
₹35.6 lakh, as expected given it's a small, unidentified slice of only
77 deals.
*/

-- Query 29: Calculate SLA compliance rate (percentage of tickets where
-- SLA was met) by Priority and by Product.

/*
SLA_Met holds three possible values: "Yes", "No", or "Unknown" (from
cleaning, where the original data had no recorded outcome). The rate
below is calculated against known outcomes only (Yes + No) — Unknown
tickets are shown as their own column so they're visible, not silently
dropped from the denominator or counted as a miss.
*/

-- By Priority
SELECT
    Priority,
    COUNT(CASE WHEN SLA_Met = "Yes" THEN 1 END) AS Met,
    COUNT(CASE WHEN SLA_Met = "No" THEN 1 END) AS Missed,
    COUNT(CASE WHEN SLA_Met = "Unknown" THEN 1 END) AS Unknown_Outcome,
    ROUND(
        COUNT(CASE WHEN SLA_Met = "Yes" THEN 1 END) /
        NULLIF(COUNT(CASE WHEN SLA_Met IN ("Yes","No") THEN 1 END), 0)* 100
    , 2) AS SLA_Compliance_Rate
FROM support_tickets
GROUP BY Priority
ORDER BY SLA_Compliance_Rate;

/*
Finding: SLA compliance is weak everywhere (35-41% across the board) —
this backs up the original concern about SLA breaches. The most
concerning pattern: compliance is WORST for Critical-priority tickets
(34.6%) and best for the catch-all "Unspecified" priority bucket
(40.5%) — exactly backwards from what you'd want, since Critical
tickets carry the tightest SLA targets and the most at stake. By
product, CloudShift Platform is weakest (33.9%) and DataVault Pro
strongest (43.1%).
*/

-- By Product (same logic, grouped by Product instead)
SELECT
    Product,
    COUNT(CASE WHEN SLA_Met = "Yes" THEN 1 END) AS Met,
    COUNT(CASE WHEN SLA_Met = "No" THEN 1 END) AS Missed,
    COUNT(CASE WHEN SLA_Met = "Unknown" THEN 1 END) AS Unknown_Outcome,
    ROUND(
        COUNT(CASE WHEN SLA_Met = "Yes" THEN 1 END) /
        NULLIF(COUNT(CASE WHEN SLA_Met IN ("Yes","No") THEN 1 END), 0)*100
    , 2)  AS SLA_Compliance_Rate
FROM support_tickets
GROUP BY Product
ORDER BY SLA_Compliance_Rate;


/*
Finding: SLA compliance by product ranges from 33.9% to 43.1% — a real
but modest spread. CloudShift Platform is the weakest performer (33.9%),
DataVault Pro the strongest (43.1%). Every product still sits well
below a healthy compliance rate regardless of which one it is, so this
is a smaller factor than Priority — no single product is driving the
overall SLA problem on its own.
*/

-- Query 30: Find the top 10 clients by ticket volume. Cross-reference
-- with the Clients table: are these high-value or low-value clients?

/*
Joins Support_Tickets to Clients on Client_ID so we can see each
high-ticket-volume client's contract value and account status alongside
their ticket count — not just the raw count on its own.
*/

SELECT
    c.Client_ID,
    c.Company_Name,
    c.Annual_Contract_Value,
    c.Account_Status,
    COUNT(t.Ticket_ID) AS Ticket_Count
FROM support_tickets t
JOIN clients c ON t.Client_ID = c.Client_ID
GROUP BY c.Client_ID, c.Company_Name, c.Annual_Contract_Value, c.Account_Status
ORDER BY Ticket_Count DESC
LIMIT 10;

/*
Finding: it's a mixed picture, not cleanly "high-value" or "low-value."
The top-ticket-volume client (BrightPath Labs, 34 tickets) has a modest
₹75,000 contract and has already Churned. GreenPulse Corp (#2, 32
tickets) has also churned. Notably, NetDynamic Group (#5, 27 tickets) is
a ₹5,00,000 contract — one of the largest in the top 10 — and it
churned too. 3 of the top 5 heaviest ticket-volume clients have already
left, regardless of contract size, which is worth flagging as a possible
early-warning signal: unusually high ticket volume may predict churn
risk on its own, independent of how valuable the account is.
*/

-- Query 31: Calculate average resolution time by Issue_Type. Which issue
-- types take the longest and have the lowest satisfaction scores?

/*
AVG() automatically skips NULL values, so this doesn't need any special
handling for the blanks left over from cleaning — tickets that aren't
yet resolved (blank Resolution_Hours) or have no survey response (blank
Customer_Satisfaction) are simply excluded from their respective
averages, not counted as zero.
*/

SELECT
    Issue_Type,
    COUNT(*) AS Ticket_Count,
    ROUND(AVG(Resolution_Hours), 1) AS Avg_Resolution_Hours,
    ROUND(AVG(Customer_Satisfaction), 2) AS Avg_Satisfaction
FROM support_tickets
GROUP BY Issue_Type
ORDER BY Avg_Resolution_Hours DESC;


/*
Finding: Access Permission Issue is slowest overall (31.8 hrs) but
doesn't have the worst satisfaction (3.68, mid-pack). Data Sync Error is
the standout problem case — 2nd-slowest (31.1 hrs) AND tied for the
lowest satisfaction score (3.56) — it's slow AND poorly rated, unlike
most other issue types where slow resolution doesn't necessarily mean an
unhappy customer. Login Issue is the fastest to resolve (27.1 hrs) and
also rates well (3.78).
*/

-- Query 32: Join Clients with Support_Tickets and Sales_Deals: do clients
-- with more support escalations tend to have lower satisfaction scores
-- and fewer repeat deals?

/*
Built as three steps: first summarize each client's ticket/escalation
counts, then summarize each client's deal counts, then join both
summaries onto Clients. Finally, bucket clients by escalation count and
compare AVERAGES across the buckets — that comparison is the actual
answer to the question, not the raw per-client row list.
*/

WITH ticket_summary AS (
    SELECT
        Client_ID,
        COUNT(*) AS Total_Tickets,
        COUNT(CASE WHEN Status = "Escalated" THEN 1 END) AS Escalations
    FROM support_tickets
    GROUP BY Client_ID
),
deal_summary AS (
    SELECT
        Client_ID,
        COUNT(*) AS Total_Deals,
        COUNT(CASE WHEN Deal_Stage = "Closed Won" THEN 1 END) AS Deals_Won
    FROM sales_deals
    GROUP BY Client_ID
),
client_level AS (
    SELECT
        c.Client_ID,
        c.Satisfaction_Score,
        COALESCE(ts.Escalations, 0) AS Escalations,
        COALESCE(ds.Total_Deals, 0) AS Total_Deals,
        COALESCE(ds.Deals_Won, 0) AS Deals_Won
    FROM clients c
    LEFT JOIN ticket_summary ts ON c.Client_ID = ts.Client_ID
    LEFT JOIN deal_summary ds ON c.Client_ID = ds.Client_ID
)
SELECT
    CASE
        WHEN Escalations = 0 THEN "0 escalations"
        WHEN Escalations BETWEEN 1 AND 2 THEN "1-2 escalations"
        ELSE "3+ escalations"
    END AS Escalation_Bucket,
    COUNT(*) AS Client_Count,
    ROUND(AVG(Satisfaction_Score), 2) AS Avg_Satisfaction,
    ROUND(AVG(Total_Deals), 1) AS Avg_Total_Deals,
    ROUND(AVG(Deals_Won), 1) AS Avg_Deals_Won
FROM client_level
GROUP BY Escalation_Bucket
ORDER BY Escalation_Bucket;

/*
Finding: the hypothesis does NOT hold in this data. Average satisfaction
is essentially flat across escalation buckets (3.74 / 3.83 / 3.74 for
0 / 1-2 / 3+ escalations) — no meaningful decline. Deal activity actually
trends the OPPOSITE direction from what was expected: clients with 3+
escalations average MORE total deals (9.8) than clients with zero
escalations (7.4), not fewer. The likely explanation is account size,
not dissatisfaction — clients who do more business with NovaByte
naturally generate more tickets and more escalations simply by having
more touchpoints, which masks any real satisfaction effect. Reporting
this honestly rather than forcing the expected narrative.
*/


-- Query 33: Compare regions by combining Sales revenue, Marketing spend,
-- Support SLA compliance, and Finance expenses. Which region has the
-- best and worst overall health?

/*
Finance_Expenses has no Region column at all — only Department — so
Finance spend genuinely cannot be included here. That's stated directly
below rather than forced with an invented mapping.

Built in three pieces: Sales revenue by region (with client count, so we
can normalize per the brief's own hint about not comparing raw totals),
Marketing spend by Target_Region ('All Regions' campaigns excluded,
since we don't know their true regional split), and Support SLA
compliance by region (joined through Clients, since Support_Tickets has
no Region column of its own).
*/

WITH sales_by_region AS (
    SELECT
        Region,
        SUM(CASE WHEN Deal_Stage = "Closed Won" THEN Deal_Value_INR ELSE 0 END) AS Revenue,
        COUNT(DISTINCT Client_ID) AS Client_Count
    FROM sales_deals
    GROUP BY Region
),
marketing_by_region AS (
    SELECT Target_Region AS Region, SUM(Budget_INR) AS Spend
    FROM marketing_campaigns
    WHERE Target_Region <> "All Regions"
    GROUP BY Target_Region
),
support_by_region AS (
    SELECT
        c.Region,
        ROUND(
            COUNT(CASE WHEN t.SLA_Met = "Yes" THEN 1 END) /
            NULLIF(COUNT(CASE WHEN t.SLA_Met IN ("Yes","No") THEN 1 END), 0)* 100
        , 2) AS SLA_Rate
    FROM support_tickets t
    JOIN clients c ON t.Client_ID = c.Client_ID
    GROUP BY c.Region
)
SELECT
    sr.Region,
    sr.Revenue,
    ROUND(sr.Revenue / NULLIF(sr.Client_Count, 0), 0) AS Revenue_Per_Client,
    mr.Spend,
    sup.SLA_Rate
FROM sales_by_region sr
LEFT JOIN marketing_by_region mr ON sr.Region = mr.Region
LEFT JOIN support_by_region sup ON sr.Region = sup.Region;

/*
Finding (ranked by Revenue_Per_Client, per the brief's own hint to
normalize rather than compare raw totals):
  North: ₹1,75,020/client — highest revenue efficiency, but also the
         weakest SLA compliance (35.38%) of any region
  South: ₹1,65,318/client — 2nd-best revenue, BEST SLA compliance
         (39.02%), and the lowest marketing spend (₹1.70 crore) of any
         region — South looks like the healthiest region overall:
         strong revenue per client, best support delivery, most
         efficient marketing spend
  West:  ₹1,63,268/client — mid-pack on every measure
  East:  ₹1,53,419/client — lowest revenue per client despite the 2nd
         highest marketing spend (₹2.19 crore) — the weakest return on
         marketing investment of the four regions

Best overall: South. Worst overall: East (spends heavily but converts
that spend into the least revenue per client). Finance expenses could
not be included in this comparison — see note above.
*/