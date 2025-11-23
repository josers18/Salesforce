-- ============================================================================
-- DEBUG VERSION: Stored Procedure with Verbose Output
-- ============================================================================
-- This version provides detailed diagnostic messages
-- Use this to troubleshoot issues, then switch back to the production version
-- ============================================================================

CREATE OR REPLACE PROCEDURE generate_daily_transactions_debug(
    TRANSACTIONS_PER_ACCOUNT INTEGER
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'numpy')
HANDLER = 'generate_transactions_debug'
AS
$$
import pandas as pd
import numpy as np
import uuid
from datetime import datetime, timedelta
import random
from snowflake.snowpark import Session

def generate_transactions_debug(session, transactions_per_account):
    """Debug version with verbose output"""
    
    messages = []
    
    try:
        # Step 1: Load accounts
        messages.append("Step 1: Loading accounts...")
        
        config_query = """
        SELECT 
            a.ACCOUNTID,
            a.SFACCOUNTID,
            a.CONTACTID,
            a.ACCOUNTTYPE,
            a.ACTIVE,
            c.DIRECT_DEPOSIT_AMOUNT,
            c.BONUS_AMOUNT,
            c.DD_DAY_1,
            c.DD_DAY_2,
            c.BONUS_FREQUENCY
        FROM FINS.PUBLIC.FINANCIAL_TRANSACTION_ACCOUNTS a
        JOIN FINS.PUBLIC.ACCOUNT_CREDIT_CONFIG c ON a.ACCOUNTID = c.ACCOUNTID
        WHERE a.ACTIVE = TRUE AND c.ACTIVE = TRUE
        """
        
        accounts_df = session.sql(config_query).to_pandas()
        messages.append(f"Found {len(accounts_df)} active accounts with credit config")
        
        if len(accounts_df) == 0:
            return "; ".join(messages) + "; ERROR: No active accounts found. Run troubleshoot_no_transactions.sql"
        
        # Show account IDs
        account_ids = accounts_df['ACCOUNTID'].tolist()
        messages.append(f"Account IDs: {', '.join(account_ids[:5])}" + ("..." if len(account_ids) > 5 else ""))
        
        # Step 2: Load MCC data
        messages.append("Step 2: Loading MCC data...")
        mcc_df = session.table("FINS.PUBLIC.MCC").to_pandas()
        messages.append(f"Found {len(mcc_df)} MCC records")
        
        if len(mcc_df) == 0:
            return "; ".join(messages) + "; ERROR: MCC table is empty"
        
        # Standardize column names
        mcc_df.columns = [col.strip().upper() for col in mcc_df.columns]
        
        # Check for debit transactions
        debit_mccs = mcc_df[mcc_df['TRAN_TYPE'] == 'Debit']
        messages.append(f"Found {len(debit_mccs)} debit MCCs")
        
        if len(debit_mccs) == 0:
            return "; ".join(messages) + "; ERROR: No debit MCCs found. Check TRAN_TYPE column values"
        
        # Check for credit MCCs
        dd_mccs = mcc_df[mcc_df['MCC'] == 9961]
        bonus_mccs = mcc_df[mcc_df['MCC'] == 9963]
        messages.append(f"Found {len(dd_mccs)} direct deposit MCCs (9961)")
        messages.append(f"Found {len(bonus_mccs)} bonus MCCs (9963)")
        
        # Step 3: Check today's date
        today = datetime.now()
        current_day = today.day
        current_month = today.month
        
        messages.append(f"Today is {today.strftime('%Y-%m-%d')} (Day {current_day} of month)")
        
        is_dd_day = current_day in [1, 15]
        is_bonus_day = current_day == 1 and current_month in [1, 4, 7, 10]
        
        messages.append(f"Is Direct Deposit Day: {is_dd_day}")
        messages.append(f"Is Quarterly Bonus Day: {is_bonus_day}")
        
        # Step 4: Generate transactions
        transactions = []
        
        # Generate credits if applicable
        credits_generated = 0
        if is_dd_day and len(dd_mccs) > 0:
            messages.append("Generating direct deposits...")
            dd_mcc = dd_mccs.iloc[0]
            for _, account in accounts_df.iterrows():
                dd_amount = float(account['DIRECT_DEPOSIT_AMOUNT'])
                trans_date = today.replace(hour=9, minute=0, second=0, microsecond=0)
                
                transactions.append({
                    'ACCOUNTID': account['ACCOUNTID'],
                    'TRANSACTIONID': str(uuid.uuid4()),
                    'POSTINGDATE': trans_date,
                    'TRANSACTIONDATE': trans_date,
                    'AMOUNT': dd_amount,
                    'DESCRIPTION': 'Direct Deposit',
                    'TRANSACTION_CATEGORY': dd_mcc['TRAN_CATEGORY'],
                    'MCC': int(dd_mcc['MCC']),
                    'MCC_DESCRIPTION': dd_mcc['DESCRIPTION'],
                    'TRANSACTION_STATUS': 'Posted',
                    'CURRENCY': 'USD',
                    'TRANSACTION_TYPE': 'Credit',
                    'SOURCE_TRANSACTION_TYPE': 'Credit',
                    'DATA_DATE': today,
                    'SFACCOUNTID': account['SFACCOUNTID'],
                    'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                    'ACCOUNT_TYPE': account['ACCOUNTTYPE']
                })
                credits_generated += 1
            
            messages.append(f"Generated {credits_generated} direct deposits")
        
        if is_bonus_day and len(bonus_mccs) > 0:
            messages.append("Generating quarterly bonuses...")
            bonus_mcc = bonus_mccs.iloc[0]
            bonuses_generated = 0
            
            for _, account in accounts_df.iterrows():
                bonus_amount = float(account['BONUS_AMOUNT'])
                trans_date = today.replace(hour=17, minute=0, second=0, microsecond=0)
                quarter = (current_month - 1) // 3 + 1
                
                transactions.append({
                    'ACCOUNTID': account['ACCOUNTID'],
                    'TRANSACTIONID': str(uuid.uuid4()),
                    'POSTINGDATE': trans_date,
                    'TRANSACTIONDATE': trans_date,
                    'AMOUNT': bonus_amount,
                    'DESCRIPTION': f'Q{quarter} Bonus',
                    'TRANSACTION_CATEGORY': bonus_mcc['TRAN_CATEGORY'],
                    'MCC': int(bonus_mcc['MCC']),
                    'MCC_DESCRIPTION': bonus_mcc['DESCRIPTION'],
                    'TRANSACTION_STATUS': 'Posted',
                    'CURRENCY': 'USD',
                    'TRANSACTION_TYPE': 'Credit',
                    'SOURCE_TRANSACTION_TYPE': 'Credit',
                    'DATA_DATE': today,
                    'SFACCOUNTID': account['SFACCOUNTID'],
                    'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                    'ACCOUNT_TYPE': account['ACCOUNTTYPE']
                })
                bonuses_generated += 1
            
            messages.append(f"Generated {bonuses_generated} bonuses")
        
        # Generate debits
        messages.append(f"Generating up to {transactions_per_account} debit transactions per account...")
        debits_generated = 0
        
        for _, account in accounts_df.iterrows():
            account_id = account['ACCOUNTID']
            
            for i in range(min(transactions_per_account, len(debit_mccs))):
                # Simple debit generation (no balance checking for debug)
                mcc_row = debit_mccs.sample(n=1).iloc[0]
                
                random_seconds = random.randint(0, 86399)
                trans_date = today.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(seconds=random_seconds)
                
                amount = round(random.uniform(10, 300), 2)
                
                transactions.append({
                    'ACCOUNTID': account_id,
                    'TRANSACTIONID': str(uuid.uuid4()),
                    'POSTINGDATE': trans_date,
                    'TRANSACTIONDATE': trans_date,
                    'AMOUNT': amount,
                    'DESCRIPTION': mcc_row['DESCRIPTION'],
                    'TRANSACTION_CATEGORY': mcc_row['TRAN_CATEGORY'],
                    'MCC': int(mcc_row['MCC']),
                    'MCC_DESCRIPTION': mcc_row['DESCRIPTION'],
                    'TRANSACTION_STATUS': 'Posted',
                    'CURRENCY': 'USD',
                    'TRANSACTION_TYPE': 'Debit',
                    'SOURCE_TRANSACTION_TYPE': 'Debit',
                    'DATA_DATE': today,
                    'SFACCOUNTID': account['SFACCOUNTID'],
                    'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                    'ACCOUNT_TYPE': account['ACCOUNTTYPE']
                })
                debits_generated += 1
        
        messages.append(f"Generated {debits_generated} debit transactions")
        
        if len(transactions) == 0:
            return "; ".join(messages) + "; WARNING: No transactions generated!"
        
        # Convert to DataFrame
        df = pd.DataFrame(transactions)
        messages.append(f"Created DataFrame with {len(df)} total transactions")
        
        # Ensure column order
        column_order = [
            'ACCOUNTID', 'TRANSACTIONID', 'POSTINGDATE', 'TRANSACTIONDATE',
            'AMOUNT', 'DESCRIPTION', 'TRANSACTION_CATEGORY', 'MCC',
            'MCC_DESCRIPTION', 'TRANSACTION_STATUS', 'CURRENCY',
            'TRANSACTION_TYPE', 'SOURCE_TRANSACTION_TYPE', 'DATA_DATE',
            'SFACCOUNTID', 'CONTACTID', 'ACCOUNT_TYPE'
        ]
        df = df[column_order]
        
        # Convert dates
        date_columns = ['POSTINGDATE', 'TRANSACTIONDATE', 'DATA_DATE']
        for col in date_columns:
            if col in df.columns:
                df[col] = pd.to_datetime(df[col]).dt.tz_localize(None)
        
        messages.append("Writing to FINANCIAL_TRANSACTIONS table...")
        
        # Write to table
        snowpark_df = session.create_dataframe(df)
        snowpark_df.write.mode("append").save_as_table("FINANCIAL_TRANSACTIONS")
        
        messages.append(f"SUCCESS! Wrote {len(df)} transactions to database")
        
        return "; ".join(messages)
        
    except Exception as e:
        return "; ".join(messages) + f"; ERROR: {str(e)}"

$$;

-- ============================================================================
-- How to use the debug version
-- ============================================================================

-- Call the debug version
CALL generate_daily_transactions_debug(5);

-- The return message will show you exactly what happened at each step
-- Example output:
-- "Step 1: Loading accounts...; Found 10 active accounts with credit config; 
--  Account IDs: ACC-001, ACC-002, ACC-003...; Step 2: Loading MCC data...; 
--  Found 450 MCC records; Found 380 debit MCCs; ..."

-- Once you identify and fix the issue, use the production version:
-- CALL generate_daily_transactions(10);
