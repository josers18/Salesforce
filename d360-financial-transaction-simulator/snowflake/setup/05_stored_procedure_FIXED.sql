-- ============================================================================
-- FIXED STORED PROCEDURE - Handles accounts without credits deposited yet
-- ============================================================================
-- This version uses configured credit amounts to calculate available spending
-- even before direct deposits are generated this month
-- ============================================================================

CREATE OR REPLACE PROCEDURE generate_daily_transactions(
    TRANSACTIONS_PER_ACCOUNT INTEGER
)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python', 'pandas', 'numpy')
HANDLER = 'generate_transactions'
AS
$$
import pandas as pd
import numpy as np
import uuid
from datetime import datetime, timedelta
import random
from snowflake.snowpark import Session

def generate_merchant_name(mcc_description):
    """Generate merchant name from MCC description"""
    if any(brand in str(mcc_description).upper() for brand in ['HILTON', 'MARRIOTT', 'SHERATON', 'HERTZ', 'AVIS', 'UNITED AIRLINES', 'AMERICAN AIRLINES']):
        return mcc_description
    return mcc_description

def generate_amount_for_mcc(mcc_row, account_type='personal'):
    """Generate realistic amount based on MCC and account type"""
    category = str(mcc_row.get('CATEGORY', mcc_row.get('category', '')))
    
    amount_ranges = {
        'Retail outlets': (10, 500),
        'Restaurants': (15, 150),
        'Fast Food': (5, 30),
        'Hotels': (80, 500),
        'Airlines': (150, 1500),
        'Gas Stations': (20, 100),
        'Utilities': (50, 300),
        'Transportation': (5, 200),
        'Amusement and entertainment': (10, 200),
        'Professional services and membership organizations': (50, 500),
        'Business services': (30, 400),
        'Repair services': (40, 300),
        'Government services': (20, 500),
        'Agricultural services': (50, 300),
        'Contracted services': (100, 1000),
    }
    
    min_amt, max_amt = amount_ranges.get(category, (10, 300))
    
    # Adjust for business accounts
    if account_type.lower() == 'business':
        if category in ['Business services', 'Professional services and membership organizations', 'Contracted services']:
            multiplier = 2.5
        elif category in ['Utilities', 'Hotels', 'Airlines']:
            multiplier = 1.8
        elif category in ['Repair services', 'Transportation']:
            multiplier = 1.5
        else:
            multiplier = 1.3
        min_amt *= multiplier
        max_amt *= multiplier
    
    return round(random.uniform(min_amt, max_amt), 2)

def filter_mccs_for_business(mcc_df):
    """Filter MCCs appropriate for business accounts"""
    business_categories = [
        'Business services', 'Professional services and membership organizations',
        'Contracted services', 'Repair services', 'Agricultural services',
        'Government services'
    ]
    
    business_tran_categories = [
        'Business Services', 'Bills & Utilities', 'Shopping',
        'Auto & Transport', 'Fees & Charges'
    ]
    
    category_col = 'CATEGORY' if 'CATEGORY' in mcc_df.columns else 'category'
    tran_cat_col = 'TRAN_CATEGORY' if 'TRAN_CATEGORY' in mcc_df.columns else 'Tran_category'
    
    exclude_categories = ['Amusement and entertainment', 'Fast Food']
    exclude_tran_categories = ['Entertainment']
    
    filtered = mcc_df[
        (mcc_df[category_col].isin(business_categories) | 
         mcc_df[tran_cat_col].isin(business_tran_categories)) &
        ~mcc_df[category_col].isin(exclude_categories) &
        ~mcc_df[tran_cat_col].isin(exclude_tran_categories)
    ]
    
    return filtered

def is_quarterly_bonus_day(date):
    """Check if date is a quarterly bonus day"""
    return date.day == 1 and date.month in [1, 4, 7, 10]

