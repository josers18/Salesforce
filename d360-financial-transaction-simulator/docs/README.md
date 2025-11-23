# Documentation Index

Complete documentation for the Financial Transaction Generator system.

## 📚 Main Documentation

### Getting Started
- **[Main README](../README.md)** - Project overview and quick start
- **[Python README](../python/README.md)** - Python standalone documentation
- **[Snowflake README](../snowflake/README.md)** - Snowflake solution documentation

### Reference Guides
- **[Quick Reference](QUICK_REFERENCE.md)** - Common commands and queries
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Fix common issues
- **[Migration Guide](MIGRATION_GUIDE.md)** - Migrate from old system to new

### Project Information
- **[Contributing](../CONTRIBUTING.md)** - How to contribute
- **[Changelog](../CHANGELOG.md)** - Version history
- **[License](../LICENSE)** - MIT License

## 🏗️ Architecture Documentation

### System Design
- **[System Overview](architecture/system_overview.md)** - High-level architecture
- **[Database Schema](architecture/database_schema.md)** - Table structures and relationships
- **[Credit Schedule](architecture/credit_schedule.md)** - Direct deposit and bonus timing

### Technical Details
- **[Overdraft Prevention](architecture/overdraft_prevention.md)** - How the 80% rule works
- **[Balance Tracking](architecture/balance_tracking.md)** - Monthly balance calculations
- **[Transaction Generation](architecture/transaction_generation.md)** - How transactions are created

## 💡 Examples & Use Cases

### Common Scenarios
- **[Bulk Generation](examples/scenario_1_bulk_generation.md)** - Generate historical data
- **[Daily Automation](examples/scenario_2_daily_automation.md)** - Automated daily runs
- **[Custom Credits](examples/scenario_3_custom_credits.md)** - Customize credit amounts

### Code Examples
- **[Python Examples](../python/examples/)** - Shell scripts and Python code
- **[Snowflake Examples](../snowflake/examples/)** - SQL scripts and queries

## 🔧 Setup & Configuration

### Initial Setup
1. **Prerequisites** - Python 3.8+, Snowflake access
2. **Installation** - Install dependencies
3. **Data Files** - Set up MCC file (see [Data README](../data/README.md))
4. **Database Setup** - Create tables and procedures

### Configuration
- **Python Configuration** - Command-line arguments
- **Snowflake Configuration** - ACCOUNT_CREDIT_CONFIG table
- **Task Scheduling** - Snowflake tasks for automation

## 🐛 Troubleshooting

### Common Issues
1. **No transactions generated** → [Troubleshooting Guide](TROUBLESHOOTING.md)
2. **Accounts overdrawn** → Increase credit amounts
3. **High utilization** → Adjust spending limits
4. **MCC file errors** → Check [Data README](../data/README.md)

### Debug Tools
- **Debug Stored Procedure** - Verbose output version
- **Diagnostic Queries** - Check system health
- **Validation Scripts** - Verify configuration

## 📊 Data & Schema

### Database Objects
- **Tables** - ACCOUNT_CREDIT_CONFIG, ACCOUNT_BALANCE_TRACKER, FINANCIAL_TRANSACTIONS
- **Views** - VW_CURRENT_MONTH_BALANCES, VW_ACCOUNT_SUMMARY
- **Procedures** - generate_daily_transactions

### Data Files
- **MCCs.csv** - Merchant category codes (required)
- **Output Files** - Generated transaction CSVs

## 🔄 Processes & Workflows

### Daily Workflow
1. Scheduled task runs at 2 AM
2. Check if today is credit day (1st, 15th, or bonus day)
3. Generate credits if applicable
4. Generate debit transactions
5. Update balance tracker
6. Return summary

### Monthly Workflow
1. Review balance tracker on 1st of month
2. Adjust credit amounts if needed
3. Generate monthly reports
4. Archive old data (optional)

## 📈 Monitoring & Reporting

### Key Metrics
- Transaction count by account
- Credit utilization percentage
- Account status (good standing, high utilization, overdrawn)
- Monthly credit/debit totals

### Dashboards
- Current month balances
- Account health status
- Historical trends
- Utilization alerts

## 🔐 Security & Best Practices

### Security
- No credentials in code
- Use environment variables
- Limit database permissions
- Regular security audits

### Best Practices
- Test changes in dev environment
- Monitor balance tracker regularly
- Keep credit amounts updated
- Document custom configurations

## 📖 Additional Resources

### External Documentation
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Python Documentation](https://docs.python.org/)

### Related Topics
- Merchant Category Codes (MCC)
- Salesforce Data Cloud
- Financial transaction modeling
- Data generation best practices

## 🆘 Getting Help

### Support Channels
1. **Check Documentation** - Start here first
2. **GitHub Issues** - Report bugs or request features
3. **Troubleshooting Guide** - Common solutions
4. **Examples** - Learn from working code

### Before Asking for Help
- [ ] Checked [Troubleshooting Guide](TROUBLESHOOTING.md)
- [ ] Reviewed relevant documentation
- [ ] Tried the debug version
- [ ] Checked system requirements
- [ ] Verified configuration

## 📝 Documentation Standards

### Writing Guidelines
- Use clear, concise language
- Include code examples
- Add screenshots when helpful
- Keep formatting consistent
- Update changelog

### Code Documentation
- Add docstrings to functions
- Comment complex logic
- Include usage examples
- Document parameters and returns

## 🔄 Keeping Documentation Updated

### When to Update
- New features added
- Bugs fixed
- Configuration changes
- Process improvements
- Breaking changes

### How to Update
1. Make changes in appropriate doc file
2. Update CHANGELOG.md
3. Test examples still work
4. Submit pull request
5. Review and merge

---

**Last Updated**: November 2024  
**Maintained By**: Jose  
**Version**: 2.0
