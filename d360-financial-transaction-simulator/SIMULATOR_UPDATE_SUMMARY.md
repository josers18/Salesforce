# ✅ Transaction Simulator Updated - SFAccountID & ContactID Support

**Status:** ✅ Complete and Tested  
**Version:** 2.0  
**Date:** November 22, 2024

---

## 🎯 What Was Done

Updated `transaction_simulator.py` to include:
1. ✅ **SFAccountID field** - Salesforce Account ID support
2. ✅ **ContactID field** - Contact reference support
3. ✅ **Column reordering** - Matches Snowflake table structure
4. ✅ **Backwards compatible** - Old commands still work

---

## 📊 Updated Output Structure

### New Columns (17 total)

```
1.  AccountID              - Your account number
2.  TransactionID          - UUID
3.  PostingDate            - Timestamp
4.  TransactionDate        - Timestamp
5.  Amount                 - Decimal
6.  Description            - Merchant name
7.  Transaction_Category   - Category
8.  MCC                    - MCC code
9.  MCC_Description        - MCC description
10. Transaction_status     - Status
11. Currency               - Currency code
12. Transaction_Type       - Type
13. Source_Transaction_Type - Source type
14. Data_Date              - Generation date
15. SFAccountID            - NEW: Salesforce Account ID
16. ContactID              - NEW: Contact ID
17. Account_Type           - Personal or Business
```

**Key Change:** Account_Type moved from position 2 to position 17 (matches Snowflake!)

---

## 🚀 Quick Usage

### With SF Account IDs and Contact IDs

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ACC-PERS-001 ACC-BIZ-001 \
    --account-types personal business \
    --sf-account-ids 001am00000qvjsAAAQ 001bm00000rwksXXXQ \
    --contact-ids CON-98765 "" \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100
```

**Result:**
- Personal: AccountID=ACC-PERS-001, SFAccountID=001am00000qvjsAAAQ, ContactID=CON-98765
- Business: AccountID=ACC-BIZ-001, SFAccountID=001bm00000rwksXXXQ, ContactID=(empty)

---

### Using Defaults (Backwards Compatible)

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ACC-001 ACC-002 \
    --account-types personal business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100
```

**Result:**
- SFAccountID defaults to AccountID (ACC-001, ACC-002)
- ContactID defaults to empty string
- Works exactly like old version!

---

## 📁 Your Files

