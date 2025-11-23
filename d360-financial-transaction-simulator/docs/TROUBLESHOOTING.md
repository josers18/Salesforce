# 🔧 Troubleshooting: No Transactions Generated

## Issue
When calling `CALL generate_daily_transactions(10);` the procedure returns but generates 0 transactions.

---

## Quick Diagnosis (Run These Queries)

### 1️⃣ Run the Troubleshooting Script
```sql
-- This will check all common issues
@troubleshoot_no_transactions.sql
```

This script checks:
- ✅ Is ACCOUNT_CREDIT_CONFIG populated?
- ✅ Are there active accounts?
- ✅ Are accounts in BOTH tables?
- ✅ Does MCC table have data?
- ✅ Does MCC table have debit transactions?
- ✅ What day is today (affects credit generation)?

---

## Common Issues & Solutions

### Issue #1: ACCOUNT_CREDIT_CONFIG Table is Empty ⚠️

**Symptom**: Query shows 0 records in ACCOUNT_CREDIT_CONFIG

**Solution**: Run the population script
```sql
@02_populate_credit_config.sql
```

Or manually populate:
```sql
INSERT INTO FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG (
    ACCOUNTID, SFACCOUNTID, CONTACTID, ACCOUNT_TYPE,
    DIRECT_DEPOSIT_AMOUNT, BONUS_AMOUNT, DD_DAY_1, DD_DAY_2,
    BONUS_FREQUENCY, ACTIVE, NOTES
)
SELECT 
    ACCOUNTID, SFACCOUNTID, CONTACTID, ACCOUNTTYPE,
    CASE WHEN ACCOUNTTYPE = 'Business' THEN 7500.00 ELSE 3000.00 END,
    CASE WHEN ACCOUNTTYPE = 'Business' THEN 1000.00 ELSE 500.00 END,
    1, 15, 'QUARTERLY', ACTIVE,
    'Auto-populated from master accounts'
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
WHERE ACTIVE = TRUE;
```

**Verify**:
```sql
SELECT * FROM FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG;
```

---

### Issue #2: Accounts Not Active ⚠️

**Symptom**: Accounts exist but ACTIVE = FALSE

**Solution**: Activate the accounts
```sql
-- Activate in master table
UPDATE FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS
SET ACTIVE = TRUE;

-- Activate in config table
UPDATE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG
SET ACTIVE = TRUE;
```

**Verify**:
```sql
SELECT COUNT(*) 
FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS a
JOIN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c ON a.ACCOUNTID = c.ACCOUNTID
WHERE a.ACTIVE = TRUE AND c.ACTIVE = TRUE;
```

---

### Issue #3: MCC Table Has No Debit Transactions ⚠️

**Symptom**: Query shows 0 debit transactions in MCC table

**Check**:
```sql
SELECT TRAN_TYPE, COUNT(*)
FROM FINS.PUBLIC.MCC
GROUP BY TRAN_TYPE;
```

**Possible Causes**:
1. **Wrong column name** - Check the actual column:
   ```sql
   SELECT COLUMN_NAME
   FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_NAME = 'MCC'
   AND COLUMN_NAME LIKE '%TYPE%';
   ```

2. **Case sensitivity** - Try different cases:
   ```sql
   -- Try these variations
   SELECT COUNT(*) FROM MCC WHERE TRAN_TYPE = 'Debit';
   SELECT COUNT(*) FROM MCC WHERE "Tran_Type" = 'Debit';
   SELECT COUNT(*) FROM MCC WHERE tran_type = 'Debit';
   ```

3. **Different value** - Check what values exist:
   ```sql
   SELECT DISTINCT TRAN_TYPE FROM MCC;
   ```

---

### Issue #4: Schema/Database Not Set ⚠️

**Symptom**: Error about table not found

**Solution**: Set the schema
```sql
USE DATABASE FINS;
USE SCHEMA PUBLIC;

-- Then try again
CALL generate_daily_transactions(10);
```

---

### Issue #5: Column Name Mismatches ⚠️

**Symptom**: Error about column not found

**Check Actual Column Names**:
```sql
-- MCC table columns
DESCRIBE TABLE FINS.PUBLIC.MCC;

-- Accounts table columns
DESCRIBE TABLE FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS;

-- Config table columns
DESCRIBE TABLE FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG;
```

---

## Debug Mode (Detailed Diagnostics)

Deploy and run the debug version of the stored procedure:

```sql
-- Deploy debug version
@04_stored_procedure_debug_version.sql

-- Run it
CALL generate_daily_transactions_debug(5);
```

**The debug version will tell you**:
- ✅ How many accounts were found
- ✅ Which account IDs were loaded
- ✅ How many MCC records exist
- ✅ How many debit MCCs found
- ✅ Whether today is a credit day
- ✅ How many transactions generated at each step
- ✅ Any errors with full details

**Example Output**:
```
Step 1: Loading accounts...; Found 10 active accounts with credit config; 
Account IDs: ACC-001, ACC-002, ACC-003, ACC-004, ACC-005...; 
Step 2: Loading MCC data...; Found 450 MCC records; Found 380 debit MCCs; 
Found 1 direct deposit MCCs (9961); Found 1 bonus MCCs (9963); 
Today is 2024-11-22 (Day 22 of month); Is Direct Deposit Day: False; 
Is Quarterly Bonus Day: False; Generating up to 5 debit transactions per account...; 
Generated 50 debit transactions; Created DataFrame with 50 total transactions; 
Writing to FINANCIAL_TRANSACTIONS table...; SUCCESS! Wrote 50 transactions to database
```

