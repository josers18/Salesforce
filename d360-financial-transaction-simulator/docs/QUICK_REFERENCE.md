# Quick Reference Card

## 🚀 Quick Start

### 1. Setup (One-Time)
```sql
-- Step 1: Create tables
@01_create_balance_tables.sql

-- Step 2: Populate configuration
@02_populate_credit_config.sql

-- Step 3: Deploy stored procedure
@03_stored_procedure_with_balance_tracking.sql
```

### 2. Daily Use
```sql
-- Generate transactions for today
CALL generate_daily_transactions(15);
```

---

## 📅 Credit Schedule Quick Reference

| Event | Frequency | When | Personal | Business |
|-------|-----------|------|----------|----------|
| **Direct Deposit** | Bi-Monthly | 1st & 15th | $3,000 | $7,500 |
| **Quarterly Bonus** | Quarterly | 1st of Q | $500 | $1,000 |

**Quarterly Bonus Dates**: Jan 1, Apr 1, Jul 1, Oct 1

---

## 💰 Annual Credit Totals

### Personal Account
- Direct Deposits: $3,000 × 2/month × 12 = **$72,000**
- Bonuses: $500 × 4 = **$2,000**
- **Total**: **$74,000/year**
- **Max Spending**: **$59,200** (80% limit)

### Business Account
- Direct Deposits: $7,500 × 2/month × 12 = **$180,000**
- Bonuses: $1,000 × 4 = **$4,000**
- **Total**: **$184,000/year**
- **Max Spending**: **$147,200** (80% limit)

---

## 🔍 Essential Queries

### Check Account Balance
```sql
SELECT * 
FROM VW_CURRENT_MONTH_BALANCES
WHERE ACCOUNTID = 'YOUR-ACCOUNT-ID';
```

### View All Account Statuses
```sql
SELECT 
    ACCOUNTID,
    ACCOUNT_TYPE,
    NET_BALANCE,
    CREDIT_UTILIZATION_PCT,
    ACCOUNT_STATUS
FROM VW_CURRENT_MONTH_BALANCES
ORDER BY CREDIT_UTILIZATION_PCT DESC;
```

### Update Credit Amount
```sql
UPDATE ACCOUNT_CREDIT_CONFIG
SET 
    DIRECT_DEPOSIT_AMOUNT = 5000.00,
    BONUS_AMOUNT = 1000.00
WHERE ACCOUNTID = 'YOUR-ACCOUNT-ID';
```

---

## 🐍 Python Script Examples

### Basic Usage
```bash
python transaction_simulator.py \
  --mcc-file MCCs.csv \
  --account-ids ACC-001 \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 500 \
  --output-file transactions.csv
```

### Multiple Accounts
```bash
python transaction_simulator.py \
  --mcc-file MCCs.csv \
  --account-ids ACC-001 ACC-002 ACC-003 \
  --account-types personal business personal \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 1000 \
  --output-file transactions.csv
```

### Custom Amounts
```bash
python transaction_simulator.py \
  --mcc-file MCCs.csv \
  --account-ids ACC-001 \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 500 \
  --direct-deposit-amount 5000 \
  --bonus-amount 1000 \
  --output-file transactions.csv
```

---

## ⚡ Stored Procedure Return Values

```sql
CALL generate_daily_transactions(10);
-- Returns:
"Successfully generated 45 transactions from 4 active accounts 
(25 personal, 20 business). 
Credits: $12,000.00, Debits: $9,450.00, Net: $2,550.00"
```

---

## 🎯 Monthly Credit Schedule Calendar

```
January              February             March
1: DD + Q1 Bonus    1: DD                1: DD
15: DD              15: DD               15: DD

April                May                  June
1: DD + Q2 Bonus    1: DD                1: DD
15: DD              15: DD               15: DD

July                 August               September
1: DD + Q3 Bonus    1: DD                1: DD
15: DD              15: DD               15: DD

October              November             December
1: DD + Q4 Bonus    1: DD                1: DD
15: DD              15: DD               15: DD

Legend: DD = Direct Deposit
```

---

## 🛠️ Common Tasks

### Add New Account
```sql
INSERT INTO ACCOUNT_CREDIT_CONFIG (
    ACCOUNTID, SFACCOUNTID, CONTACTID, ACCOUNT_TYPE,
    DIRECT_DEPOSIT_AMOUNT, BONUS_AMOUNT, ACTIVE
) VALUES (
    'NEW-001', 'SF-12345', 'CON-67890', 'Personal',
    3000.00, 500.00, TRUE
);
```

### Deactivate Account
```sql
UPDATE ACCOUNT_CREDIT_CONFIG
SET ACTIVE = FALSE
WHERE ACCOUNTID = 'OLD-001';
```

### Change Account Type
```sql
UPDATE ACCOUNT_CREDIT_CONFIG
SET 
    ACCOUNT_TYPE = 'Business',
    DIRECT_DEPOSIT_AMOUNT = 7500.00,
    BONUS_AMOUNT = 1000.00
WHERE ACCOUNTID = 'ACC-001';
```

---

## 📊 Account Status Indicators

| Status | Utilization | Balance | Action Needed |
|--------|-------------|---------|---------------|
| ✓ GOOD STANDING | < 70% | Positive | None |
| ℹ️ MODERATE | 70-90% | Positive | Monitor |
| ⚠️ HIGH UTILIZATION | > 90% | Positive | Increase credits |
| ⚠️ OVERDRAWN | Any | Negative | Urgent: Add credits |

---

## 🔄 Automation Setup

### Daily Task (Recommended)
```sql
CREATE TASK daily_transaction_generation
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 2 * * * America/New_York'
AS
  CALL generate_daily_transactions(15);

-- Enable the task
ALTER TASK daily_transaction_generation RESUME;
```

### Weekly Summary Report
```sql
CREATE TASK weekly_balance_report
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 9 * * 1 America/New_York'  -- Monday 9 AM
AS
  SELECT * FROM VW_ACCOUNT_SUMMARY;
```

---

## 📞 Emergency Commands

### Clear All Balances (Start Fresh)
```sql
TRUNCATE TABLE ACCOUNT_BALANCE_TRACKER;
TRUNCATE TABLE ACCOUNT_DAILY_BALANCE;
```

### Reset Month (Careful!)
```sql
DELETE FROM ACCOUNT_BALANCE_TRACKER
WHERE PERIOD_YEAR = 2024 AND PERIOD_MONTH = 11;
```

### Bulk Update All Personal Accounts
```sql
UPDATE ACCOUNT_CREDIT_CONFIG
SET DIRECT_DEPOSIT_AMOUNT = 4000.00
WHERE ACCOUNT_TYPE = 'Personal' AND ACTIVE = TRUE;
```

---

## 📁 File Reference

- `01_create_balance_tables.sql` - Table creation
- `02_populate_credit_config.sql` - Initial configuration
- `03_stored_procedure_with_balance_tracking.sql` - Stored procedure
- `transaction_simulator.py` - Python script
- `README.md` - Full documentation
- `QUICK_REFERENCE.md` - This file

---

**Version**: 2.0  
**Last Updated**: November 2024
