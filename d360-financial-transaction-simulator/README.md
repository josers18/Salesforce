# Financial Transaction Simulator

Generate realistic financial transactions with **Personal** and **Business** account patterns.

## Key Features

### 🏢 Account Types
- **Personal Accounts**: Consumer spending patterns with entertainment, dining, shopping
- **Business Accounts**: B2B transactions - NO entertainment, higher amounts (1.3x-2.5x), professional services focus

### 💰 Transaction Generation
- ✅ Unique UUIDs for each transaction
- ✅ Realistic amounts based on MCC categories and account type
- ✅ Random dates within specified range
- ✅ Automatic direct deposits (twice monthly: 1st & 15th)
- ✅ Monthly bonuses (last day of month)

### 📊 Data Quality
- ✅ 325+ MCC categories from real merchant codes
- ✅ Proper CSV formatting (handles commas, special characters)
- ✅ Complete transaction metadata (MCC, categories, types)
- ✅ Tested with 1000+ transactions

## Personal vs Business Accounts

| Feature | Personal | Business |
|---------|----------|----------|
| **Avg Transaction** | ~$400 | ~$900 (2.2x) |
| **Direct Deposits** | $3,000 | $7,500 (2.5x) |
| **Monthly Bonuses** | $500 | $1,000 (2x) |
| **Entertainment** | ✅ Included | ❌ Excluded |
| **Fast Food** | ✅ Included | ❌ Excluded |
| **Business Services** | Standard | Priority Focus |
| **Transaction Focus** | Consumer | B2B |

## Requirements

```bash
pip install pandas numpy
```

## Quick Start

### 1️⃣ Business Account (B2B Transactions)

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids BUSINESS_LLC \
    --account-types business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

**Output:** 500 business transactions with NO entertainment, higher amounts, B2B focus

### 2️⃣ Personal Account (Consumer Spending)

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids JOHN_PERSONAL \
    --account-types personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

**Output:** 500 consumer transactions with entertainment, dining, shopping

### 3️⃣ Mixed Accounts (Realistic Scenario)

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids PERSONAL_ALICE BUSINESS_ACME PERSONAL_BOB \
    --account-types personal business personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1000
```

**Output:** 1000 transactions across 3 accounts, each maintaining its own pattern

### Custom Direct Deposit and Bonus Amounts

```bash
python transaction_simulator.py \
    --account-ids ACC123456 \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500 \
    --direct-deposit-amount 5000.00 \
    --bonus-amount 1000.00
```

### Exclude Direct Deposits or Bonuses

```bash
# Exclude direct deposits
python transaction_simulator.py \
    --account-ids ACC123456 \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500 \
    --no-direct-deposits

# Exclude bonuses
python transaction_simulator.py \
    --account-ids ACC123456 \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500 \
    --no-bonuses
```

## Command Line Arguments

### Required Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `--account-ids` | One or more account IDs (space-separated) | `ACC001 ACC002` |
| `--start-date` | Start date for transactions | `2024-01-01` |
| `--end-date` | End date for transactions | `2024-12-31` |

### Account Type Configuration

| Argument | Default | Description |
|----------|---------|-------------|
| `--account-types` | `personal` | Account types: `personal` or `business`<br>Must match order of account-ids<br>If omitted, all accounts default to personal |

**Examples:**
```bash
# Single business account
--account-types business

# Multiple accounts with types
--account-ids ACC001 ACC002 ACC003 \
--account-types personal business personal

# Default (all personal if not specified)
--account-ids ACC001 ACC002
```

### Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--mcc-file` | `MCCs.csv` | Path to MCC CSV file |
| `--num-records` | `100` | Total number of transactions to generate |
| `--output-file` | `generated_transactions.csv` | Output CSV filename |
| `--direct-deposit-amount` | `3000.00` | Base amount for deposits (×2.5 for business) |
| `--bonus-amount` | `500.00` | Base amount for bonuses (×2 for business) |
| `--no-direct-deposits` | `False` | Exclude direct deposits |
| `--no-bonuses` | `False` | Exclude monthly bonuses |

## Output Format

