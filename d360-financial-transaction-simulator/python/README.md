# Python Transaction Simulator

Standalone Python script for generating realistic financial transactions in bulk.

## 🎯 Purpose

Use this script when you need to:
- Generate historical transaction data
- Create test datasets
- Produce transactions for specific date ranges
- Generate data outside of Snowflake

## 📋 Requirements

- Python 3.8+
- pandas
- numpy
- uuid (built-in)
- datetime (built-in)

## 🚀 Installation

```bash
# Install dependencies
pip install -r ../requirements.txt

# Or install manually
pip install pandas numpy
```

## 💻 Usage

### Basic Usage

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids ACC-001 \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 500 \
  --output-file output/transactions.csv
```

### Multiple Accounts

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids ACC-001 ACC-002 ACC-003 \
  --account-types personal business personal \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 1000 \
  --output-file output/transactions.csv
```

### Custom Credit Amounts

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids VIP-001 \
  --account-types personal \
  --direct-deposit-amount 5000 \
  --bonus-amount 1000 \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 500 \
  --output-file output/vip_transactions.csv
```

## 📝 Command-Line Arguments

### Required Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `--mcc-file` | Path to MCC CSV file | `../data/MCCs.csv` |
| `--account-ids` | Space-separated account IDs | `ACC-001 ACC-002` |
| `--start-date` | Start date (YYYY-MM-DD) | `2024-01-01` |
| `--end-date` | End date (YYYY-MM-DD) | `2024-12-31` |

### Optional Arguments

| Argument | Description | Default | Example |
|----------|-------------|---------|---------|
| `--account-types` | Account types (personal/business) | `personal` | `personal business` |
| `--sf-account-ids` | Salesforce Account IDs | Same as account-ids | `SF001 SF002` |
| `--contact-ids` | Salesforce Contact IDs | Empty string | `CON001 CON002` |
| `--num-records` | Total number of records | `100` | `1000` |
| `--output-file` | Output CSV filename | `generated_transactions.csv` | `output/txns.csv` |
| `--direct-deposit-amount` | Direct deposit amount | `3000.00` | `5000.00` |
| `--bonus-amount` | Quarterly bonus amount | `500.00` | `1000.00` |
| `--no-direct-deposits` | Exclude direct deposits | N/A | Flag only |
| `--no-bonuses` | Exclude bonuses | N/A | Flag only |

## 📅 Credit Schedule

### Direct Deposits (Bi-Monthly)
- Generated on **1st** and **15th** of every month
- Amount controlled by `--direct-deposit-amount`
- Business accounts receive 2.5× the amount

### Quarterly Bonuses
- Generated on **1st of Jan, Apr, Jul, Oct** (Q1, Q2, Q3, Q4)
- Amount controlled by `--bonus-amount`
- Business accounts receive 2× the amount

## 🔒 Overdraft Prevention

The script automatically:
1. Calculates total credits per account
2. Limits debits to **80% of total credits**
3. Adjusts or skips transactions that would overdraft
4. Maintains a 20% safety buffer

## 📊 Output Format

### CSV Columns

All dates are output in **Timestamp_NTZ** format for Snowflake compatibility:

```csv
AccountID,TransactionID,PostingDate,TransactionDate,Amount,Description,...
ACC-001,uuid-here,2024-01-01 09:00:00.000000,2024-01-01 09:00:00.000000,3000.00,Direct Deposit,...
```

### Output Summary

After generation, the script displays:

```
========================================
TRANSACTION SUMMARY
========================================
Total Transactions: 500
Date Range: 2024-01-01 00:00:00.000000 to 2024-12-31 23:59:59.000000

Account Types:
Personal    300
Business    200

Transaction Types:
Debit     450
Credit     50

Total Debits: $135,000.00
Total Credits: $84,000.00

ACCOUNT BALANCE VERIFICATION
========================================
Account ACC-001:
  Total Credits: $72,000.00
  Total Debits:  $56,800.00
  Net Balance:   $15,200.00
  Utilization:   78.9% of available credits
  ✓ Account is in good standing
```

## 🎯 Examples

### Example 1: Full Year Personal Account

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids PERS-2024-001 \
  --account-types personal \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 500 \
  --direct-deposit-amount 3000 \
  --bonus-amount 500 \
  --output-file output/personal_2024.csv
```

