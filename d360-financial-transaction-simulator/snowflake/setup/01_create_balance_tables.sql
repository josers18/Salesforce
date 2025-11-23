-- ============================================================================
-- ACCOUNT CREDIT CONFIGURATION AND BALANCE TRACKING TABLES
-- ============================================================================
-- Database: FINS
-- Schema: PUBLIC
-- ============================================================================

-- USE DATABASE FINS;
-- USE SCHEMA PUBLIC;

-- ============================================================================
-- TABLE 1: ACCOUNT_CREDIT_CONFIG
-- Stores direct deposit and bonus configuration for each account
-- ============================================================================

CREATE OR REPLACE TABLE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG (
    ACCOUNTID VARCHAR(50) PRIMARY KEY,
    SFACCOUNTID VARCHAR(18),
    CONTACTID VARCHAR(18),
    ACCOUNT_TYPE VARCHAR(20),  -- Personal or Business
    DIRECT_DEPOSIT_AMOUNT DECIMAL(15,2) NOT NULL,
    BONUS_AMOUNT DECIMAL(15,2) NOT NULL,
    DD_DAY_1 INTEGER DEFAULT 1,  -- First direct deposit day of month
    DD_DAY_2 INTEGER DEFAULT 15, -- Second direct deposit day of month
    BONUS_FREQUENCY VARCHAR(20) DEFAULT 'QUARTERLY', -- QUARTERLY, MONTHLY, ANNUAL
    ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    LAST_UPDATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    NOTES VARCHAR(500)
);

COMMENT ON TABLE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG IS 
'Configuration table for account direct deposits and bonuses. Used by transaction generator to ensure proper credit amounts.';

COMMENT ON COLUMN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG.DIRECT_DEPOSIT_AMOUNT IS 
'Amount for each direct deposit (occurs twice monthly on DD_DAY_1 and DD_DAY_2)';

COMMENT ON COLUMN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG.BONUS_AMOUNT IS 
'Amount for bonus payments (frequency set by BONUS_FREQUENCY)';

-- ============================================================================
-- TABLE 2: ACCOUNT_BALANCE_TRACKER
-- Tracks monthly credits, debits, and balances for each account
-- ============================================================================

CREATE OR REPLACE TABLE FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER (
    ACCOUNTID VARCHAR(50) NOT NULL,
    PERIOD_YEAR INTEGER NOT NULL,
    PERIOD_MONTH INTEGER NOT NULL,
    PERIOD_START_DATE DATE,
    PERIOD_END_DATE DATE,
    OPENING_BALANCE DECIMAL(15,2) DEFAULT 0.00,
    TOTAL_CREDITS DECIMAL(15,2) DEFAULT 0.00,
    TOTAL_DEBITS DECIMAL(15,2) DEFAULT 0.00,
    NET_BALANCE DECIMAL(15,2) DEFAULT 0.00,
    AVAILABLE_CREDIT DECIMAL(15,2) DEFAULT 0.00,  -- 80% of credits for spending
    CREDIT_UTILIZATION_PCT DECIMAL(5,2) DEFAULT 0.00,
    TRANSACTION_COUNT INTEGER DEFAULT 0,
    LAST_TRANSACTION_DATE TIMESTAMP_NTZ,
    LAST_UPDATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ACCOUNTID, PERIOD_YEAR, PERIOD_MONTH)
);

COMMENT ON TABLE FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER IS 
'Monthly balance tracking for all accounts. Updated by transaction generator to prevent overdrafts.';

COMMENT ON COLUMN FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER.AVAILABLE_CREDIT IS 
'80% of total credits - maximum allowed debits to maintain 20% buffer';

COMMENT ON COLUMN FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER.CREDIT_UTILIZATION_PCT IS 
'Percentage of available credit used (total_debits / available_credit * 100)';

-- ============================================================================
-- TABLE 3: ACCOUNT_DAILY_BALANCE
-- Tracks daily running balance for each account (optional - for detailed tracking)
-- ============================================================================

CREATE OR REPLACE TABLE FINS.PUBLIC.ACCOUNT_DAILY_BALANCE (
    ACCOUNTID VARCHAR(50) NOT NULL,
    BALANCE_DATE DATE NOT NULL,
    OPENING_BALANCE DECIMAL(15,2) DEFAULT 0.00,
    DAILY_CREDITS DECIMAL(15,2) DEFAULT 0.00,
    DAILY_DEBITS DECIMAL(15,2) DEFAULT 0.00,
    CLOSING_BALANCE DECIMAL(15,2) DEFAULT 0.00,
    TRANSACTION_COUNT INTEGER DEFAULT 0,
    LAST_UPDATED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (ACCOUNTID, BALANCE_DATE)
);

