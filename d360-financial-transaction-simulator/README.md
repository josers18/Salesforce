# Financial Transaction Generator

A comprehensive system for generating realistic financial transactions with overdraft prevention, balance tracking, and Salesforce Data Cloud integration.

[![Python Version](https://img.shields.io/badge/python-3.8%2B-blue)](https://www.python.org/downloads/)
[![Snowflake](https://img.shields.io/badge/snowflake-compatible-blue)](https://www.snowflake.com/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 🎯 Overview

This system provides two complementary approaches for generating realistic financial transaction data:

1. **Python Standalone** - For bulk historical data generation and ad-hoc scenarios
2. **Snowflake Stored Procedures** - For automated daily transaction generation

### Key Features

✅ **Configuration-Based Credit Management** - No hard-coded amounts  
✅ **Realistic Credit Schedule** - Bi-monthly direct deposits, quarterly bonuses  
✅ **Overdraft Prevention** - 80% spending limit with balance tracking  
✅ **Salesforce Data Cloud Ready** - Timestamp_NTZ format  
✅ **Business & Personal Accounts** - Different spending patterns  
✅ **MCC-Based Transactions** - Real merchant category codes  

## 📊 Quick Stats

- **2 direct deposits/month** (1st & 15th)
- **4 bonuses/year** (Jan 1, Apr 1, Jul 1, Oct 1)
- **80% spending limit** (20% safety buffer)
- **324 MCC categories** supported

## 🚀 Quick Start

### Python Standalone

```bash
# Install dependencies
pip install -r requirements.txt

# Generate transactions
python transaction_simulator.py \
  --mcc-file data/MCCs.csv \
  --account-ids ACC-001 ACC-002 \
  --account-types personal business \
  --start-date 2024-01-01 \
  --end-date 2024-12-31 \
  --num-records 1000 \
  --output-file output/transactions_2024.csv
```

### Snowflake

```sql
-- 1. Create tables
@snowflake/01_create_balance_tables.sql

-- 2. Populate configuration
@snowflake/02_populate_credit_config.sql

-- 3. Deploy stored procedure
@snowflake/05_stored_procedure_FIXED.sql

-- 4. Generate transactions
CALL generate_daily_transactions(15);
```

## 📁 Repository Structure

```
financial-transaction-generator/
├── README.md                          # This file
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── requirements.txt                   # Python dependencies
│
├── python/                            # Python standalone solution
│   ├── README.md                      # Python-specific docs
│   ├── transaction_simulator.py      # Main script
│   ├── config/                        # Configuration files
│   │   └── example_config.yaml       # Example configuration
│   └── examples/                      # Usage examples
│       └── generate_year.sh          # Example shell script
│
├── snowflake/                         # Snowflake solution
│   ├── README.md                      # Snowflake-specific docs
│   ├── setup/                         # Setup scripts (run in order)
│   │   ├── 01_create_balance_tables.sql
│   │   ├── 02_populate_credit_config.sql
│   │   └── 05_stored_procedure_FIXED.sql
│   ├── troubleshooting/               # Diagnostic scripts
│   │   ├── troubleshoot_no_transactions.sql
│   │   ├── quick_fix_no_transactions.sql
│   │   └── 04_stored_procedure_debug_version.sql
│   └── examples/                      # Example queries
│       ├── daily_task_setup.sql
│       └── balance_queries.sql
│
├── data/                              # Data files
│   ├── MCCs.csv                       # Merchant Category Codes (required)
│   └── README.md                      # Data file descriptions
│
├── docs/                              # Documentation
│   ├── README.md                      # Documentation index
│   ├── QUICK_REFERENCE.md            # Quick reference card
│   ├── TROUBLESHOOTING.md            # Troubleshooting guide
│   ├── MIGRATION_GUIDE.md            # Migration from old system
│   ├── architecture/                  # Architecture docs
│   │   ├── system_overview.md
│   │   ├── database_schema.md
│   │   └── credit_schedule.md
│   └── examples/                      # Example scenarios
│       ├── scenario_1_bulk_generation.md
│       ├── scenario_2_daily_automation.md
│       └── scenario_3_custom_credits.md
│
└── tests/                             # Test files
    ├── test_python_simulator.py
    └── test_snowflake_procedures.sql
```

## 💰 Credit Schedule

### Personal Accounts
| Credit Type | Frequency | Amount | Annual Total |
|-------------|-----------|--------|--------------|
| Direct Deposit | Bi-Monthly (1st & 15th) | $3,000 | $72,000 |
| Quarterly Bonus | Quarterly (1st of Q) | $500 | $2,000 |
| **Total Annual Credits** | | | **$74,000** |
| **Max Annual Spending** | (80% limit) | | **$59,200** |

### Business Accounts
| Credit Type | Frequency | Amount | Annual Total |
|-------------|-----------|--------|--------------|
| Direct Deposit | Bi-Monthly (1st & 15th) | $7,500 | $180,000 |
| Quarterly Bonus | Quarterly (1st of Q) | $1,000 | $4,000 |
| **Total Annual Credits** | | | **$184,000** |
| **Max Annual Spending** | (80% limit) | | **$147,200** |

## 🏗️ Architecture

### Python Standalone
```
User Input → Transaction Simulator → CSV Output
  ↓
- Account IDs
- Date Range              ↓
- Record Count            - Generate Credits
- Credit Amounts          - Generate Debits
                          - Track Balance
                          - Prevent Overdrafts
                               ↓
                          Timestamp_NTZ
                          Formatted CSV
```

### Snowflake
```
ACCOUNT_CREDIT_CONFIG → Stored Procedure → FINANCIAL_TRANSACTIONS
        ↓                      ↓                      ↓
- DD Amounts            - Read Config           - All Transactions
- Bonus Amounts         - Generate Credits      - Timestamp_NTZ
- Schedules             - Generate Debits            ↓
                        - Track Balance         ACCOUNT_BALANCE_TRACKER
                               ↓                      ↓
                        FINANCIAL_TRANSACTIONS  - Monthly Balances
                                                - Utilization %
                                                - Overdraft Prevention
```

## 📖 Documentation

- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Common commands and queries
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Fix common issues
- **[Migration Guide](docs/MIGRATION_GUIDE.md)** - Migrate from old system
- **[Python README](python/README.md)** - Python-specific documentation
- **[Snowflake README](snowflake/README.md)** - Snowflake-specific documentation

## 🔧 Configuration

### Python

Edit account configuration directly via command-line arguments:

```bash
python transaction_simulator.py \
  --account-ids ACC-001 ACC-002 \
  --account-types personal business \
  --direct-deposit-amount 3000 \
  --bonus-amount 500
```

### Snowflake

Update credit configuration in the database:

```sql
UPDATE ACCOUNT_CREDIT_CONFIG
SET 
    DIRECT_DEPOSIT_AMOUNT = 5000.00,
    BONUS_AMOUNT = 1000.00
WHERE ACCOUNTID = 'VIP-001';
```

## 🧪 Testing

### Python

```bash
# Test with small dataset
python transaction_simulator.py \
  --mcc-file data/MCCs.csv \
  --account-ids TEST-001 \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --num-records 50 \
  --output-file test_output.csv
```

### Snowflake

```sql
-- Test with debug version
@snowflake/troubleshooting/04_stored_procedure_debug_version.sql
CALL generate_daily_transactions_debug(5);

-- Test production version
CALL generate_daily_transactions(10);
```

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/financial-transaction-generator/issues)
- **Documentation**: [docs/](docs/)
- **Troubleshooting**: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## 📊 Database Schema

### Key Tables

1. **ACCOUNT_CREDIT_CONFIG** - Credit configuration per account
2. **ACCOUNT_BALANCE_TRACKER** - Monthly balance tracking
3. **FINANCIAL_TRANSACTIONS** - All generated transactions
4. **MCC** - Merchant category codes

See [Database Schema Documentation](docs/architecture/database_schema.md) for details.

## 🎯 Use Cases

1. **Demo Systems** - Realistic transaction data for demos
2. **Testing** - Test data for Salesforce Data Cloud
3. **Development** - Sample data for application development
4. **Training** - Training data for ML models
5. **Analytics** - Historical data for analytics testing

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

## 👥 Authors

- **Jose** - *Initial work*

## 🙏 Acknowledgments

- Merchant Category Codes (MCC) based on industry standards
- Built for Salesforce Data Cloud integration
- Designed for Snowflake data warehousing

---

**Version**: 2.0  
**Last Updated**: November 2024  
**Status**: Production Ready ✅
