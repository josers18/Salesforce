# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-23

### Added
- **Configuration-based credit management** - Credit amounts now stored in ACCOUNT_CREDIT_CONFIG table
- **ACCOUNT_BALANCE_TRACKER** table for monthly balance tracking
- **ACCOUNT_DAILY_BALANCE** table for daily balance snapshots
- **VW_CURRENT_MONTH_BALANCES** view for current month status
- **VW_ACCOUNT_SUMMARY** view for lifetime account summary
- **Quarterly bonus schedule** - Changed from monthly to quarterly (more realistic)
- **Expected credit calculation** - Allows spending before deposits are made
- **Debug stored procedure** version with verbose output
- **Timestamp_NTZ format** for all date columns
- **Comprehensive documentation** including troubleshooting guides
- **Account balance verification** in Python script output
- **GitHub repository structure** with proper organization

### Changed
- **Direct deposits** now generate on 1st and 15th (was variable)
- **Bonuses** now quarterly (Jan, Apr, Jul, Oct) instead of monthly
- **Overdraft prevention** now uses expected monthly credits, not just deposited amounts
- **Stored procedure** completely refactored for better balance tracking
- **Python script** updated with quarterly bonuses and improved reporting
- **Credit amounts** now fully configurable via database table

### Fixed
- **Issue**: Stored procedure generated no transactions on non-DD days
  - **Fix**: Use expected monthly credits for budget calculation
- **Issue**: Accounts could overdraft if debits occurred before credits
  - **Fix**: Calculate budget based on configured amounts, not just deposits
- **Issue**: Hard-coded credit amounts made customization difficult
  - **Fix**: Moved all credit config to database table

### Removed
- Hard-coded direct deposit amounts from stored procedure
- Monthly bonus generation (replaced with quarterly)

## [1.0.0] - 2024-10-01

### Added
- Initial release
- Python standalone transaction generator
- Snowflake stored procedure for daily generation
- Basic overdraft prevention (80% rule)
- Direct deposit generation
- Monthly bonus generation
- MCC-based transaction generation
- Account type support (Personal/Business)

### Known Issues
- Credit amounts hard-coded in stored procedure
- No balance tracking between runs
- Bonuses generated monthly (too frequent)
- Overdraft prevention too strict on non-DD days

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 2.0.0 | 2024-11-23 | Configuration-based credits, balance tracking, quarterly bonuses |
| 1.0.0 | 2024-10-01 | Initial release with basic functionality |

## Upgrade Guide

### From 1.0.0 to 2.0.0

**Breaking Changes**:
- Bonus frequency changed from monthly to quarterly
  - If you need same annual total, multiply bonus amount by 3
- Direct deposit days now fixed at 1st and 15th
- New database tables required

**Migration Steps**:
1. Run `@snowflake/setup/01_create_balance_tables.sql`
2. Run `@snowflake/setup/02_populate_credit_config.sql`
3. Review and adjust credit amounts in ACCOUNT_CREDIT_CONFIG
4. Deploy new stored procedure: `@snowflake/setup/05_stored_procedure_FIXED.sql`
5. Test with `CALL generate_daily_transactions(10);`

See [MIGRATION_GUIDE.md](docs/MIGRATION_GUIDE.md) for detailed instructions.

## Future Releases

### Planned for 2.1.0
- [ ] Add support for custom direct deposit schedules (weekly, bi-weekly)
- [ ] Add seasonal spending patterns
- [ ] Add account age-based credit increases
- [ ] Add support for joint accounts
- [ ] Add transaction approval/pending status
- [ ] Add declined transaction generation

### Planned for 3.0.0
- [ ] Machine learning-based realistic spending patterns
- [ ] Integration with real merchant data APIs
- [ ] Multi-currency support
- [ ] Credit card transactions with interest calculations
- [ ] Loan payment schedules
- [ ] Investment account transactions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute to this changelog.

---

**Maintained by**: Jose  
**Last Updated**: November 23, 2024