COMMENT ON TABLE FINS.PUBLIC.ACCOUNT_DAILY_BALANCE IS 
'Daily balance snapshots for detailed account tracking and historical analysis.';

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index on balance tracker for period lookups
CREATE INDEX IF NOT EXISTS IDX_BALANCE_TRACKER_PERIOD 
ON FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER(PERIOD_YEAR, PERIOD_MONTH);

-- Index on daily balance for date range queries
CREATE INDEX IF NOT EXISTS IDX_DAILY_BALANCE_DATE 
ON FINS.PUBLIC.ACCOUNT_DAILY_BALANCE(BALANCE_DATE);

-- Index on credit config for active accounts
CREATE INDEX IF NOT EXISTS IDX_CREDIT_CONFIG_ACTIVE 
ON FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG(ACTIVE);

-- ============================================================================
-- VIEWS FOR EASY QUERYING
-- ============================================================================

-- Current month balances for all accounts
CREATE OR REPLACE VIEW FINS.PUBLIC.VW_CURRENT_MONTH_BALANCES AS
SELECT 
    b.*,
    c.ACCOUNT_TYPE,
    c.DIRECT_DEPOSIT_AMOUNT,
    c.BONUS_AMOUNT,
    CASE 
        WHEN b.NET_BALANCE < 0 THEN 'OVERDRAWN'
        WHEN b.CREDIT_UTILIZATION_PCT > 90 THEN 'HIGH_UTILIZATION'
        WHEN b.CREDIT_UTILIZATION_PCT > 70 THEN 'MODERATE_UTILIZATION'
        ELSE 'GOOD_STANDING'
    END AS ACCOUNT_STATUS
FROM FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER b
JOIN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c ON b.ACCOUNTID = c.ACCOUNTID
WHERE b.PERIOD_YEAR = YEAR(CURRENT_DATE())
  AND b.PERIOD_MONTH = MONTH(CURRENT_DATE())
  AND c.ACTIVE = TRUE;

-- Account summary with all-time totals
CREATE OR REPLACE VIEW FINS.PUBLIC.VW_ACCOUNT_SUMMARY AS
SELECT 
    c.ACCOUNTID,
    c.SFACCOUNTID,
    c.ACCOUNT_TYPE,
    c.DIRECT_DEPOSIT_AMOUNT,
    c.BONUS_AMOUNT,
    c.ACTIVE,
    COUNT(DISTINCT CONCAT(b.PERIOD_YEAR, '-', b.PERIOD_MONTH)) AS MONTHS_ACTIVE,
    SUM(b.TOTAL_CREDITS) AS LIFETIME_CREDITS,
    SUM(b.TOTAL_DEBITS) AS LIFETIME_DEBITS,
    SUM(b.NET_BALANCE) AS CURRENT_BALANCE,
    AVG(b.CREDIT_UTILIZATION_PCT) AS AVG_UTILIZATION_PCT
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c
LEFT JOIN FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER b ON c.ACCOUNTID = b.ACCOUNTID
WHERE c.ACTIVE = TRUE
GROUP BY c.ACCOUNTID, c.SFACCOUNTID, c.ACCOUNT_TYPE, c.DIRECT_DEPOSIT_AMOUNT, c.BONUS_AMOUNT, c.ACTIVE;

COMMENT ON VIEW FINS.PUBLIC.VW_CURRENT_MONTH_BALANCES IS 
'Current month balance status for all active accounts with account status flags';

COMMENT ON VIEW FINS.PUBLIC.VW_ACCOUNT_SUMMARY IS 
'Lifetime summary statistics for all active accounts';

-- ============================================================================
-- GRANT PERMISSIONS (Adjust as needed for your environment)
-- ============================================================================

-- GRANT SELECT, INSERT, UPDATE ON FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG TO ROLE YOUR_ROLE;
-- GRANT SELECT, INSERT, UPDATE ON FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER TO ROLE YOUR_ROLE;
-- GRANT SELECT, INSERT, UPDATE ON FINS.PUBLIC.ACCOUNT_DAILY_BALANCE TO ROLE YOUR_ROLE;
-- GRANT SELECT ON FINS.PUBLIC.VW_CURRENT_MONTH_BALANCES TO ROLE YOUR_ROLE;
-- GRANT SELECT ON FINS.PUBLIC.VW_ACCOUNT_SUMMARY TO ROLE YOUR_ROLE;
