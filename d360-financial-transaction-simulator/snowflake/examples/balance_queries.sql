-- ============================================================================
-- Balance Monitoring & Analysis Queries
-- ============================================================================

-- ============================================================================
-- Current Month Snapshot
-- ============================================================================

-- Overall status
SELECT 
    COUNT(*) AS total_accounts,
    SUM(TOTAL_CREDITS) AS total_credits,
    SUM(TOTAL_DEBITS) AS total_debits,
    SUM(NET_BALANCE) AS net_balance,
    AVG(CREDIT_UTILIZATION_PCT) AS avg_utilization,
    SUM(CASE WHEN ACCOUNT_STATUS = 'OVERDRAWN' THEN 1 ELSE 0 END) AS overdrawn_count,
    SUM(CASE WHEN ACCOUNT_STATUS = 'HIGH_UTILIZATION' THEN 1 ELSE 0 END) AS high_util_count
FROM VW_CURRENT_MONTH_BALANCES;

-- Status breakdown
SELECT 
    ACCOUNT_STATUS,
    COUNT(*) AS account_count,
    AVG(CREDIT_UTILIZATION_PCT) AS avg_utilization,
    AVG(NET_BALANCE) AS avg_balance
FROM VW_CURRENT_MONTH_BALANCES
GROUP BY ACCOUNT_STATUS
ORDER BY 
    CASE ACCOUNT_STATUS
        WHEN 'OVERDRAWN' THEN 1
        WHEN 'HIGH_UTILIZATION' THEN 2
        WHEN 'MODERATE_UTILIZATION' THEN 3
        ELSE 4
    END;

-- Account type comparison
SELECT 
    ACCOUNT_TYPE,
    COUNT(*) AS accounts,
    AVG(TOTAL_CREDITS) AS avg_credits,
    AVG(TOTAL_DEBITS) AS avg_debits,
    AVG(CREDIT_UTILIZATION_PCT) AS avg_utilization
FROM VW_CURRENT_MONTH_BALANCES
GROUP BY ACCOUNT_TYPE;

-- ============================================================================
-- Alert Queries - Accounts Needing Attention
-- ============================================================================

-- Overdrawn accounts (CRITICAL)
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    TOTAL_CREDITS,
    TOTAL_DEBITS,
    NET_BALANCE,
    CREDIT_UTILIZATION_PCT
FROM VW_CURRENT_MONTH_BALANCES
WHERE ACCOUNT_STATUS = 'OVERDRAWN'
ORDER BY NET_BALANCE;

-- High utilization accounts (WARNING)
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    AVAILABLE_CREDIT - TOTAL_DEBITS AS remaining_credit,
    CREDIT_UTILIZATION_PCT,
    TOTAL_CREDITS,
    DIRECT_DEPOSIT_AMOUNT
FROM VW_CURRENT_MONTH_BALANCES
WHERE CREDIT_UTILIZATION_PCT > 85
ORDER BY CREDIT_UTILIZATION_PCT DESC;

-- Accounts approaching zero balance
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    AVAILABLE_CREDIT - TOTAL_DEBITS AS remaining_credit,
    CREDIT_UTILIZATION_PCT
FROM VW_CURRENT_MONTH_BALANCES
WHERE AVAILABLE_CREDIT - TOTAL_DEBITS < 100
ORDER BY remaining_credit;

-- ============================================================================
-- Historical Analysis
-- ============================================================================

-- Monthly trend for all accounts
SELECT 
    CONCAT(PERIOD_YEAR, '-', LPAD(PERIOD_MONTH::VARCHAR, 2, '0')) AS period,
    COUNT(DISTINCT ACCOUNTID) AS active_accounts,
    SUM(TOTAL_CREDITS) AS total_credits,
    SUM(TOTAL_DEBITS) AS total_debits,
    AVG(CREDIT_UTILIZATION_PCT) AS avg_utilization,
    SUM(TRANSACTION_COUNT) AS total_transactions
FROM ACCOUNT_BALANCE_TRACKER
WHERE PERIOD_YEAR = YEAR(CURRENT_DATE())
GROUP BY PERIOD_YEAR, PERIOD_MONTH
ORDER BY PERIOD_YEAR, PERIOD_MONTH;

-- Account performance over time
SELECT 
    ACCOUNTID,
    PERIOD_MONTH,
    TOTAL_CREDITS,
    TOTAL_DEBITS,
    CREDIT_UTILIZATION_PCT,
    TRANSACTION_COUNT
FROM ACCOUNT_BALANCE_TRACKER
WHERE ACCOUNTID = 'YOUR-ACCOUNT-ID'
  AND PERIOD_YEAR = YEAR(CURRENT_DATE())
ORDER BY PERIOD_MONTH;

-- Growth analysis
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    SUM(TOTAL_CREDITS) AS ytd_credits,
    SUM(TOTAL_DEBITS) AS ytd_debits,
    AVG(CREDIT_UTILIZATION_PCT) AS avg_utilization,
    COUNT(DISTINCT CONCAT(PERIOD_YEAR, PERIOD_MONTH)) AS active_months
FROM ACCOUNT_BALANCE_TRACKER
JOIN ACCOUNT_CREDIT_CONFIG USING (ACCOUNTID)
WHERE PERIOD_YEAR = YEAR(CURRENT_DATE())
GROUP BY ACCOUNTID, ACCOUNT_TYPE
ORDER BY ytd_credits DESC;

-- ============================================================================
-- Credit Configuration Analysis
-- ============================================================================

