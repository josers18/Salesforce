# Contributing to Financial Transaction Generator

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🤝 How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. **Search existing issues** to avoid duplicates
2. **Create a new issue** with a clear title and description
3. **Include**:
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (Python version, Snowflake version, etc.)
   - Relevant logs or error messages

### Submitting Changes

1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test your changes**:
   ```bash
   # Python
   python transaction_simulator.py --mcc-file data/MCCs.csv --account-ids TEST-001 --start-date 2024-01-01 --end-date 2024-01-31 --num-records 50 --output-file test.csv
   
   # Snowflake
   @snowflake/troubleshooting/04_stored_procedure_debug_version.sql
   CALL generate_daily_transactions_debug(5);
   ```
5. **Commit your changes**:
   ```bash
   git commit -m "feat: Add new feature description"
   ```
6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Create a Pull Request**

## 📝 Coding Standards

### Python

- Follow [PEP 8](https://pep8.org/) style guide
- Use meaningful variable names
- Add docstrings for functions and classes
- Keep functions focused and under 50 lines when possible
- Add comments for complex logic

Example:
```python
def generate_amount_for_mcc(self, mcc_row, account_type='personal'):
    """
    Generate a realistic amount based on MCC category and account type.
    
    Args:
        mcc_row: Row from MCC dataframe
        account_type: 'personal' or 'business'
        
    Returns:
        Float amount rounded to 2 decimal places
    """
    # Implementation here
    pass
```

### SQL

- Use uppercase for SQL keywords
- Use snake_case for table and column names
- Add comments for complex queries
- Format for readability with proper indentation

Example:
```sql
-- Create balance tracker table with proper constraints
CREATE TABLE ACCOUNT_BALANCE_TRACKER (
    ACCOUNTID VARCHAR(50) NOT NULL,
    PERIOD_YEAR INTEGER NOT NULL,
    PERIOD_MONTH INTEGER NOT NULL,
    TOTAL_CREDITS DECIMAL(15,2) DEFAULT 0.00,
    PRIMARY KEY (ACCOUNTID, PERIOD_YEAR, PERIOD_MONTH)
);
```

## 🧪 Testing

### Python Tests

```bash
# Run existing tests
python -m pytest tests/

# Add new tests in tests/ directory
tests/
├── test_transaction_generator.py
├── test_overdraft_prevention.py
└── test_credit_schedule.py
```

### Snowflake Tests

```sql
-- Test stored procedure
@tests/test_snowflake_procedures.sql

-- Verify no overdrafts
SELECT COUNT(*) FROM VW_CURRENT_MONTH_BALANCES
WHERE ACCOUNT_STATUS = 'OVERDRAWN';
-- Should return 0
```

## 📚 Documentation

When adding features:

1. **Update README files**:
   - Main README.md
   - python/README.md
   - snowflake/README.md

2. **Add examples** in appropriate directories:
   - python/examples/
   - snowflake/examples/
   - docs/examples/

3. **Update CHANGELOG.md** with your changes

4. **Add inline comments** for complex logic

## 🔄 Commit Message Format

Use conventional commits format:

```
type(scope): brief description

Detailed explanation if needed

Fixes #issue-number
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples**:
```
feat(python): Add support for weekly direct deposits
fix(snowflake): Correct overdraft calculation logic
docs(readme): Update installation instructions
```

## 🎯 Pull Request Guidelines

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests added/updated and passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No merge conflicts
- [ ] Descriptive PR title and description
- [ ] Linked related issues

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
How to test these changes

## Related Issues
Fixes #123, Related to #456

## Screenshots (if applicable)
```

## 🐛 Bug Reports

Good bug reports should include:

1. **Clear title**: "Overdraft prevention fails for business accounts"
2. **Environment**: Python 3.9, Snowflake Enterprise Edition
3. **Steps to reproduce**:
   ```bash
   python transaction_simulator.py --account-ids BUS-001 --account-types business ...
   ```
4. **Expected behavior**: "Debits should not exceed 80% of credits"
5. **Actual behavior**: "Account shows negative balance"
6. **Logs/Error messages**: Include relevant output
7. **Possible solution**: If you have ideas

## 💡 Feature Requests

Feature requests should include:

1. **Clear description**: What feature do you want?
2. **Use case**: Why is this feature needed?
3. **Proposed solution**: How should it work?
4. **Alternatives**: What alternatives have you considered?
5. **Additional context**: Screenshots, examples, etc.

## 🔐 Security

If you discover a security vulnerability:

1. **DO NOT** open a public issue
2. Email the maintainer privately
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

## 📜 Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome diverse perspectives
- Focus on constructive feedback
- Accept responsibility for mistakes
- Prioritize community well-being

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal or political attacks
- Publishing private information
- Unprofessional conduct

## 🎖️ Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Credited in release notes
- Added to contributors list

## 📞 Questions?

- Open an issue with the `question` label
- Check existing documentation
- Review closed issues for similar questions

## 🙏 Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort!

---

**Last Updated**: November 2024