---

## Step-by-Step Resolution

### Step 1: Check Prerequisites
```sql
-- Run all checks
@troubleshoot_no_transactions.sql
```

### Step 2: Fix Missing Data
```sql
-- If ACCOUNT_CREDIT_CONFIG is empty
@02_populate_credit_config.sql

-- Verify
SELECT COUNT(*) FROM ACCOUNT_CREDIT_CONFIG;
```

### Step 3: Test with Debug Version
```sql
-- Deploy debug version
@04_stored_procedure_debug_version.sql

-- Run with small number
CALL generate_daily_transactions_debug(2);

-- Read the output carefully
```

### Step 4: Fix Issues Identified

Based on the debug output, apply appropriate fixes from the solutions above.

### Step 5: Test Production Version
```sql
-- Once debug version works, try production version
CALL generate_daily_transactions(10);

-- Check results
SELECT COUNT(*) FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= CURRENT_DATE();
```

---

## Quick Validation Queries

### Check if tables exist:
```sql
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'PUBLIC'
AND TABLE_NAME IN (
    'ACCOUNT_CREDIT_CONFIG',
    'ACCOUNT_BALANCE_TRACKER',
    'FINANCIAL_TRANSACTION_ACCOUNTS',
    'MCC',
    'FINANCIAL_TRANSACTIONS'
);
```

### Check procedure exists:
```sql
SHOW PROCEDURES LIKE 'generate_daily_transactions';
```

### Check recent transactions:
```sql
SELECT 
    DATA_DATE,
    COUNT(*) AS txn_count,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Credit' THEN AMOUNT ELSE 0 END) AS credits,
    SUM(CASE WHEN TRANSACTION_TYPE = 'Debit' THEN AMOUNT ELSE 0 END) AS debits
FROM FINANCIAL_TRANSACTIONS
WHERE DATA_DATE >= DATEADD(day, -7, CURRENT_DATE())
GROUP BY DATA_DATE
ORDER BY DATA_DATE DESC;
```

---

## Understanding Credit Generation Schedule

The stored procedure only generates credits on specific days:

### Direct Deposits
- **1st of month**: Generates DD for all accounts
- **15th of month**: Generates DD for all accounts
- **Other days**: No DDs generated

### Bonuses
- **January 1**: Q1 bonus
- **April 1**: Q2 bonus
- **July 1**: Q3 bonus
- **October 1**: Q4 bonus
- **Other days**: No bonuses

### Debit Transactions
- **Every day**: Generates debit transactions (up to the specified count per account)

**Example**:
```
Today is November 22
- Is DD Day? NO
- Is Bonus Day? NO
- Will generate: Debits only (no credits today)

If you call generate_daily_transactions(10):
- 0 direct deposits
- 0 bonuses  
- Up to 10 debits per account
```

---

## Still Not Working?

### Manual Test Transaction

Try inserting a transaction manually to verify table structure:

```sql
INSERT INTO FINS.PUBLIC.FINANCIAL_TRANSACTIONS (
    ACCOUNTID, TRANSACTIONID, POSTINGDATE, TRANSACTIONDATE,
    AMOUNT, DESCRIPTION, TRANSACTION_CATEGORY, MCC,
    MCC_DESCRIPTION, TRANSACTION_STATUS, CURRENCY,
    TRANSACTION_TYPE, SOURCE_TRANSACTION_TYPE, DATA_DATE,
    SFACCOUNTID, CONTACTID, ACCOUNT_TYPE
)
VALUES (
    'TEST-001', UUID_STRING(), CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(),
    100.00, 'Manual Test Transaction', 'Shopping', 5411,
    'Grocery Store', 'Posted', 'USD',
    'Debit', 'Debit', CURRENT_TIMESTAMP(),
    'SF-TEST-001', 'CON-TEST-001', 'Personal'
);

-- If this works, the table structure is fine
-- If this fails, there's a table structure issue
```

---

## Contact Support

If none of these solutions work, gather this information:

1. **Output from troubleshoot script**:
   ```sql
   @troubleshoot_no_transactions.sql
   ```

2. **Output from debug procedure**:
   ```sql
   CALL generate_daily_transactions_debug(2);
   ```

3. **Table structures**:
   ```sql
   DESCRIBE TABLE ACCOUNT_CREDIT_CONFIG;
   DESCRIBE TABLE FINANCIAL_TRANSACTION_ACCOUNTS;
   DESCRIBE TABLE MCC;
   DESCRIBE TABLE FINANCIAL_TRANSACTIONS;
   ```

4. **Sample data**:
   ```sql
   SELECT * FROM ACCOUNT_CREDIT_CONFIG LIMIT 3;
   SELECT * FROM MCC WHERE TRAN_TYPE = 'Debit' LIMIT 3;
   ```

---

## Files Included

| File | Purpose |
|------|---------|
| `troubleshoot_no_transactions.sql` | Diagnostic queries |
| `quick_fix_no_transactions.sql` | Common fixes |
| `04_stored_procedure_debug_version.sql` | Debug version with verbose output |
| `TROUBLESHOOTING.md` | This guide |

---

**Most Common Issue**: ACCOUNT_CREDIT_CONFIG table is empty  
**Most Common Fix**: Run `@02_populate_credit_config.sql`
