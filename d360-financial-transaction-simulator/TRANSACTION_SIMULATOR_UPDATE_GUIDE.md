# Transaction Simulator - Updated with SFAccountID and ContactID

**Version:** 2.0  
**Updated:** November 22, 2024  
**New Features:** SFAccountID and ContactID support

---

## 🎯 What's New

The transaction simulator now includes:
- ✅ **SFAccountID** - Salesforce Account ID field
- ✅ **ContactID** - Contact reference field  
- ✅ **Reordered columns** - Matches Snowflake table structure

---

## 📊 New Column Structure

### Output Columns (17 total)

```
1.  AccountID              - Account number (your designation)
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
16. ContactID              - NEW: Contact ID (optional)
17. Account_Type           - Personal or Business
```

**Note:** Columns reordered to match Snowflake FINANCIAL_TRANSACTIONS table!

---

## 🚀 Usage Examples

### Example 1: Basic with SF Account IDs

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids ACC-PERS-001 ACC-BIZ-001 \
    --account-types personal business \
    --sf-account-ids 001am00000qvjsAAAQ 001bm00000rwksXXXQ \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100
```

**Result:**
- AccountID: ACC-PERS-001, SFAccountID: 001am00000qvjsAAAQ
- AccountID: ACC-BIZ-001, SFAccountID: 001bm00000rwksXXXQ
- ContactID: empty for both (default)

---

### Example 2: With Contact IDs

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
- Personal account has ContactID: CON-98765
- Business account has ContactID: empty (use empty quotes "")

---

### Example 3: Default Behavior (No SF/Contact IDs)

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

---

### Example 4: Complete Example

```bash
python transaction_simulator.py \
    --mcc-file MCCs.csv \
    --account-ids PERS-ALICE BIZ-ACME PERS-BOB \
    --account-types personal business personal \
    --sf-account-ids 001am00001 001bm00002 001am00003 \
    --contact-ids CON-ALICE "" CON-BOB \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 300 \
    --output-file transactions_complete.csv
```

**Result:** 300 transactions across 3 accounts with full IDs

---

## 📋 New Command-Line Arguments

### SF Account IDs

```bash
--sf-account-ids <SF_ID1> <SF_ID2> ...
```

- **Required:** No (optional)
- **Format:** Space-separated list
- **Must Match:** Order and count of --account-ids
- **Default:** Uses account-ids if not provided

**Example:**
```bash
--account-ids ACC-001 ACC-002 ACC-003 \
--sf-account-ids 001a1 001a2 001a3
```

---

### Contact IDs

```bash
--contact-ids <CONTACT1> <CONTACT2> ...
```

- **Required:** No (optional)
- **Format:** Space-separated list
- **Must Match:** Order and count of --account-ids
- **Default:** Empty string if not provided
- **Empty Values:** Use `""` for empty contact

**Example:**
```bash
--account-ids PERS-001 BIZ-001 PERS-002 \
--contact-ids CON-123 "" CON-456
```
(Business account has no contact)

---

## 🔍 Parameter Behavior

### Defaults

| Parameter | If Not Provided | Result |
|-----------|----------------|--------|
| --account-types | Defaults to all personal | All accounts are personal |
| --sf-account-ids | Defaults to account-ids | SFAccountID = AccountID |
| --contact-ids | Defaults to empty | ContactID = "" (empty) |

---

### Validation

The simulator validates:
- ✅ Number of account-types matches account-ids
- ✅ Number of sf-account-ids matches account-ids  
- ✅ Number of contact-ids matches account-ids
- ✅ Account types are 'personal' or 'business'

**Error Example:**
```bash
--account-ids ACC-001 ACC-002 \
--sf-account-ids 001a1
# ERROR: Number of SF Account IDs (1) must match number of account IDs (2)
```

---

## 💻 Python Module Usage

### Basic Example

```python
from transaction_simulator import TransactionSimulator

simulator = TransactionSimulator('MCCs.csv')

df = simulator.generate_transactions(
    account_ids=['ACC-PERS-001', 'ACC-BIZ-001'],
    account_types=['personal', 'business'],
    sf_account_ids=['001am00000qvjsAAAQ', '001bm00000rwksXXXQ'],
    contact_ids=['CON-98765', ''],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=100
)

df.to_csv('transactions.csv', index=False)
```

---

### Using Dictionaries (Cleaner)

```python
df = simulator.generate_transactions(
    account_ids=['ACC-001', 'ACC-002'],
    account_types={
        'ACC-001': 'personal',
        'ACC-002': 'business'
    },
    sf_account_ids={
        'ACC-001': '001am00000qvjsAAAQ',
        'ACC-002': '001bm00000rwksXXXQ'
    },
    contact_ids={
        'ACC-001': 'CON-98765',
        'ACC-002': ''  # Empty for business
    },
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=100
)
```

---

### Default Behavior

```python
# Minimal - uses defaults
df = simulator.generate_transactions(
    account_ids=['ACC-001'],
    start_date='2024-01-01',
    end_date='2024-12-31',
    num_records=50
)

