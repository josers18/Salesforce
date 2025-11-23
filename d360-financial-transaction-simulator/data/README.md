# Data Files

This directory contains data files required for transaction generation.

## 📁 Required Files

### MCCs.csv (Merchant Category Codes)

**REQUIRED** - This file must be present for the transaction generator to work.

#### File Format

The MCC file should be a CSV with the following columns:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `mcc` | Integer | Merchant category code | `5411` |
| `description` | String | Merchant description | `Grocery Stores, Supermarkets` |
| `category` | String | General category | `Retail outlets` |
| `Tran_category` | String | Transaction category | `Shopping` |
| `Tran_Type` | String | Transaction type | `Debit` or `Credit` |

#### Example CSV Structure

```csv
mcc,description,category,Tran_category,Tran_Type
5411,Grocery Stores,Retail outlets,Shopping,Debit
5812,Eating Places and Restaurants,Restaurants,Food & Dining,Debit
5814,Fast Food Restaurants,Fast Food,Food & Dining,Debit
9961,Direct Deposit,Incoming Direct Deposit,Income,Credit
9963,ACH Deposit,ACH Deposit,Income,Credit
```

#### Where to Get MCCs.csv

**Option 1: Use Your Existing File**
If you already have an MCC reference file, ensure it matches the format above.

**Option 2: Create from Template**
Create a new CSV file with standard MCC codes. Here's a starter template:

```csv
mcc,description,category,Tran_category,Tran_Type
5411,Grocery Stores - Supermarkets,Retail outlets,Shopping,Debit
5812,Eating Places and Restaurants,Restaurants,Food & Dining,Debit
5814,Fast Food Restaurants,Fast Food,Food & Dining,Debit
5541,Service Stations (with or without Ancillary Services),Gas Stations,Auto & Transport,Debit
5912,Drug Stores and Pharmacies,Retail outlets,Health & Fitness,Debit
5999,Miscellaneous and Specialty Retail Stores,Retail outlets,Shopping,Debit
7011,Hotels - Motels - Resorts,Hotels,Travel,Debit
3000,UNITED AIRLINES,Airlines,Travel,Debit
4121,Taxicabs and Limousines,Transportation,Auto & Transport,Debit
5311,Department Stores,Retail outlets,Shopping,Debit
5732,Electronics Stores,Retail outlets,Shopping,Debit
8011,Doctors and Physicians,Professional services and membership organizations,Health & Fitness,Debit
9961,Direct Deposit,Incoming Direct Deposit,Income,Credit
9963,ACH Deposit,ACH Deposit,Income,Credit
```

**Option 3: Standard MCC Reference**
You can find standard MCC codes from:
- ISO 18245 standard
- Payment network documentation (Visa, Mastercard)
- Financial institution resources

#### Important Notes

1. **Credit MCCs Required**:
   - MCC `9961` - Direct Deposit (Credit)
   - MCC `9963` - Bonus/ACH Deposit (Credit)
   - Without these, no credit transactions will be generated

2. **Debit MCCs Required**:
   - The file should contain multiple debit MCCs across various categories
   - More MCC codes = more realistic transaction variety

3. **Case Sensitivity**:
   - Column names should match exactly: `mcc`, `description`, `category`, `Tran_category`, `Tran_Type`
   - `Tran_Type` values: `Debit` or `Credit` (case-sensitive)

4. **File Location**:
   - Place in `data/MCCs.csv` relative to script location
   - Or specify custom path with `--mcc-file` argument

## 📊 MCC Categories

Standard categories used in the system:

### Spending Categories (Debits)
- **Retail outlets** - General shopping, department stores
- **Restaurants** - Sit-down dining
- **Fast Food** - Quick service restaurants
- **Hotels** - Lodging
- **Airlines** - Air travel
- **Gas Stations** - Fuel purchases
- **Utilities** - Bills and services
- **Transportation** - Taxis, public transit
- **Amusement and entertainment** - Recreation
- **Professional services** - Doctors, lawyers, etc.
- **Business services** - B2B services
- **Repair services** - Maintenance
- **Government services** - Fees, licenses

