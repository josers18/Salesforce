#!/bin/bash
# Financial Transaction Generator - Repository Setup Script
# This script organizes all files into the proper directory structure

echo "========================================="
echo "Financial Transaction Generator"
echo "Repository Setup Script"
echo "========================================="
echo ""

# Get the base directory (where this script is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo "Setting up repository structure..."
echo ""

# Create directory structure
echo "Creating directories..."
mkdir -p python/examples
mkdir -p python/config
mkdir -p snowflake/setup
mkdir -p snowflake/troubleshooting
mkdir -p snowflake/examples
mkdir -p data
mkdir -p docs/architecture
mkdir -p docs/examples
mkdir -p tests
mkdir -p output

echo "✓ Directories created"
echo ""

# Move Python files
echo "Organizing Python files..."
if [ -f "transaction_simulator.py" ]; then
    mv transaction_simulator.py python/
    echo "✓ Moved transaction_simulator.py"
fi

# Move Snowflake setup files
echo "Organizing Snowflake setup files..."
for file in 01_create_balance_tables.sql 02_populate_credit_config.sql 05_stored_procedure_FIXED.sql; do
    if [ -f "$file" ]; then
        mv "$file" snowflake/setup/
        echo "✓ Moved $file"
    fi
done

# Move Snowflake troubleshooting files
echo "Organizing Snowflake troubleshooting files..."
for file in troubleshoot_no_transactions.sql quick_fix_no_transactions.sql 04_stored_procedure_debug_version.sql; do
    if [ -f "$file" ]; then
        mv "$file" snowflake/troubleshooting/
        echo "✓ Moved $file"
    fi
done

# Move documentation files
echo "Organizing documentation files..."
for file in QUICK_REFERENCE.md TROUBLESHOOTING.md MIGRATION_GUIDE.md; do
    if [ -f "$file" ]; then
        mv "$file" docs/
        echo "✓ Moved $file"
    fi
done

# Copy example files to examples directory (if they were generated)
if [ -f "python/examples/generate_year.sh" ]; then
    chmod +x python/examples/generate_year.sh
    echo "✓ Made generate_year.sh executable"
fi

echo ""
echo "========================================="
echo "Directory Structure Created:"
echo "========================================="
echo ""
echo "financial-transaction-generator/"
echo "├── README.md"
echo "├── LICENSE"
echo "├── .gitignore"
echo "├── requirements.txt"
echo "├── CONTRIBUTING.md"
echo "├── CHANGELOG.md"
echo "│"
echo "├── python/"
echo "│   ├── README.md"
echo "│   ├── transaction_simulator.py"
echo "│   ├── config/"
echo "│   └── examples/"
echo "│       └── generate_year.sh"
echo "│"
echo "├── snowflake/"
echo "│   ├── README.md"
echo "│   ├── setup/"
echo "│   │   ├── 01_create_balance_tables.sql"
echo "│   │   ├── 02_populate_credit_config.sql"
echo "│   │   └── 05_stored_procedure_FIXED.sql"
echo "│   ├── troubleshooting/"
echo "│   │   ├── troubleshoot_no_transactions.sql"
echo "│   │   ├── quick_fix_no_transactions.sql"
echo "│   │   └── 04_stored_procedure_debug_version.sql"
echo "│   └── examples/"
echo "│       ├── daily_task_setup.sql"
echo "│       └── balance_queries.sql"
echo "│"
echo "├── data/"
echo "│   ├── README.md"
echo "│   └── MCCs.csv (YOU NEED TO ADD THIS)"
echo "│"
echo "├── docs/"
echo "│   ├── README.md"
echo "│   ├── QUICK_REFERENCE.md"
echo "│   ├── TROUBLESHOOTING.md"
echo "│   ├── MIGRATION_GUIDE.md"
echo "│   ├── architecture/"
echo "│   └── examples/"
echo "│"
echo "├── tests/"
echo "└── output/"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo ""
echo "1. Add your MCCs.csv file to data/ directory"
echo "   See data/README.md for format requirements"
echo ""
echo "2. Initialize git repository:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo ""
echo "3. Create GitHub repository and push:"
echo "   git remote add origin https://github.com/yourusername/financial-transaction-generator.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "4. Test Python script:"
echo "   cd python"
echo "   python transaction_simulator.py --help"
echo ""
echo "5. Deploy Snowflake solution:"
echo "   @snowflake/setup/01_create_balance_tables.sql"
echo "   @snowflake/setup/02_populate_credit_config.sql"
echo "   @snowflake/setup/05_stored_procedure_FIXED.sql"
echo ""
echo "========================================="
echo "Setup Complete! 🎉"
echo "========================================="
