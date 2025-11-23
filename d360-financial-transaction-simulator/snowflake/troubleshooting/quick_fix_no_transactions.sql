-- ============================================================================
-- QUICK FIX: Common Issues with generate_daily_transactions
-- ============================================================================

-- ISSUE 1: ACCOUNT_CREDIT_CONFIG table is empty
-- SOLUTION: Populate it from FINANCIAL_TRANSACTION_ACCOUNTS

-- Check if empty
SELECT COUNT(*) AS credit_config_count FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG;

-- If count is 0, run this to populate:
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
    CASE 
        WHEN ACCOUNTTYPE = 'Business' THEN 7500.00
        ELSE 3000.00
    END AS DIRECT_DEPOSIT_AMOUNT,
    CASE 
        WHEN ACCOUNTTYPE = 'Business' THEN 1000.00
        ELSE 500.00
    END AS BONUS_AMOUNT,
    1 AS DD_DAY_1,
    15 AS DD_DAY_2,
    'QUARTERLY' AS BONUS_FREQUENCY,
    ACTIVE,
    'Auto-populated from master accounts table' AS NOTES
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
WHERE ACTIVE = TRUE;

-- Verify populated
SELECT COUNT(*) AS credit_config_count FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG;

-- ============================================================================
-- ISSUE 2: MCC table doesn't have debit transactions
-- ============================================================================

-- Check debit count
SELECT 
    TRAN_TYPE,
    COUNT(*) AS count
FROM FINS.PUBLIC.MCC
GROUP BY TRAN_TYPE;

-- If no debits, check the column name (might be case sensitive)
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'MCC'
  AND COLUMN_NAME LIKE '%TRAN%TYPE%';

-- Try different case variations if needed
SELECT COUNT(*) FROM FINS.PUBLIC.MCC WHERE TRAN_TYPE = 'Debit';
SELECT COUNT(*) FROM FINS.PUBLIC.MCC WHERE "TRAN_TYPE" = 'Debit';
SELECT COUNT(*) FROM FINS.PUBLIC.MCC WHERE tran_type = 'Debit';

-- ============================================================================
-- ISSUE 3: Accounts exist but are not active
-- ============================================================================

-- Check active status
SELECT 
    ACTIVE,
    COUNT(*) AS account_count
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
GROUP BY ACTIVE;

-- If all are FALSE, activate them:
UPDATE FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
SET ACTIVE = TRUE
WHERE ACTIVE = FALSE OR ACTIVE IS NULL;

-- Also update credit config
UPDATE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
SET ACTIVE = TRUE
WHERE ACTIVE = FALSE OR ACTIVE IS NULL;

-- ============================================================================
-- ISSUE 4: Column name case sensitivity issues
-- ============================================================================

-- Check actual column names in MCC table
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'MCC'
ORDER BY ORDINAL_POSITION;

-- Check actual column names in FINANCIAL_TRANSACTION_ACCOUNTS
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'PUBLIC'
  AND TABLE_NAME = 'FINANCIAL_TRANSACTION_ACCOUNTS'
ORDER BY ORDINAL_POSITION;

-- ============================================================================
-- ISSUE 5: Test with a simple manual transaction insert
-- ============================================================================

-- If stored procedure still doesn't work, test manual insert:
INSERT INTO FINS.PUBLIC.FINANCIAL_TRANSACTIONS (
    ACCOUNTID,
    TRANSACTIONID,
    POSTINGDATE,
    TRANSACTIONDATE,
    AMOUNT,
    DESCRIPTION,
    TRANSACTION_CATEGORY,
    MCC,
    MCC_DESCRIPTION,
    TRANSACTION_STATUS,
    CURRENCY,
    TRANSACTION_TYPE,
    SOURCE_TRANSACTION_TYPE,
    DATA_DATE,
    SFACCOUNTID,
    CONTACTID,
    ACCOUNT_TYPE
)
SELECT 
    ACCOUNTID,
    UUID_STRING() AS TRANSACTIONID,
    CURRENT_TIMESTAMP() AS POSTINGDATE,
    CURRENT_TIMESTAMP() AS TRANSACTIONDATE,
    3000.00 AS AMOUNT,
    'Test Direct Deposit' AS DESCRIPTION,
    'Income' AS TRANSACTION_CATEGORY,
    9961 AS MCC,
    'Direct Deposit' AS MCC_DESCRIPTION,
    'Posted' AS TRANSACTION_STATUS,
    'USD' AS CURRENCY,
    'Credit' AS TRANSACTION_TYPE,
    'Credit' AS SOURCE_TRANSACTION_TYPE,
    CURRENT_TIMESTAMP() AS DATA_DATE,
    SFACCOUNTID,
    CONTACTID,
    ACCOUNTTYPE AS ACCOUNT_TYPE
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
WHERE ACTIVE = TRUE
LIMIT 1;

-- Check if test transaction was created
SELECT * FROM FINS.PUBLIC.FINANCIAL_TRANSACTIONS
ORDER BY TRANSACTIONDATE DESC
LIMIT 5;

-- ============================================================================
-- AFTER FIXING: Test the stored procedure again
-- ============================================================================

-- Try with a small number first
CALL generate_daily_transactions(2);

-- Check the return message
-- It should say something like:
-- "Successfully generated X transactions from Y active accounts..."

-- If it says "0 transactions" check the detailed diagnostics above