### Income Categories (Credits)
- **Incoming Direct Deposit** - Payroll (MCC 9961)
- **ACH Deposit** - Bonuses, transfers (MCC 9963)

## 🔧 Validating Your MCC File

### Python Script Validation

```python
import pandas as pd

# Load MCC file
mcc_df = pd.read_csv('MCCs.csv')

# Check required columns
required_columns = ['mcc', 'description', 'category', 'Tran_category', 'Tran_Type']
missing = [col for col in required_columns if col not in mcc_df.columns]

if missing:
    print(f"❌ Missing columns: {missing}")
else:
    print("✓ All required columns present")

# Check for credit MCCs
credit_mccs = mcc_df[mcc_df['Tran_Type'] == 'Credit']
print(f"\n✓ Found {len(credit_mccs)} credit MCCs")

if 9961 in credit_mccs['mcc'].values:
    print("✓ Direct Deposit MCC (9961) present")
else:
    print("❌ Missing Direct Deposit MCC (9961)")

if 9963 in credit_mccs['mcc'].values:
    print("✓ Bonus MCC (9963) present")
else:
    print("❌ Missing Bonus MCC (9963)")

# Check for debit MCCs
debit_mccs = mcc_df[mcc_df['Tran_Type'] == 'Debit']
print(f"\n✓ Found {len(debit_mccs)} debit MCCs")

# Show category distribution
print("\nCategory distribution:")
print(mcc_df['category'].value_counts())
```

### SQL Validation (Snowflake)

```sql
-- Check MCC table
SELECT 
    TRAN_TYPE,
    COUNT(*) AS mcc_count,
    COUNT(DISTINCT CATEGORY) AS categories
FROM MCC
GROUP BY TRAN_TYPE;

-- Verify required MCCs exist
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM MCC WHERE MCC = 9961) THEN '✓'
        ELSE '❌'
    END AS has_dd_mcc,
    CASE 
        WHEN EXISTS (SELECT 1 FROM MCC WHERE MCC = 9963) THEN '✓'
        ELSE '❌'
    END AS has_bonus_mcc,
    CASE 
        WHEN (SELECT COUNT(*) FROM MCC WHERE TRAN_TYPE = 'Debit') > 10 THEN '✓'
        ELSE '❌'
    END AS has_enough_debits;
```

## 🚫 What NOT to Include

Do **not** commit files with:
- Real customer data
- Proprietary merchant information
- Sensitive financial data
- Personally identifiable information (PII)

## 📝 Sample Data Generation

If you need to create test MCC data:

```python
import pandas as pd

# Create sample MCC data
mccs = [
    {'mcc': 5411, 'description': 'Grocery Stores', 'category': 'Retail outlets', 
     'Tran_category': 'Shopping', 'Tran_Type': 'Debit'},
    {'mcc': 5812, 'description': 'Restaurants', 'category': 'Restaurants', 
     'Tran_category': 'Food & Dining', 'Tran_Type': 'Debit'},
    {'mcc': 9961, 'description': 'Direct Deposit', 'category': 'Incoming Direct Deposit', 
     'Tran_category': 'Income', 'Tran_Type': 'Credit'},
    {'mcc': 9963, 'description': 'ACH Deposit', 'category': 'ACH Deposit', 
     'Tran_category': 'Income', 'Tran_Type': 'Credit'},
]

df = pd.DataFrame(mccs)
df.to_csv('MCCs.csv', index=False)
print("Sample MCC file created!")
```

## 📞 Need Help?

If you're having trouble with the MCC file:
1. Check [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
2. Verify column names match exactly
3. Ensure credit MCCs (9961, 9963) are present
4. Check that Tran_Type values are 'Debit' or 'Credit'

---

**File Format**: CSV (UTF-8)  
**Required**: Yes  
**Location**: `data/MCCs.csv`
