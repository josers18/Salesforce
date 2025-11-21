# Quick Start Guide - Transaction Simulator with Account Types

## Installation (30 seconds)

```bash
pip install pandas numpy
```

## Choose Your Scenario

### 🏢 Business Account (B2B Transactions)

Generate 500 business transactions with NO entertainment:

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids BUSINESS_LLC \
    --account-types business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

✅ **You get:**
- 500 B2B transactions (office supplies, contractors, business travel)
- $7,500 revenue deposits (twice monthly: 1st & 15th)
- $1,000 monthly bonuses (last day of month)
- **ZERO entertainment/leisure spending**
- Higher transaction amounts (2.2× average vs personal)

---

### 👤 Personal Account (Consumer Spending)

Generate 500 consumer transactions with entertainment:

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids JOHN_PERSONAL \
    --account-types personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 500
```

✅ **You get:**
- 500 consumer transactions (retail, dining, entertainment)
- $3,000 direct deposits (twice monthly: 1st & 15th)
- $500 monthly bonuses (last day of month)
- Entertainment, movies, sports events included
- Typical consumer spending patterns

---

### 🏠 Mixed Accounts (Realistic Household)

Generate 1000 transactions across personal and business accounts:

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ALICE_PERSONAL BOB_BUSINESS JOINT_PERSONAL \
    --account-types personal business personal \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 1000
```

✅ **You get:**
- Each account maintains its own pattern
- Business account: B2B only, higher amounts
- Personal accounts: full consumer spending
- Realistic multi-account scenario

---

## What Makes Business Different?

| Feature | Personal | Business |
|---------|----------|----------|
| **Avg Transaction** | ~$400 | ~$900 **(2.2×)** |
| **Direct Deposits** | $3,000 | $7,500 **(2.5×)** |
| **Monthly Bonuses** | $500 | $1,000 **(2×)** |
| **Entertainment** | ✅ Yes | ❌ **None** |
| **Fast Food** | ✅ Yes | ❌ **None** |
| **Focus** | Consumer | B2B |

## Output Example

```csv
AccountID,Account_Type,TransactionID,PostingDate,TransactionDate,Amount,Description,...
PERSONAL,Personal,uuid-1,2024-01-01,2024-01-01,3000.0,Direct Deposit,...
BUSINESS,Business,uuid-2,2024-01-01,2024-01-01,7500.0,Business Revenue Deposit,...
PERSONAL,Personal,uuid-3,2024-01-05,2024-01-05,45.00,Movie Theater,...
BUSINESS,Business,uuid-4,2024-01-05,2024-01-05,850.00,Office Supplies,...
```

Notice:
- Different deposit amounts
- Personal has entertainment ($45 movie)
- Business has higher amounts ($850 office supplies)
- No entertainment for business account

## Common Options

### Higher Revenue Business
```bash
--direct-deposit-amount 15000 --bonus-amount 3000
```
Result: $37,500 monthly revenue + $6,000 bonuses

### Freelancer
```bash
--account-types personal --direct-deposit-amount 5000
```
Result: $5,000 monthly income with personal spending

### No Income (Just Expenses)
```bash
--no-direct-deposits --no-bonuses
```
Result: Only expense transactions

## Verify Your CSV

```bash
python verify_csv.py generated_transactions.csv
```

Output shows:
- Account type breakdown
- Transaction counts
- Average amounts
- Format verification

## Troubleshooting

**Error: "No module named 'pandas'"**
```bash
pip install pandas numpy
```

**Error: "MCCs.csv not found"**
- Make sure MCCs.csv is in the same directory
- Or use: `--mcc-file /path/to/MCCs.csv`

**Want different account type per account?**
```bash
--account-ids ACC001 ACC002 ACC003 \
--account-types personal business personal
```
Order must match!

## Next Steps

- **Full Documentation:** See README.md
- **Account Type Details:** See ACCOUNT_TYPES_GUIDE.md
- **Python Examples:** Run example_account_types.py
- **More Examples:** See example files in outputs folder

## Key Takeaway

🎯 **Business accounts automatically:**
- Get 2.5× higher deposits
- Get 2× higher bonuses
- Exclude all entertainment
- Focus on B2B transactions
- Have higher transaction amounts

Just add `--account-types business` and everything adjusts!

---

**Happy simulating! 🚀**
