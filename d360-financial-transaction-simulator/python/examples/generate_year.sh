#!/bin/bash
# Example: Generate full year of transactions for multiple accounts

# Configuration
MCC_FILE="../data/MCCs.csv"
START_DATE="2024-01-01"
END_DATE="2024-12-31"
OUTPUT_DIR="output"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate transactions for personal account
echo "Generating transactions for personal account..."
python transaction_simulator.py \
  --mcc-file "$MCC_FILE" \
  --account-ids "PERS-2024-001" \
  --account-types personal \
  --sf-account-ids "SF-PERS-001" \
  --contact-ids "CON-PERS-001" \
  --start-date "$START_DATE" \
  --end-date "$END_DATE" \
  --num-records 500 \
  --direct-deposit-amount 3000 \
  --bonus-amount 500 \
  --output-file "$OUTPUT_DIR/personal_2024.csv"

# Generate transactions for business account
echo "Generating transactions for business account..."
python transaction_simulator.py \
  --mcc-file "$MCC_FILE" \
  --account-ids "BUS-2024-001" \
  --account-types business \
  --sf-account-ids "SF-BUS-001" \
  --contact-ids "CON-BUS-001" \
  --start-date "$START_DATE" \
  --end-date "$END_DATE" \
  --num-records 800 \
  --direct-deposit-amount 7500 \
  --bonus-amount 1000 \
  --output-file "$OUTPUT_DIR/business_2024.csv"

# Generate transactions for mixed accounts
echo "Generating transactions for mixed accounts..."
python transaction_simulator.py \
  --mcc-file "$MCC_FILE" \
  --account-ids "ACC-001" "ACC-002" "ACC-003" \
  --account-types personal business personal \
  --sf-account-ids "SF-001" "SF-002" "SF-003" \
  --contact-ids "CON-001" "CON-002" "CON-003" \
  --start-date "$START_DATE" \
  --end-date "$END_DATE" \
  --num-records 1500 \
  --output-file "$OUTPUT_DIR/mixed_accounts_2024.csv"

echo "Done! Check $OUTPUT_DIR directory for output files."
