-- Schema setup — run once before the analysis queries.
-- Creates the database and loads the 5 cleaned tables.

CREATE DATABASE IF NOT EXISTS novabyte_capstone;
USE novabyte_capstone;

DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS sales_deals;
DROP TABLE IF EXISTS marketing_campaigns;
DROP TABLE IF EXISTS finance_expenses;
DROP TABLE IF EXISTS clients;

CREATE TABLE clients (
    Client_ID VARCHAR(10) PRIMARY KEY,
    Company_Name VARCHAR(100),
    Industry VARCHAR(50),
    Contract_Type VARCHAR(50),
    Region VARCHAR(20),
    City VARCHAR(50),
    Onboarding_Date DATE,
    Satisfaction_Score DECIMAL(3 , 1) NULL,
    Tenure_Years DECIMAL(4 , 1),
    Annual_Contract_Value INT,
    Account_Status VARCHAR(20)
);

CREATE TABLE sales_deals (
    Deal_ID VARCHAR(12),
    Sales_Rep VARCHAR(50),
    Client_ID VARCHAR(10),
    Product VARCHAR(50),
    Lead_Source VARCHAR(30),
    Deal_Stage VARCHAR(20),
    Deal_Value_INR INT,
    Created_Date DATE,
    Close_Date DATE NULL,
    Days_to_Close INT NULL,
    Discount_Percent DECIMAL(4 , 1) NULL,
    Region VARCHAR(20),
    Quarter VARCHAR(10),
    Outlier_Flag VARCHAR(20)
);

CREATE TABLE marketing_campaigns (
    Campaign_ID VARCHAR(12),
    Campaign_Name VARCHAR(100),
    Channel VARCHAR(30),
    Campaign_Type VARCHAR(30),
    Start_Date DATE,
    End_Date DATE,
    Budget_INR INT,
    Impressions INT,
    Clicks INT,
    MQLs INT,
    SQLs INT,
    Conversions INT,
    CTR_Percent DECIMAL(5 , 2),
    Cost_Per_Click DECIMAL(10 , 2),
    Customer_Acquisition_Cost DECIMAL(12 , 2),
    Target_Region VARCHAR(20),
    Target_Industry VARCHAR(50),
    Quarter VARCHAR(10),
    Quarter_Sort INT
);

CREATE TABLE support_tickets (
    Ticket_ID VARCHAR(12),
    Client_ID VARCHAR(10),
    Product VARCHAR(50),
    Issue_Type VARCHAR(50),
    Priority VARCHAR(20),
    Created_Date DATE,
    Resolved_Date DATE NULL,
    Resolution_Hours DECIMAL(6 , 1) NULL,
    SLA_Target_Hours INT,
    SLA_Met VARCHAR(10),
    Status VARCHAR(20),
    Assigned_Agent VARCHAR(50),
    Contact_Channel VARCHAR(20),
    Customer_Satisfaction INT NULL
);

CREATE TABLE finance_expenses (
    Expense_ID VARCHAR(12),
    Department VARCHAR(30),
    Category VARCHAR(30),
    Vendor VARCHAR(50),
    Amount_INR INT,
    Budget_Allocated_INR DECIMAL(12 , 2) NULL,
    Variance_INR DECIMAL(12 , 2) NULL,
    Expense_Date DATE,
    Approval_Status VARCHAR(20),
    Payment_Mode VARCHAR(30),
    Fiscal_Year VARCHAR(15),
    Remarks VARCHAR(100) NULL,
    Amount_Type_Flag VARCHAR(20),
    High_Value_Pending_Rejected_Flag VARCHAR(30)
);

-- Loading notes:
-- CHARACTER SET latin1 — without it the import throws a conversion
-- error (a stray \r was turning up at the end of some rows).
-- LINES TERMINATED BY '\r\n' — plain '\n' still finds every row, but
-- leaves a trailing \r stuck to the last column, which broke exact
-- filters like WHERE Account_Status = 'Churned'.
-- NULLIF — turns blank cells into real NULLs so numeric/date columns
-- don't fail their type check.