**Expected Output**:
- 24 direct deposits (2/month × 12 months) = $72,000
- 4 bonuses (quarterly) = $2,000
- ~470 debit transactions ≤ $59,200
- Total credits: $74,000

### Example 2: Business Account Quarter

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids BUS-Q1-001 \
  --account-types business \
  --start-date 2024-01-01 \
  --end-date 2024-03-31 \
  --num-records 200 \
  --direct-deposit-amount 7500 \
  --bonus-amount 1000 \
  --output-file output/business_q1.csv
```

**Expected Output**:
- 6 direct deposits (2/month × 3 months) = $45,000
- 1 bonus (Q1) = $1,000
- ~193 debit transactions ≤ $36,800
- Total credits: $46,000

### Example 3: Multiple Accounts Mixed Types

```bash
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids ACC-001 ACC-002 ACC-003 \
  --account-types personal business personal \
  --sf-account-ids SF-P-001 SF-B-002 SF-P-003 \
  --contact-ids CON-001 CON-002 CON-003 \
  --start-date 2024-01-01 \
  --end-date 2024-06-30 \
  --num-records 750 \
  --output-file output/mixed_accounts.csv
```

## 🔧 Troubleshooting

### Issue: "FileNotFoundError: MCCs.csv"

**Solution**: Ensure MCC file path is correct
```bash
# Check if file exists
ls ../data/MCCs.csv

# Use absolute path
python transaction_simulator.py --mcc-file /full/path/to/MCCs.csv ...
```

### Issue: "Account shows negative balance"

**Solution**: This shouldn't happen with overdraft prevention. If it does:
1. Check the output summary
2. Look for "⚠️ WARNING: Account is OVERDRAWN!"
3. Increase direct deposit amount or reduce num-records

### Issue: "Not enough transactions generated"

**Solution**: Account hit 80% limit
- Increase `--direct-deposit-amount`
- Increase `--bonus-amount`
- Reduce `--num-records`

## 📁 Output File Structure

```
output/
├── transactions.csv              # Main output file
└── transactions_2024_summary.txt # Auto-generated summary (optional)
```

## 🧪 Testing

```bash
# Test with minimal data
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids TEST-001 \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --num-records 50 \
  --output-file output/test.csv

# Verify output
head -20 output/test.csv
wc -l output/test.csv  # Should show ~50 lines
```

## 🐍 Python API Usage

You can also import and use the simulator programmatically:

```python
from transaction_simulator import TransactionSimulator

# Initialize
simulator = TransactionSimulator('data/MCCs.csv')

# Generate transactions
df = simulator.generate_transactions(
    account_ids=['ACC-001', 'ACC-002'],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=500,
    account_types=['personal', 'business'],
    direct_deposit_amount=3000.00,
    bonus_amount=500.00
)

# Save to CSV
df.to_csv('output/transactions.csv', index=False)

# Or process in memory
print(df.head())
print(df['Transaction_Type'].value_counts())
```

## 📊 Performance

Typical generation times on standard hardware:

| Records | Accounts | Time |
|---------|----------|------|
| 100 | 1 | < 1 second |
| 1,000 | 5 | ~2 seconds |
| 10,000 | 10 | ~15 seconds |
| 100,000 | 100 | ~2 minutes |

## 🔄 Integration

### Snowflake Integration

```bash
# Generate CSV
python transaction_simulator.py \
  --mcc-file ../data/MCCs.csv \
  --account-ids ACC-001 \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 1000 \
  --output-file output/transactions.csv

# Load to Snowflake
snowsql -q "
COPY INTO FINANCIAL_TRANSACTIONS
FROM @my_stage/transactions.csv
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1)
"
```

### Salesforce Data Cloud Integration

The output CSV format is compatible with Data Cloud ingestion:
- Timestamp_NTZ format for dates
- Standard field names
- UTF-8 encoding

## 📝 Notes

- All timestamps are timezone-naive (Timestamp_NTZ format)
- Dates use microsecond precision
- Transaction IDs are UUID v4
- Currency is always USD
- All amounts are rounded to 2 decimal places

## 🔗 Related

- [Snowflake Solution](../snowflake/README.md)
- [Quick Reference](../docs/QUICK_REFERENCE.md)
- [Troubleshooting](../docs/TROUBLESHOOTING.md)

---

**Script Version**: 2.0  
**Python Version**: 3.8+  
**Last Updated**: November 2024