### CSV Columns

| Column | Description |
|--------|-------------|
| **AccountID** | Account identifier |
| **Account_Type** | 🆕 **Personal** or **Business** |
| **TransactionID** | Unique UUID for each transaction |
| **PostingDate** | Date transaction was posted |
| **TransactionDate** | Date of the transaction (same as PostingDate) |
| **Amount** | Transaction amount in USD |
| **Description** | Merchant/transaction description |
| **Transaction_Category** | High-level category (Shopping, Business Services, etc.) |
| **MCC** | Merchant Category Code |
| **MCC_Description** | MCC description |
| **Transaction_status** | Always "Posted" |
| **Currency** | Always "USD" |
| **Transaction_Type** | Debit or Credit |
| **Source_Transaction_Type** | Original transaction type |
| **Data_Date** | Date the data was generated |

### Sample Output

```csv
AccountID,Account_Type,TransactionID,PostingDate,TransactionDate,Amount,Description,Transaction_Category,MCC,MCC_Description,Transaction_status,Currency,Transaction_Type,Source_Transaction_Type,Data_Date
PERSONAL001,Personal,d4c2952c-...,2024-01-01,2024-01-01,3000.0,Direct Deposit,Paycheck,9961,Direct Deposit,Posted,USD,Credit,Credit,2025-11-14
BUSINESS001,Business,f4d290f2-...,2024-01-01,2024-01-01,7500.0,Business Revenue Deposit,Paycheck,9961,Direct Deposit,Posted,USD,Credit,Credit,2025-11-14
PERSONAL001,Personal,3d9a6b7c-...,2024-01-05,2024-01-05,14.05,Sports Events,Entertainment,7941,Sports Events,Posted,USD,Debit,Debit,2025-11-14
BUSINESS001,Business,5d8430d5-...,2024-01-05,2024-01-05,423.92,Membership Organizations,Business Services,8699,Membership Organizations,Posted,USD,Debit,Debit,2025-11-14
```

**Notice:** 
- Personal account has entertainment spending ($14.05 for sports)
- Business account has NO entertainment
- Business amounts are higher ($423.92 vs typical personal)
- Different deposit descriptions and amounts

## Business Account Features

### Transaction Filtering
Business accounts **automatically exclude**:
- ❌ Entertainment (movies, casinos, sports events, gambling)
- ❌ Fast food restaurants
- ❌ Personal leisure activities

Business accounts **prioritize**:
- ✅ Business services (professional services, contractors)
- ✅ Office supplies and equipment
- ✅ Business travel (hotels, airlines, car rentals)
- ✅ Utilities and telecommunications
- ✅ Repair and maintenance services

### Amount Multipliers

Business transactions are scaled based on category:

| Category | Multiplier | Example |
|----------|------------|---------|
| **Business Services** | 2.5× | Personal $30-400 → Business $75-1,000 |
| **Professional Services** | 2.5× | Personal $50-500 → Business $125-1,250 |
| **Hotels/Airlines** | 1.8× | Personal $80-500 → Business $144-900 |
| **Utilities** | 1.8× | Personal $50-300 → Business $90-540 |
| **Repairs** | 1.5× | Personal $40-300 → Business $60-450 |
| **Other Categories** | 1.3× | Base increase |

### Automatic Revenue Adjustments

| Type | Personal | Business |
|------|----------|----------|
| **Direct Deposits** | $3,000 (default) | $7,500 (2.5×) |
| **Description** | "Direct Deposit" | "Business Revenue Deposit" |
| **Monthly Bonuses** | $500 (default) | $1,000 (2×) |
| **Frequency** | Same: 2× deposits, 1× bonus per month | Same |

## Special Transaction Types

### Direct Deposits
- **MCC**: 9961
- **Frequency**: Twice per month (1st and 15th)
- **Amount**: 
  - Personal: Fixed (default $3,000)
  - Business: 2.5× personal (default $7,500)
- **Type**: Credit

### Monthly Bonuses
- **MCC**: 9963 (ACH Deposit)
- **Frequency**: Once per month (last day)
- **Amount**: 
  - Personal: Fixed (default $500)
  - Business: 2× personal (default $1,000)
