-- ============================================================================
-- POPULATE ACCOUNT_CREDIT_CONFIG FROM EXISTING ACCOUNTS
-- ============================================================================
-- This script initializes credit configuration for existing accounts
-- ============================================================================

-- USE DATABASE FINS;
-- USE SCHEMA PUBLIC;

-- ============================================================================
-- STEP 1: Populate from FINANCIAL_TRANSACTION_ACCOUNTS
-- ============================================================================

INSERT INTO FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG (
    ACCOUNTID,
    SFACCOUNTID,
    CONTACTID,
    ACCOUNT_TYPE,
    DIRECT_DEPOSIT_AMOUNT,
    BONUS_AMOUNT,
    DD_DAY_1,
    DD_DAY_2,
    BONUS_FREQUENCY,
    ACTIVE,
    NOTES
)
SELECT 
    ACCOUNTID,
    SFACCOUNTID,
    CONTACTID,
    ACCOUNTTYPE AS ACCOUNT_TYPE,
    -- Set direct deposit amounts based on account type
    CASE 
        WHEN ACCOUNTTYPE = 'Business' THEN 7500.00  -- Higher for business
        ELSE 3000.00  -- Standard for personal
    END AS DIRECT_DEPOSIT_AMOUNT,
    -- Set bonus amounts based on account type
    CASE 
        WHEN ACCOUNTTYPE = 'Business' THEN 1000.00  -- Higher quarterly bonus
        ELSE 500.00  -- Standard quarterly bonus
    END AS BONUS_AMOUNT,
    1 AS DD_DAY_1,     -- First direct deposit on 1st
    15 AS DD_DAY_2,    -- Second direct deposit on 15th
    'QUARTERLY' AS BONUS_FREQUENCY,
    ACTIVE,
    'Auto-populated from FINANCIAL_TRANSACTION_ACCOUNTS' AS NOTES
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
WHERE ACTIVE = TRUE
ON CONFLICT (ACCOUNTID) DO NOTHING;  -- Skip if already exists

-- ============================================================================
-- STEP 2: Display populated configuration
-- ============================================================================

SELECT 
    ACCOUNT_TYPE,
    COUNT(*) AS ACCOUNT_COUNT,
    AVG(DIRECT_DEPOSIT_AMOUNT) AS AVG_DD_AMOUNT,
    AVG(BONUS_AMOUNT) AS AVG_BONUS_AMOUNT,
    SUM(DIRECT_DEPOSIT_AMOUNT * 2) AS MONTHLY_DD_TOTAL,  -- 2 deposits per month
    SUM(BONUS_AMOUNT) AS QUARTERLY_BONUS_TOTAL
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
WHERE ACTIVE = TRUE
GROUP BY ACCOUNT_TYPE;

-- ============================================================================
-- STEP 3: Verify configuration
-- ============================================================================

SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    DIRECT_DEPOSIT_AMOUNT,
    BONUS_AMOUNT,
    CONCAT('$', DIRECT_DEPOSIT_AMOUNT * 2) AS MONTHLY_CREDITS,
    CONCAT('$', (DIRECT_DEPOSIT_AMOUNT * 2 * 12) + (BONUS_AMOUNT * 4)) AS ANNUAL_CREDITS,
    DD_DAY_1,
    DD_DAY_2,
    BONUS_FREQUENCY,
    ACTIVE
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
ORDER BY ACCOUNT_TYPE, ACCOUNTID
LIMIT 10;

-- ============================================================================
-- OPTIONAL: Manual override examples
-- ============================================================================

-- Example: Update specific account with custom amounts
-- UPDATE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
-- SET 
--     DIRECT_DEPOSIT_AMOUNT = 5000.00,
--     BONUS_AMOUNT = 750.00,
--     NOTES = 'Custom amounts for VIP account'
-- WHERE ACCOUNTID = 'ACC-001';

-- Example: Disable direct deposits for specific account
-- UPDATE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
-- SET 
--     DD_DAY_1 = NULL,
--     DD_DAY_2 = NULL,
--     NOTES = 'No direct deposits - manual deposits only'
-- WHERE ACCOUNTID = 'ACC-002';

-- Example: Change bonus to monthly instead of quarterly
-- UPDATE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
-- SET 
--     BONUS_FREQUENCY = 'MONTHLY',
--     BONUS_AMOUNT = 125.00,  -- Adjusted for monthly frequency
--     NOTES = 'Monthly bonus structure'
-- WHERE ACCOUNTID = 'ACC-003';