def update_balance_tracker(session, account_id, year, month, credits, debits, txn_count):
    """Update the balance tracker table"""
    
    query = f"""
    SELECT COUNT(*) as cnt 
    FROM FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER 
    WHERE ACCOUNTID = '{account_id}' 
    AND PERIOD_YEAR = {year} 
    AND PERIOD_MONTH = {month}
    """
    result = session.sql(query).collect()
    exists = result[0]['CNT'] > 0
    
    if exists:
        update_sql = f"""
        UPDATE FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER
        SET 
            TOTAL_CREDITS = TOTAL_CREDITS + {credits},
            TOTAL_DEBITS = TOTAL_DEBITS + {debits},
            NET_BALANCE = OPENING_BALANCE + (TOTAL_CREDITS + {credits}) - (TOTAL_DEBITS + {debits}),
            AVAILABLE_CREDIT = (TOTAL_CREDITS + {credits}) * 0.80,
            CREDIT_UTILIZATION_PCT = CASE 
                WHEN (TOTAL_CREDITS + {credits}) * 0.80 > 0 
                THEN ((TOTAL_DEBITS + {debits}) / ((TOTAL_CREDITS + {credits}) * 0.80)) * 100 
                ELSE 0 
            END,
            TRANSACTION_COUNT = TRANSACTION_COUNT + {txn_count},
            LAST_TRANSACTION_DATE = CURRENT_TIMESTAMP(),
            LAST_UPDATED = CURRENT_TIMESTAMP()
        WHERE ACCOUNTID = '{account_id}'
        AND PERIOD_YEAR = {year}
        AND PERIOD_MONTH = {month}
        """
    else:
        period_start = f"{year}-{month:02d}-01"
        if month == 12:
            next_month = f"{year+1}-01-01"
        else:
            next_month = f"{year}-{month+1:02d}-01"
        
        insert_sql = f"""
        INSERT INTO FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER (
            ACCOUNTID, PERIOD_YEAR, PERIOD_MONTH, PERIOD_START_DATE, PERIOD_END_DATE,
            OPENING_BALANCE, TOTAL_CREDITS, TOTAL_DEBITS, NET_BALANCE, AVAILABLE_CREDIT,
            CREDIT_UTILIZATION_PCT, TRANSACTION_COUNT, LAST_TRANSACTION_DATE
        ) VALUES (
            '{account_id}', {year}, {month}, 
            '{period_start}', DATEADD(day, -1, '{next_month}'),
            0, {credits}, {debits}, {credits - debits}, 
            CASE WHEN {credits} > 0 THEN {credits * 0.80} ELSE 0 END,
            CASE WHEN {credits} > 0 THEN ({debits} / ({credits * 0.80}) * 100) ELSE 0 END,
            {txn_count}, CURRENT_TIMESTAMP()
        )
        """
        update_sql = insert_sql
    
    session.sql(update_sql).collect()