LOAD DATA INFILE 'Enter path to/Clients.csv'
INTO TABLE clients
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Client_ID, Company_Name, Industry, Contract_Type, Region, City, Onboarding_Date, @Satisfaction_Score, Tenure_Years, Annual_Contract_Value, Account_Status)
SET Satisfaction_Score = NULLIF(@Satisfaction_Score, '');

LOAD DATA INFILE 'Enter path to/Sales_Deals.csv'
INTO TABLE sales_deals
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Deal_ID, Sales_Rep, Client_ID, Product, Lead_Source, Deal_Stage, Deal_Value_INR, Created_Date, @Close_Date, @Days_to_Close, @Discount_Percent, Region, Quarter, Outlier_Flag)
SET
    Close_Date = NULLIF(@Close_Date, ''),
    Days_to_Close = NULLIF(@Days_to_Close, ''),
    Discount_Percent = NULLIF(@Discount_Percent, '');

LOAD DATA INFILE 'Enter path to/Marketing_Campaigns.csv'
INTO TABLE marketing_campaigns
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Support_Tickets kept failing on the same \r issue even with the fix
-- above, so this one loads into an all-text staging table first, then
-- gets inserted into the real table with NULLIF cleanup applied.

CREATE TABLE support_tickets_staging (
    Ticket_ID VARCHAR(20), Client_ID VARCHAR(20), Product VARCHAR(50),
    Issue_Type VARCHAR(50), Priority VARCHAR(20), Created_Date VARCHAR(20),
    Resolved_Date VARCHAR(20), Resolution_Hours VARCHAR(20), SLA_Target_Hours VARCHAR(20),
    SLA_Met VARCHAR(20), Status VARCHAR(20), Assigned_Agent VARCHAR(50),
    Contact_Channel VARCHAR(20), Customer_Satisfaction VARCHAR(20)
);

LOAD DATA INFILE 'Enter path to/Support_Tickets.csv'
INTO TABLE support_tickets_staging
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

INSERT INTO support_tickets
SELECT
    Ticket_ID, Client_ID, Product, Issue_Type, Priority,
    STR_TO_DATE(Created_Date, '%Y-%m-%d'),
    NULLIF(Resolved_Date, ''),
    NULLIF(Resolution_Hours, ''),
    SLA_Target_Hours,
    SLA_Met, Status, Assigned_Agent, Contact_Channel,
    NULLIF(Customer_Satisfaction, '')
FROM support_tickets_staging;

DROP TABLE support_tickets_staging;

LOAD DATA INFILE 'Enter path to/Finance_Expenses.csv'
INTO TABLE finance_expenses
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(Expense_ID, Department, Category, Vendor, Amount_INR, @Budget_Allocated_INR, @Variance_INR, Expense_Date, Approval_Status, Payment_Mode, Fiscal_Year, @Remarks, Amount_Type_Flag, High_Value_Pending_Rejected_Flag)
SET
    Budget_Allocated_INR = NULLIF(@Budget_Allocated_INR, ''),
    Variance_INR = NULLIF(@Variance_INR, ''),
    Remarks = NULLIF(@Remarks, '');

-- Client_ID is the only reliable key across tables
ALTER TABLE sales_deals
ADD CONSTRAINT fk_sales_client FOREIGN KEY (Client_ID) REFERENCES clients(Client_ID);

ALTER TABLE support_tickets
ADD CONSTRAINT fk_support_client FOREIGN KEY (Client_ID) REFERENCES clients(Client_ID);

-- Sanity check — should return 0. Confirms Resolved_Date is always on
-- or after Created_Date (catches any leftover date-format issues from
-- the mixed formats in the raw Support_Tickets data).
SELECT COUNT(*) FROM support_tickets
WHERE Resolved_Date IS NOT NULL AND Resolved_Date < Created_Date;
