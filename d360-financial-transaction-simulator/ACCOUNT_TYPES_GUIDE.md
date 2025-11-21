# Account Type Feature Guide

## Overview

The transaction simulator now supports **Personal** and **Business** account types with distinct transaction patterns.

## Key Differences

### Personal Accounts
- ✅ All MCC categories available (retail, entertainment, dining, etc.)
- ✅ Standard transaction amounts
- ✅ Direct deposits labeled as "Direct Deposit"
- ✅ Standard deposit amounts (default: $3,000)
- ✅ Standard bonuses (default: $500)
- ✅ Includes entertainment, dining, and leisure activities

### Business Accounts
- ✅ Filtered to business-appropriate MCCs
- ✅ **NO entertainment** transactions (casinos, movies, etc.)
- ✅ Focus on B2B services (contractors, professional services, office supplies)
- ✅ Higher transaction amounts (1.3x - 2.5x multiplier)
- ✅ Direct deposits labeled as "Business Revenue Deposit"
- ✅ Higher deposit amounts (2.5x personal, default: $7,500)
- ✅ Higher bonuses (2x personal, default: $1,000)
- ✅ More utilities, transportation, and business services

## Transaction Amount Multipliers for Business

| Category | Multiplier | Example |
|----------|------------|---------|
| Business Services | 2.5x | Personal: $30-400 → Business: $75-1000 |
| Professional Services | 2.5x | Personal: $50-500 → Business: $125-1250 |
| Contracted Services | 2.5x | Personal: $100-1000 → Business: $250-2500 |
| Hotels/Airlines | 1.8x | Personal: $80-500 → Business: $144-900 |
| Utilities | 1.8x | Personal: $50-300 → Business: $90-540 |
| Repair Services | 1.5x | Personal: $40-300 → Business: $60-450 |
| Other Categories | 1.3x | Baseline increase |

## Business Account Transaction Focus

Business accounts prioritize:
1. **Business Services** (70% of transactions)
   - Office supplies and equipment
   - Professional services
   - Contracted services (contractors, repairs)
   - Business travel (hotels, airlines, car rentals)
   - Utilities and telecommunications

2. **Excluded Categories**
   - Entertainment (movies, casinos, sports events)
   - Fast food
   - Personal leisure activities

## Usage Examples

### Example 1: Single Business Account

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids BUSINESS001 \
    --account-types business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

**Output:**
- 500 business-appropriate transactions
- $7,500 revenue deposits twice monthly
- $1,000 monthly bonuses
- Higher average transaction amounts
- No entertainment expenses

### Example 2: Mixed Personal and Business Accounts

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids PERSONAL001 BUSINESS001 PERSONAL002 \
    --account-types personal business personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1000
```

**Output:**
- Transactions distributed across 3 accounts
- 2 personal accounts with standard patterns
- 1 business account with business patterns
- Each account type maintains its characteristics

### Example 3: Multiple Business Accounts

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids BIZ_LLC BIZ_CORP BIZ_INC \
    --account-types business business business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1500 \
    --direct-deposit-amount 10000 \
    --bonus-amount 2500
```

**Output:**
- 1500 business transactions across 3 accounts
- $25,000 revenue deposits per account twice monthly ($10,000 × 2.5)
- $5,000 monthly bonuses per account ($2,500 × 2)
- All business-appropriate spending

### Example 4: Default to Personal (No Type Specified)

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ACC001 ACC002 \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

**Output:**
- Both accounts default to personal type
- Standard personal transaction patterns

## Python Module Usage

```python
from transaction_simulator import TransactionSimulator

simulator = TransactionSimulator('MCCs.csv')

# Mixed account types
df = simulator.generate_transactions(
    account_ids=['PERSONAL001', 'BUSINESS001'],
    account_types=['personal', 'business'],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=500
)

# Or using a dictionary
df = simulator.generate_transactions(
    account_ids=['PERSONAL001', 'BUSINESS001', 'BUSINESS002'],
    account_types={
        'PERSONAL001': 'personal',
        'BUSINESS001': 'business',
        'BUSINESS002': 'business'
    },
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=750
)
```

## CSV Output Format

The output CSV now includes the `Account_Type` column:

```csv
AccountID,Account_Type,TransactionID,PostingDate,TransactionDate,Amount,Description,...
PERSONAL001,Personal,uuid-1234,2024-01-01,2024-01-01,3000.0,Direct Deposit,...
BUSINESS001,Business,uuid-5678,2024-01-01,2024-01-01,7500.0,Business Revenue Deposit,...
```

## Verification

Run the verification to see the breakdown:

```bash
python verify_csv.py generated_transactions.csv
```

The summary will show:
- Transaction counts by account type
- Average amounts by account type
- Category breakdown by account type

## Test Results

**Test Dataset:** 100 transactions (50% personal, 50% business)

| Metric | Personal | Business |
|--------|----------|----------|
| Avg Transaction | $620.11 | $1,139.06 |
| Revenue Deposits | $3,000 | $7,500 |
| Monthly Bonuses | $500 | $1,000 |
| Entertainment | ✅ Included | ❌ Excluded |
| Business Services | Lower frequency | Higher frequency |
| Transaction Multiplier | 1.0x | 1.3x - 2.5x |

## Tips for Realistic Business Data

1. **Higher Volumes**: Business accounts typically have more transactions
   ```bash
   --num-records 2000  # For business accounts
   ```

2. **Larger Amounts**: Use custom deposit amounts for established businesses
   ```bash
   --direct-deposit-amount 15000 --bonus-amount 5000
   ```

3. **Multiple Accounts**: Simulate departments or subsidiaries
   ```bash
   --account-ids BIZ_MAIN BIZ_DEPT1 BIZ_DEPT2 \
   --account-types business business business
   ```

4. **Longer Periods**: Generate full fiscal years
   ```bash
   --start-date 2024-01-01 --end-date 2024-12-31
   ```

## Common Patterns

### Startup Business
```bash
--account-types business \
--direct-deposit-amount 5000 \
--bonus-amount 500 \
--num-records 300
```

### Established Business
```bash
--account-types business \
--direct-deposit-amount 15000 \
--bonus-amount 3000 \
--num-records 1000
```

### Freelancer/Consultant (Personal)
```bash
--account-types personal \
--direct-deposit-amount 4000 \
--bonus-amount 1000 \
--num-records 400
```

---

**Summary:** Business accounts now have realistic B2B transaction patterns with appropriate categories, higher amounts, and no entertainment spending!