# Result:
# - AccountID: ACC-001
# - SFAccountID: ACC-001 (defaults to AccountID)
# - ContactID: "" (empty)
# - Account_Type: Personal (default)
```

---

## 📊 Sample Output

```csv
AccountID,TransactionID,PostingDate,TransactionDate,Amount,Description,Transaction_Category,MCC,MCC_Description,Transaction_status,Currency,Transaction_Type,Source_Transaction_Type,Data_Date,SFAccountID,ContactID,Account_Type
ACC-PERS-001,uuid-123,2024-01-15 10:30:00,2024-01-15 10:30:00,45.50,Movie Theater,Entertainment,7832,Movie Theaters,Posted,USD,Debit,Debit,2024-11-22,001am00000qvjsAAAQ,CON-98765,Personal
ACC-BIZ-001,uuid-456,2024-01-15 11:45:00,2024-01-15 11:45:00,850.00,Office Supplies,Shopping,5943,Stationery Stores,Posted,USD,Debit,Debit,2024-11-22,001bm00000rwksXXXQ,,Business
```

**Notice:**
- Personal account has ContactID populated
- Business account has empty ContactID
- SFAccountID is different from AccountID
- Column order matches Snowflake table

---

## ✅ Validation

### Check Your Output

```python
import pandas as pd

df = pd.read_csv('generated_transactions.csv')

# Check columns
print("Columns:", df.columns.tolist())
# Should have 17 columns

# Check SF Account IDs
print("\nSF Account IDs:", df['SFAccountID'].unique())

# Check Contact IDs
print("\nContact IDs:", df['ContactID'].unique())

# Check Account Types
print("\nAccount Types:", df['Account_Type'].value_counts())
```

---

## 🚨 Common Errors

### Error: Mismatched Counts

```bash
ERROR: Number of SF Account IDs (2) must match number of account IDs (3)
```

**Fix:** Ensure all parameter lists have same length
```bash
--account-ids A B C \
--sf-account-ids 001 002 003  # Must have 3
```

---

### Error: Empty Contact for Business

If you want business accounts without contacts, use empty quotes:

```bash
--contact-ids CON-123 "" CON-456
                       ↑ Empty for business
```

---

## 🎯 Best Practices

1. **Use clear naming** - Makes debugging easier
   ```bash
   --account-ids PERS-ALICE BIZ-ACME
   --sf-account-ids 001am00000qvjsAAAQ 001bm00000rwksXXXQ
   ```

2. **Keep order consistent** - SF IDs and Contact IDs must match account IDs order

3. **Document your mappings** - Keep a reference file:
   ```
   ACC-PERS-001 → 001am00000qvjsAAAQ → CON-98765
   ACC-BIZ-001  → 001bm00000rwksXXXQ → (empty)
   ```

4. **Validate output** - Check SFAccountID and ContactID are populated correctly

5. **Use defaults wisely** - If SF IDs = Account IDs, you don't need to specify

---

## 🔄 Migration from Old Version

### Old Command (v1.0)
```bash
python transaction_simulator.py \
    --account-ids ACC-001 ACC-002 \
    --account-types personal business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100
```

### New Command (v2.0) - With IDs
```bash
python transaction_simulator.py \
    --account-ids ACC-001 ACC-002 \
    --account-types personal business \
    --sf-account-ids 001am00000qvjsAAAQ 001bm00000rwksXXXQ \
    --contact-ids CON-123 "" \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100
```

### New Command (v2.0) - Using Defaults
```bash
# If SF IDs = Account IDs, just use old command!
python transaction_simulator.py \
    --account-ids ACC-001 ACC-002 \
    --account-types personal business \
    --start-date 2024-01-01 \
    --end-date 2024-12-31 \
    --num-records 100

# Result: SFAccountID will be ACC-001, ACC-002
# ContactID will be empty
```

---

## 📝 Summary of Changes

| Change | Before | After |
|--------|--------|-------|
| **Columns** | 15 | 17 (+SFAccountID, +ContactID) |
| **Column Order** | Account_Type at position 2 | Account_Type at position 17 (end) |
| **SF Account ID** | Not supported | Supported (optional) |
| **Contact ID** | Not supported | Supported (optional) |
| **Default SFAccountID** | N/A | AccountID |
| **Default ContactID** | N/A | Empty string |

---

## ✅ Compatibility

**Backwards Compatible:** ✅ Yes!

Old commands still work:
- SFAccountID defaults to AccountID
- ContactID defaults to empty
- Account_Type moved to end but still present

**Forward Compatible:** ✅ Yes!

New output structure matches Snowflake:
- Column order: ACCOUNTID first, IDs at end
- All 17 columns present
- Ready for direct import

---

## 🎉 Summary

The updated simulator now supports:
1. ✅ **SFAccountID** - Salesforce Account ID mapping
2. ✅ **ContactID** - Contact reference (optional)
3. ✅ **Correct column order** - Matches Snowflake table
4. ✅ **Backwards compatible** - Old commands still work
5. ✅ **Flexible inputs** - Lists, dicts, or defaults

**Ready to use with your Snowflake table structure!** 🚀

---

**File:** [transaction_simulator.py](computer:///mnt/user-data/outputs/transaction_simulator.py)