### Updated Simulator
**[transaction_simulator.py](computer:///mnt/user-data/outputs/transaction_simulator.py)**
- Updated with SFAccountID and ContactID support
- Column order matches Snowflake table
- Backwards compatible

### Usage Guide
**[TRANSACTION_SIMULATOR_UPDATE_GUIDE.md](computer:///mnt/user-data/outputs/TRANSACTION_SIMULATOR_UPDATE_GUIDE.md)**
- Complete usage examples
- Command-line parameter details
- Python module examples
- Migration guide

### Test Output
**[test_output_with_ids.csv](computer:///mnt/user-data/outputs/test_output_with_ids.csv)**
- Sample output showing new structure
- 20 test transactions
- Demonstrates SFAccountID and ContactID

---

## ✅ Validation Results

### Test Run
```bash
python transaction_simulator.py \
    --account-ids TEST-PERS-001 TEST-BIZ-001 \
    --account-types personal business \
    --sf-account-ids 001am00000TEST1 001bm00000TEST2 \
    --contact-ids CON-TEST-123 "" \
    --num-records 20
```

**Results:**
- ✅ 17 columns generated
- ✅ Personal account: ContactID = "CON-TEST-123"
- ✅ Business account: ContactID = empty
- ✅ SFAccountID correctly populated for both
- ✅ Business: 0 entertainment transactions
- ✅ Column order matches Snowflake table

---

## 🔍 Sample Output

```csv
AccountID,TransactionID,PostingDate,TransactionDate,Amount,Description,Transaction_Category,MCC,MCC_Description,Transaction_status,Currency,Transaction_Type,Source_Transaction_Type,Data_Date,SFAccountID,ContactID,Account_Type
TEST-PERS-001,uuid-1,2024-11-01,2024-11-01,3000.0,Direct Deposit,Paycheck,9961,Direct Deposit,Posted,USD,Credit,Credit,2024-11-22,001am00000TEST1,CON-TEST-123,Personal
TEST-BIZ-001,uuid-2,2024-11-01,2024-11-01,928.92,Nursing Facilities,Health & Fitness,8050,Nursing Facilities,Posted,USD,Debit,Debit,2024-11-22,001bm00000TEST2,,Business
```

**Notice:**
- Personal has ContactID populated
- Business has empty ContactID
- SFAccountID differs from AccountID
- All 17 columns present

---

## 🎯 Key Features

### Flexible Input Formats

**Lists (Command-line)**
```bash
--account-ids A B C \
--sf-account-ids SF1 SF2 SF3 \
--contact-ids C1 C2 C3
```

**Dictionaries (Python)**
```python
sf_account_ids={
    'A': 'SF1',
    'B': 'SF2',
    'C': 'SF3'
}
```

---

### Smart Defaults

| Parameter | If Not Provided | Default Value |
|-----------|----------------|---------------|
| --sf-account-ids | Not specified | Uses --account-ids |
| --contact-ids | Not specified | Empty string |
| --account-types | Not specified | All 'personal' |

---

### Validation

Automatically validates:
- ✅ Parameter counts match
- ✅ Account types are valid
- ✅ Lists are same length

**Example Error:**
```bash
ERROR: Number of SF Account IDs (2) must match number of account IDs (3)
```

---

## 🔄 Migration Guide

### Old Version (v1.0)
- 15 columns
- No SFAccountID
- No ContactID
- Account_Type at position 2

### New Version (v2.0)
- 17 columns (+SFAccountID, +ContactID)
- Account_Type at position 17
- Backwards compatible
- Matches Snowflake structure

**Migration:** Just add new parameters to existing commands!

```bash
# Old command
python transaction_simulator.py --account-ids ACC-001 ...

# New command (add these)
python transaction_simulator.py \
    --account-ids ACC-001 \
    --sf-account-ids 001am00000qvjsAAAQ \  # NEW
    --contact-ids CON-123 ...              # NEW
```

---

## 💻 Python Module Example

```python
from transaction_simulator import TransactionSimulator

simulator = TransactionSimulator('MCCs.csv')

# Generate with all IDs
df = simulator.generate_transactions(
    account_ids=['ACC-PERS-001', 'ACC-BIZ-001'],
    account_types=['personal', 'business'],
    sf_account_ids=['001am00000qvjsAAAQ', '001bm00000rwksXXXQ'],
    contact_ids=['CON-98765', ''],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=100
)

# Verify structure
print(f"Columns: {len(df.columns)}")  # Should be 17
print(f"Personal ContactID: {df[df['AccountID']=='ACC-PERS-001']['ContactID'].iloc[0]}")
print(f"Business ContactID: {df[df['AccountID']=='ACC-BIZ-001']['ContactID'].iloc[0]}")
print(f"Business Entertainment: {len(df[(df['Account_Type']=='Business') & (df['Transaction_Category']=='Entertainment')])}")  # Should be 0

df.to_csv('transactions.csv', index=False)
```

---

## ✅ Validation Checklist

After updating:
- [ ] Simulator file copied to outputs
- [ ] Test run successful (20 transactions generated)
- [ ] 17 columns in output
- [ ] SFAccountID populated correctly
- [ ] ContactID populated for personal, empty for business
- [ ] Business has 0 entertainment transactions
- [ ] Column order matches Snowflake table
- [ ] Backwards compatible (old commands work)

---

## 🎉 Summary

**What's New:**
1. ✅ SFAccountID field (Salesforce Account ID)
2. ✅ ContactID field (Contact reference)
3. ✅ 17 columns total (was 15)
4. ✅ Column order matches Snowflake table
5. ✅ Backwards compatible with old commands

**Status:**
- ✅ Updated
- ✅ Tested
- ✅ Validated
- ✅ Ready to use

**Files:**
- [transaction_simulator.py](computer:///mnt/user-data/outputs/transaction_simulator.py) - Updated simulator
- [TRANSACTION_SIMULATOR_UPDATE_GUIDE.md](computer:///mnt/user-data/outputs/TRANSACTION_SIMULATOR_UPDATE_GUIDE.md) - Complete guide
- [test_output_with_ids.csv](computer:///mnt/user-data/outputs/test_output_with_ids.csv) - Sample output

---

**The simulator is now fully compatible with your Snowflake table structure!** 🚀

Use it with the new parameters to generate transactions that match your FINANCIAL_TRANSACTIONS table exactly.