-- Credit amounts by account type
SELECT 
    ACCOUNT_TYPE,
    COUNT(*) AS accounts,
    AVG(DIRECT_DEPOSIT_AMOUNT) AS avg_dd_amount,
    MIN(DIRECT_DEPOSIT_AMOUNT) AS min_dd_amount,
    MAX(DIRECT_DEPOSIT_AMOUNT) AS max_dd_amount,
    AVG(BONUS_AMOUNT) AS avg_bonus_amount,
    SUM(DIRECT_DEPOSIT_AMOUNT * 2) AS monthly_dd_total,
    SUM(BONUS_AMOUNT) AS quarterly_bonus_total
FROM ACCOUNT_CREDIT_CONFIG
WHERE ACTIVE = TRUE
GROUP BY ACCOUNT_TYPE;

-- Accounts with non-standard configurations
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    DIRECT_DEPOSIT_AMOUNT,
    BONUS_AMOUNT,
    DD_DAY_1,
    DD_DAY_2,
    NOTES
FROM ACCOUNT_CREDIT_CONFIG
WHERE (DD_DAY_1 != 1 OR DD_DAY_2 != 15)
   OR (ACCOUNT_TYPE = 'Personal' AND DIRECT_DEPOSIT_AMOUNT != 3000)
   OR (ACCOUNT_TYPE = 'Business' AND DIRECT_DEPOSIT_AMOUNT != 7500)
ORDER BY ACCOUNT_TYPE, ACCOUNTID;

-- ============================================================================
-- Transaction Analysis
-- ============================================================================

-- Today's transactions summary
SELECT 
    TRANSACTION_TYPE,
    COUNT(*) AS txn_count,
    SUM(AMOUNT) AS total_amount,
    AVG(AMOUNT) AS avg_amount,
    MIN(AMOUNT) AS min_amount,
    MAX(AMOUNT) AS max_amount
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= CURRENT_DATE()
GROUP BY TRANSACTION_TYPE;

-- Top spending categories today
SELECT 
    TRANSACTION_CATEGORY,
    COUNT(*) AS txn_count,
    SUM(AMOUNT) AS total_spent
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= CURRENT_DATE()
  AND TRANSACTION_TYPE = 'Debit'
GROUP BY TRANSACTION_CATEGORY
ORDER BY total_spent DESC
LIMIT 10;

-- Transaction volume by account
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    COUNT(*) AS txn_count,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Credit' THEN AMOUNT ELSE 0 END) AS credits,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Debit' THEN AMOUNT ELSE 0 END) AS debits
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= CURRENT_DATE()
GROUP BY ACCOUNTID, ACCOUNT_TYPE
ORDER BY txn_count DESC;

-- ============================================================================
-- Weekly Reports
-- ============================================================================

-- Last 7 days activity
SELECT 
    DATE(DATA_DATE) AS txn_date,
    COUNT(*) AS txn_count,
    COUNT(DISTINCT ACCOUNTID) AS active_accounts,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Credit' THEN AMOUNT ELSE 0 END) AS daily_credits,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Debit' THEN AMOUNT ELSE 0 END) AS daily_debits
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= DATEADD(day, -7, CURRENT_DATE())
GROUP BY DATE(DATA_DATE)
ORDER BY txn_date DESC;

-- ============================================================================
-- Health Check Query (Run Daily)
-- ============================================================================

SELECT 
    '1. Overdrawn Accounts' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM VW_CURRENT_MONTH_BALANCES
WHERE ACCOUNT_STATUS = 'OVERDRAWN'

UNION ALL

SELECT 
    '2. High Utilization (>90%)' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) < 5 THEN '✓ PASS' ELSE '⚠ WARNING' END AS status
FROM VW_CURRENT_MONTH_BALANCES
WHERE CREDIT_UTILIZATION_PCT > 90

UNION ALL

SELECT 
    '3. Inactive Accounts' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) = 0 THEN '✓ PASS' ELSE 'ℹ INFO' END AS status
FROM ACCOUNT_CREDIT_CONFIG
WHERE ACTIVE = FALSE

UNION ALL

SELECT 
    '4. Today Transaction Count' AS check_name,
    COUNT(*) AS count,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= CURRENT_DATE()

ORDER BY check_name;

-- ============================================================================
-- Export Queries for External Reporting
-- ============================================================================

-- Current month summary for all accounts (CSV export ready)
SELECT 
    b.ACCOUNTID,
    c.ACCOUNT_TYPE,
    c.DIRECT_DEPOSIT_AMOUNT,
    c.BONUS_AMOUNT,
    b.TOTAL_CREDITS,
    b.TOTAL_DEBITS,
    b.NET_BALANCE,
    b.AVAILABLE_CREDIT,
    b.CREDIT_UTILIZATION_PCT,
    b.TRANSACTION_COUNT,
    CASE 
        WHEN b.NET_BALANCE < 0 THEN 'OVERDRAWN'
        WHEN b.CREDIT_UTILIZATION_PCT > 90 THEN 'HIGH_UTILIZATION'
        WHEN b.CREDIT_UTILIZATION_PCT > 70 THEN 'MODERATE_UTILIZATION'
        ELSE 'GOOD_STANDING'
    END AS STATUS
FROM ACCOUNT_BALANCE_TRACKER b
JOIN ACCOUNT_CREDIT_CONFIG c ON b.ACCOUNTID = c.ACCOUNTID
WHERE b.PERIOD_YEAR = YEAR(CURRENT_DATE())
  AND b.PERIOD_MONTH = MONTH(CURRENT_DATE())
  AND c.ACTIVE = TRUE
ORDER BY b.ACCOUNTID;
