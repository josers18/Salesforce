-- ============================================================================
-- TROUBLESHOOTING: Why is generate_daily_transactions(10) generating nothing?
-- ============================================================================

-- Step 1: Check if ACCOUNT_CREDIT_CONFIG table has data
SELECT 'Step 1: Credit Config Count' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG;

-- Step 2: Check if there are ACTIVE accounts in credit config
SELECT 'Step 2: Active Credit Config Count' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
WHERE ACTIVE = TRUE;

-- Step 3: Check if FINANCIAL_TRANSACTION_ACCOUNTS has active accounts
SELECT 'Step 3: Active Master Accounts Count' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
WHERE ACTIVE = TRUE;

-- Step 4: Check if there are accounts in BOTH tables (the JOIN)
SELECT 'Step 4: Accounts in BOTH tables' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS a
JOIN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c ON a.ACCOUNTID = c.ACCOUNTID
WHERE a.ACTIVE = TRUE AND c.ACTIVE = TRUE;

-- Step 5: Check if MCC table exists and has data
SELECT 'Step 5: MCC Total Records' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.MCC;

-- Step 6: Check if MCC table has DEBIT transactions
SELECT 'Step 6: MCC Debit Records' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.MCC
WHERE TRAN_TYPE = 'Debit';

-- Step 7: Check if MCC table has CREDIT transactions (DD and Bonus)
SELECT 'Step 7: MCC Direct Deposit (9961)' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.MCC
WHERE MCC = 9961
UNION ALL
SELECT 'Step 7: MCC Bonus (9963)' AS check_name, COUNT(*) AS result
FROM FINS.PUBLIC.MCC
WHERE MCC = 9963;

-- ============================================================================
-- Detailed diagnostics - view sample records
-- ============================================================================

-- View sample credit config records
SELECT 'CREDIT CONFIG SAMPLE' AS section, * 
FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG 
LIMIT 5;

-- View sample master account records
SELECT 'MASTER ACCOUNTS SAMPLE' AS section, ACCOUNTID, SFACCOUNTID, ACCOUNTTYPE, ACTIVE
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
LIMIT 5;

-- View sample MCC debit records
SELECT 'MCC DEBIT SAMPLE' AS section, MCC, DESCRIPTION, TRAN_TYPE, TRAN_CATEGORY, CATEGORY
FROM FINS.PUBLIC.MCC
WHERE TRAN_TYPE = 'Debit'
LIMIT 5;

-- ============================================================================
-- Test the exact JOIN that the stored procedure uses
-- ============================================================================

SELECT 
    a.ACCOUNTID,
    a.SFACCOUNTID,
    a.CONTACTID,
    a.ACCOUNTTYPE,
    a.ACTIVE AS MASTER_ACTIVE,
    c.DIRECT_DEPOSIT_AMOUNT,
    c.BONUS_AMOUNT,
    c.ACTIVE AS CONFIG_ACTIVE,
    c.DD_DAY_1,
    c.DD_DAY_2
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS a
JOIN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c ON a.ACCOUNTID = c.ACCOUNTID
WHERE a.ACTIVE = TRUE AND c.ACTIVE = TRUE;

-- ============================================================================
-- Check what today's date means for credit generation
-- ============================================================================

SELECT 
    CURRENT_DATE() AS TODAY,
    DAY(CURRENT_DATE()) AS DAY_OF_MONTH,
    MONTH(CURRENT_DATE()) AS MONTH_NUMBER,
    CASE 
        WHEN DAY(CURRENT_DATE()) = 1 THEN 'YES - DD + possibly bonus'
        WHEN DAY(CURRENT_DATE()) = 15 THEN 'YES - DD only'
        ELSE 'NO - Debits only'
    END AS WILL_GENERATE_CREDITS,
    CASE 
        WHEN DAY(CURRENT_DATE()) = 1 AND MONTH(CURRENT_DATE()) IN (1,4,7,10) 
        THEN 'YES - Quarterly Bonus Day!'
        ELSE 'NO'
    END AS IS_BONUS_DAY;