def generate_transactions(session, transactions_per_account):
    """Main transaction generation function with balance tracking"""
    
    # Load active accounts and their credit configuration
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
    
    if len(accounts_df) == 0:
        return "No active accounts found with credit configuration"
    
    accounts_df.columns = [col.strip().upper() for col in accounts_df.columns]
    
    # Load MCC data
    mcc_df = session.table("FINS.PUBLIC.MCC").to_pandas()
    mcc_df.columns = [col.strip().upper() for col in mcc_df.columns]
    
    business_mccs = filter_mccs_for_business(mcc_df)
    
    dd_mccs = mcc_df[mcc_df['MCC'] == 9961]
    bonus_mccs = mcc_df[mcc_df['MCC'] == 9963]
    
    transactions = []
    today = datetime.now()
    data_date = today
    current_year = today.year
    current_month = today.month
    current_day = today.day
    
    total_credits = 0
    total_debits = 0
    personal_count = 0
    business_count = 0
    account_credits = {}
    account_debits = {}
    
    # ========================================================================
    # STEP 1: Calculate expected monthly credits for each account
    # This allows spending even before DDs are deposited
    # ========================================================================
    
    for _, account in accounts_df.iterrows():
        account_id = account['ACCOUNTID']
        dd_amount = float(account['DIRECT_DEPOSIT_AMOUNT'])
        bonus_amount = float(account['BONUS_AMOUNT'])
        
        # Expected monthly credits = 2 DDs per month
        expected_monthly_credits = dd_amount * 2
        
        # Add quarterly bonus if this is a bonus quarter
        if is_quarterly_bonus_day(today):
            expected_monthly_credits += bonus_amount
        
        account_credits[account_id] = expected_monthly_credits
        account_debits[account_id] = 0.0
    
    # ========================================================================
    # STEP 2: Generate Credits (Direct Deposits and Bonuses)
    # ========================================================================
    
    for _, account in accounts_df.iterrows():
        account_id = account['ACCOUNTID']
        account_type = account['ACCOUNTTYPE']
        dd_amount = float(account['DIRECT_DEPOSIT_AMOUNT'])
        bonus_amount = float(account['BONUS_AMOUNT'])
        dd_day_1 = account['DD_DAY_1']
        dd_day_2 = account['DD_DAY_2']
        
        # Generate Direct Deposits (if today is a DD day)
        if len(dd_mccs) > 0:
            dd_mcc = dd_mccs.iloc[0]
            
            if current_day == dd_day_1 or current_day == dd_day_2:
                trans_date = today.replace(hour=9, minute=0, second=0, microsecond=0)
                deposit_desc = 'Business Revenue Deposit' if account_type == 'Business' else dd_mcc['DESCRIPTION']
                
                transactions.append({
                    'ACCOUNTID': account_id,
                    'TRANSACTIONID': str(uuid.uuid4()),
                    'POSTINGDATE': trans_date,
                    'TRANSACTIONDATE': trans_date,
                    'AMOUNT': dd_amount,
                    'DESCRIPTION': deposit_desc,
                    'TRANSACTION_CATEGORY': dd_mcc['TRAN_CATEGORY'],
                    'MCC': int(dd_mcc['MCC']),
                    'MCC_DESCRIPTION': dd_mcc['DESCRIPTION'],
                    'TRANSACTION_STATUS': 'Posted',
                    'CURRENCY': 'USD',
                    'TRANSACTION_TYPE': dd_mcc['TRAN_TYPE'],
                    'SOURCE_TRANSACTION_TYPE': dd_mcc['TRAN_TYPE'],
                    'DATA_DATE': data_date,
                    'SFACCOUNTID': account['SFACCOUNTID'],
                    'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                    'ACCOUNT_TYPE': account_type
                })
                
                total_credits += dd_amount
        
        # Generate Quarterly Bonuses (if today is bonus day)
        if len(bonus_mccs) > 0 and is_quarterly_bonus_day(today):
            bonus_mcc = bonus_mccs.iloc[0]
            trans_date = today.replace(hour=17, minute=0, second=0, microsecond=0)
            quarter = (current_month - 1) // 3 + 1
            bonus_desc = f'Q{quarter} Bonus - {bonus_mcc["DESCRIPTION"]}'
            
            transactions.append({
                'ACCOUNTID': account_id,
                'TRANSACTIONID': str(uuid.uuid4()),
                'POSTINGDATE': trans_date,
                'TRANSACTIONDATE': trans_date,
                'AMOUNT': bonus_amount,
                'DESCRIPTION': bonus_desc,
                'TRANSACTION_CATEGORY': bonus_mcc['TRAN_CATEGORY'],
                'MCC': int(bonus_mcc['MCC']),
                'MCC_DESCRIPTION': bonus_mcc['DESCRIPTION'],
                'TRANSACTION_STATUS': 'Posted',
                'CURRENCY': 'USD',
                'TRANSACTION_TYPE': bonus_mcc['TRAN_TYPE'],
                'SOURCE_TRANSACTION_TYPE': bonus_mcc['TRAN_TYPE'],
                'DATA_DATE': data_date,
                'SFACCOUNTID': account['SFACCOUNTID'],
                'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                'ACCOUNT_TYPE': account_type
            })
            
            total_credits += bonus_amount
    
    # ========================================================================
    # STEP 3: Get existing balance tracker data for this month
    # ========================================================================
    
    for account_id in account_credits.keys():
        balance_query = f"""
        SELECT 
            TOTAL_CREDITS,
            TOTAL_DEBITS
        FROM FINS.PUBLIC.ACCOUNT_BALANCE_TRACKER
        WHERE ACCOUNTID = '{account_id}'
        AND PERIOD_YEAR = {current_year}
        AND PERIOD_MONTH = {current_month}
        """
        
        try:
            balance_result = session.sql(balance_query).collect()
            
            if len(balance_result) > 0:
                existing_debits = float(balance_result[0]['TOTAL_DEBITS'])
                account_debits[account_id] = existing_debits
        except:
            pass  # No existing balance record, start from 0
    
    # ========================================================================
    # STEP 4: Calculate max debit per account 
    # Use expected credits (not just deposited credits)
    # ========================================================================
    
    max_debit_per_account = {
        acc_id: credits * 0.80 
        for acc_id, credits in account_credits.items()
    }
    
    # ========================================================================
    # STEP 5: Generate Debit Transactions (with overdraft prevention)
    # ========================================================================
    
    for _, account in accounts_df.iterrows():
        account_id = account['ACCOUNTID']
        account_type = account['ACCOUNTTYPE']
        
        mcc_pool = business_mccs if account_type == 'Business' else mcc_df
        debit_mccs = mcc_pool[mcc_pool['TRAN_TYPE'] == 'Debit']
        
        if len(debit_mccs) == 0:
            continue
        
        transactions_created = 0
        attempts = 0
        max_attempts = transactions_per_account * 3
        
        while transactions_created < transactions_per_account and attempts < max_attempts:
            attempts += 1
            
            mcc_row = debit_mccs.sample(n=1).iloc[0]
            
            random_seconds = random.randint(0, 86399)
            trans_date = today.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(seconds=random_seconds)
            
            amount = generate_amount_for_mcc(mcc_row, account_type)
            
            # Check if adding this debit would exceed budget
            if account_debits[account_id] + amount > max_debit_per_account[account_id]:
                remaining_budget = max_debit_per_account[account_id] - account_debits[account_id]
                if remaining_budget > 10:
                    amount = round(random.uniform(5, min(amount, remaining_budget)), 2)
                else:
                    continue
            
            account_debits[account_id] += amount
            total_debits += amount
            
            transactions.append({
                'ACCOUNTID': account_id,
                'TRANSACTIONID': str(uuid.uuid4()),
                'POSTINGDATE': trans_date,
                'TRANSACTIONDATE': trans_date,
                'AMOUNT': amount,
                'DESCRIPTION': generate_merchant_name(mcc_row['DESCRIPTION']),
                'TRANSACTION_CATEGORY': mcc_row['TRAN_CATEGORY'],
                'MCC': int(mcc_row['MCC']),
                'MCC_DESCRIPTION': mcc_row['DESCRIPTION'],
                'TRANSACTION_STATUS': 'Posted',
                'CURRENCY': 'USD',
                'TRANSACTION_TYPE': mcc_row['TRAN_TYPE'],
                'SOURCE_TRANSACTION_TYPE': mcc_row['TRAN_TYPE'],
                'DATA_DATE': data_date,
                'SFACCOUNTID': account['SFACCOUNTID'],
                'CONTACTID': account['CONTACTID'] if account['CONTACTID'] else '',
                'ACCOUNT_TYPE': account_type
            })
            
            transactions_created += 1
        
        if account_type == 'Business':
            business_count += transactions_created
        else:
            personal_count += transactions_created
    
    # ========================================================================
    # STEP 6: Save transactions and update balance tracker
    # ========================================================================
    
    if len(transactions) == 0:
        return "No transactions generated"
    
    df = pd.DataFrame(transactions)
    
    column_order = [
        'ACCOUNTID', 'TRANSACTIONID', 'POSTINGDATE', 'TRANSACTIONDATE',
        'AMOUNT', 'DESCRIPTION', 'TRANSACTION_CATEGORY', 'MCC',
        'MCC_DESCRIPTION', 'TRANSACTION_STATUS', 'CURRENCY',
        'TRANSACTION_TYPE', 'SOURCE_TRANSACTION_TYPE', 'DATA_DATE',
        'SFACCOUNTID', 'CONTACTID', 'ACCOUNT_TYPE'
    ]
    df = df[column_order]
    
    date_columns = ['POSTINGDATE', 'TRANSACTIONDATE', 'DATA_DATE']
    for col in date_columns:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col]).dt.tz_localize(None)
    
    snowpark_df = session.create_dataframe(df)
    snowpark_df.write.mode("append").save_as_table("FINANCIAL_TRANSACTIONS")
    
    # Update balance tracker
    for account_id in account_credits.keys():
        new_credits = sum(t['AMOUNT'] for t in transactions 
                         if t['ACCOUNTID'] == account_id and t['TRANSACTION_TYPE'] == 'Credit')
        new_debits = sum(t['AMOUNT'] for t in transactions 
                        if t['ACCOUNTID'] == account_id and t['TRANSACTION_TYPE'] == 'Debit')
        txn_count = len([t for t in transactions if t['ACCOUNTID'] == account_id])
        
        if new_credits > 0 or new_debits > 0:
            update_balance_tracker(session, account_id, current_year, current_month, 
                                 new_credits, new_debits, txn_count)
    
    net_balance = total_credits - total_debits
    return f"Successfully generated {len(transactions)} transactions from {len(accounts_df)} active accounts ({personal_count} personal, {business_count} business). Credits: ${total_credits:,.2f}, Debits: ${total_debits:,.2f}, Net: ${net_balance:,.2f}"

$$;