- **Type**: Credit

## Using as a Python Module

```python
from transaction_simulator import TransactionSimulator

# Initialize simulator
simulator = TransactionSimulator('MCCs.csv')

# Example 1: Business account
df_business = simulator.generate_transactions(
    account_ids='BUSINESS_LLC',
    account_types='business',
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=500
)
df_business.to_csv('business_transactions.csv', index=False)

# Example 2: Mixed personal and business
df_mixed = simulator.generate_transactions(
    account_ids=['PERSONAL_ALICE', 'BUSINESS_BOB'],
    account_types=['personal', 'business'],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=1000
)

# Example 3: Using dictionary for account types
df = simulator.generate_transactions(
    account_ids=['ACC001', 'ACC002', 'ACC003'],
    account_types={
        'ACC001': 'personal',
        'ACC002': 'business',
        'ACC003': 'personal'
    },
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=750
)

# Analyze patterns
print(f"Business avg: ${df[df['Account_Type']=='Business']['Amount'].mean():.2f}")
print(f"Personal avg: ${df[df['Account_Type']=='Personal']['Amount'].mean():.2f}")

# Check entertainment exclusion
business_entertainment = df[
    (df['Account_Type']=='Business') & 
    (df['Transaction_Category']=='Entertainment')
]
print(f"Business entertainment transactions: {len(business_entertainment)} (should be 0)")
```

## Transaction Amount Ranges by Category

The simulator generates realistic amounts based on MCC categories:

| Category | Amount Range |
|----------|--------------|
| Fast Food | $5 - $30 |
| Restaurants | $15 - $150 |
| Gas Stations | $20 - $100 |
| Hotels | $80 - $500 |
| Airlines | $150 - $1,500 |
| Retail Outlets | $10 - $500 |
| Utilities | $50 - $300 |
| Direct Deposits | $2,000 - $5,000 |
| (and many more...) |

## CSV Format Integrity

✅ **Properly Formatted Output**: The script generates CSV files with proper quoting for fields containing special characters (commas, quotes, etc.)

✅ **No Misalignment**: All fields are correctly quoted and escaped, preventing CSV parsing errors

✅ **Verified**: Tested with 127+ entries containing commas in descriptions - all properly formatted

### Verify Your CSV

Use the included verification script to check your generated CSV:

```bash
python verify_csv.py generated_transactions.csv
```

This will:
- Check for proper column structure
- Verify no misalignment in rows
- Report entries with special characters
- Confirm CSV integrity

**Example Output:**
```
✅ CSV FORMAT VERIFICATION PASSED
   No misalignment detected - File is properly formatted!
```

## Real-World Use Cases

### Small Business (Startup)
```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids STARTUP_LLC \
    --account-types business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 400 \
    --direct-deposit-amount 5000 \
    --bonus-amount 1000
```
**Result:** $12,500 monthly revenue, 400 B2B transactions, no entertainment

### Established Business
```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids CORP_MAIN \
    --account-types business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1200 \
    --direct-deposit-amount 20000 \
    --bonus-amount 5000
```
**Result:** $50,000 monthly revenue, high transaction volume, enterprise spending

### Freelancer (Personal Account)
```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids FREELANCER_JOHN \
    --account-types personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500 \
    --direct-deposit-amount 4500
```
**Result:** $4,500 monthly income, mixed consumer spending with entertainment

### Multi-Account Household
```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ALICE_PERSONAL BOB_BUSINESS JOINT_PERSONAL \
    --account-types personal business personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1500
```
**Result:** Realistic household with personal and business accounts

## Tips

1. **Account Types**: Business accounts automatically get 2.5× higher deposits and 2× bonuses
2. **Entertainment Exclusion**: Business accounts have ZERO entertainment transactions
3. **More Records = More Realistic**: Generate at least 100 transactions per month
4. **Date Ranges**: Deposits appear on 1st & 15th, bonuses on last day of month
5. **Default Behavior**: If --account-types is omitted, all accounts default to personal

## License

This script is provided as-is for simulation and testing purposes.
