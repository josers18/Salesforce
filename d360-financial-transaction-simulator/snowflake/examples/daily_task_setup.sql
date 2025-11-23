-- ============================================================================
-- Example: Daily Task Setup for Automated Transaction Generation
-- ============================================================================

-- USE DATABASE FINS;
-- USE SCHEMA PUBLIC;

-- ============================================================================
-- Task 1: Daily Transaction Generation
-- Runs at 2 AM daily, generates 15 transactions per account
-- ============================================================================

CREATE OR REPLACE TASK generate_daily_transactions_task
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 2 * * * America/New_York'
  COMMENT = 'Generate 15 transactions per account daily at 2 AM EST'
AS
  CALL generate_daily_transactions(15);

-- Enable the task
ALTER TASK generate_daily_transactions_task RESUME;

-- ============================================================================
-- Task 2: Weekly Balance Report
-- Runs every Monday at 9 AM
-- ============================================================================

CREATE OR REPLACE TASK weekly_balance_report_task
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 9 * * 1 America/New_York'
  COMMENT = 'Generate weekly balance report every Monday at 9 AM EST'
AS
  INSERT INTO BALANCE_REPORTS (
    REPORT_DATE,
    ACCOUNT_COUNT,
    TOTAL_CREDITS,
    TOTAL_DEBITS,
    AVG_UTILIZATION,
    HIGH_UTIL_ACCOUNTS,
    OVERDRAWN_ACCOUNTS
  )
  SELECT 
    CURRENT_DATE() AS REPORT_DATE,
    COUNT(*) AS ACCOUNT_COUNT,
    SUM(TOTAL_CREDITS) AS TOTAL_CREDITS,
    SUM(TOTAL_DEBITS) AS TOTAL_DEBITS,
    AVG(CREDIT_UTILIZATION_PCT) AS AVG_UTILIZATION,
    SUM(CASE WHEN CREDIT_UTILIZATION_PCT > 85 THEN 1 ELSE 0 END) AS HIGH_UTIL_ACCOUNTS,
    SUM(CASE WHEN NET_BALANCE < 0 THEN 1 ELSE 0 END) AS OVERDRAWN_ACCOUNTS
  FROM VW_CURRENT_MONTH_BALANCES;

-- Enable the task
ALTER TASK weekly_balance_report_task RESUME;

-- ============================================================================
-- Task 3: Monthly Credit Adjustment
-- Runs on 1st of each month at 1 AM (before daily generation)
-- ============================================================================

CREATE OR REPLACE TASK monthly_credit_adjustment_task
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 1 1 * * America/New_York'
  COMMENT = 'Adjust credits for high-utilization accounts on 1st of month'
AS
  -- Increase credits by 10% for accounts consistently above 85% utilization
  UPDATE ACCOUNT_CREDIT_CONFIG
  SET 
    DIRECT_DEPOSIT_AMOUNT = DIRECT_DEPOSIT_AMOUNT * 1.10,
    LAST_UPDATED = CURRENT_TIMESTAMP()
  WHERE ACCOUNTID IN (
    SELECT ACCOUNTID
    FROM (
      SELECT 
        ACCOUNTID,
        AVG(CREDIT_UTILIZATION_PCT) AS avg_util
      FROM ACCOUNT_BALANCE_TRACKER
      WHERE PERIOD_YEAR = YEAR(DATEADD(month, -1, CURRENT_DATE()))
        AND PERIOD_MONTH = MONTH(DATEADD(month, -1, CURRENT_DATE()))
      GROUP BY ACCOUNTID
      HAVING AVG(CREDIT_UTILIZATION_PCT) > 85
    )
  );

-- Enable the task
ALTER TASK monthly_credit_adjustment_task RESUME;

-- ============================================================================
-- Verify Tasks
-- ============================================================================

-- Show all tasks
SHOW TASKS LIKE '%transaction%';

-- Check task status
SELECT 
    NAME,
    STATE,
    SCHEDULE,
    WAREHOUSE,
    COMMENT
FROM TABLE(INFORMATION_SCHEMA.TASKS())
WHERE NAME LIKE '%transaction%'
ORDER BY NAME;

-- ============================================================================
-- Task History (Check Execution)
-- ============================================================================

-- Last 10 executions of daily task
SELECT 
    NAME,
    STATE,
    SCHEDULED_TIME,
    COMPLETED_TIME,
    RETURN_VALUE,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE NAME = 'GENERATE_DAILY_TRANSACTIONS_TASK'
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;

-- ============================================================================
-- Task Management Commands
-- ============================================================================

-- Suspend a task
-- ALTER TASK generate_daily_transactions_task SUSPEND;

-- Resume a task
-- ALTER TASK generate_daily_transactions_task RESUME;

-- Drop a task
-- DROP TASK IF EXISTS generate_daily_transactions_task;

-- Modify task schedule
-- ALTER TASK generate_daily_transactions_task
-- SET SCHEDULE = 'USING CRON 0 3 * * * America/New_York';  -- Change to 3 AM

-- ============================================================================
-- Monitoring Dashboard Query
-- ============================================================================

-- Daily summary of task executions
SELECT 
    DATE(SCHEDULED_TIME) AS execution_date,
    NAME,
    COUNT(*) AS executions,
    SUM(CASE WHEN STATE = 'SUCCEEDED' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN STATE = 'FAILED' THEN 1 ELSE 0 END) AS failed,
    AVG(TIMESTAMPDIFF(second, SCHEDULED_TIME, COMPLETED_TIME)) AS avg_duration_sec
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('day', -7, CURRENT_TIMESTAMP())
))
WHERE NAME LIKE '%transaction%'
GROUP BY DATE(SCHEDULED_TIME), NAME
ORDER BY execution_date DESC, NAME;
