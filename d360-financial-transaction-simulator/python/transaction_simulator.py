"""
Financial Transaction Simulator
Generates realistic financial transactions based on MCC (Merchant Category Code) data.
"""

import pandas as pd
import numpy as np
import uuid
from datetime import datetime, timedelta
import random
import argparse
import sys


class TransactionSimulator:
    """Simulate financial transactions with realistic patterns."""
    
    def __init__(self, mcc_file_path):
        """
        Initialize the simulator with MCC data.
        
        Args:
            mcc_file_path: Path to the MCC CSV file
        """
        self.mcc_data = pd.read_csv(mcc_file_path)
        # Clean up column names (remove trailing spaces)
        self.mcc_data.columns = self.mcc_data.columns.str.strip()
        
        # Separate direct deposits and regular transactions
        self.direct_deposit_mcc = self.mcc_data[self.mcc_data['mcc'] == 9961].iloc[0] if 9961 in self.mcc_data['mcc'].values else None
        self.regular_mccs = self.mcc_data[self.mcc_data['mcc'] != 9961]
        
        # Define business-focused categories (higher probability for business accounts)
        self.business_categories = [
            'Business services', 'Business Services',
            'Professional services and membership organizations',
            'Contracted services',
            'Repair services',
            'Agricultural services',
            'Government services'
        ]
        
        # Define business-focused transaction categories
        self.business_tran_categories = [
            'Business Services',
            'Bills & Utilities',
            'Shopping',  # Office supplies, equipment
            'Auto & Transport',  # Business travel
            'Fees & Charges'
        ]
        
        # Personal categories (lower probability for business accounts)
        self.personal_heavy_categories = [
            'Restaurants',
            'Fast Food',
            'Amusement and entertainment',
            'Retail outlets'  # General shopping
        ]
    
    def get_filtered_mccs(self, account_type):
        """
        Get MCC list filtered by account type.
        
        Args:
            account_type: 'personal' or 'business'
            
        Returns:
            Filtered MCC dataframe
        """
        if account_type.lower() == 'business':
            # For business accounts, heavily weight business-appropriate categories
            # 70% business transactions, 30% general
            business_mccs = self.regular_mccs[
                (self.regular_mccs['category'].isin(self.business_categories)) |
                (self.regular_mccs['Tran_category'].isin(self.business_tran_categories))
            ]
            
            # Exclude pure entertainment and personal services
            exclude_categories = ['Amusement and entertainment', 'Fast Food']
            exclude_tran_categories = ['Entertainment']
            
            business_mccs = business_mccs[
                ~business_mccs['category'].isin(exclude_categories) &
                ~business_mccs['Tran_category'].isin(exclude_tran_categories)
            ]
            
            return business_mccs
        else:
            # Personal accounts can have any transaction
            return self.regular_mccs
        
    def generate_merchant_name(self, mcc_description):
        """
        Generate a merchant name based on MCC description.
        
        Args:
            mcc_description: The MCC description
            
        Returns:
            A merchant name string
        """
        # For specific brands, return as-is
        if any(brand in mcc_description.upper() for brand in ['HILTON', 'MARRIOTT', 'SHERATON', 'HERTZ', 'AVIS', 'UNITED AIRLINES', 'AMERICAN AIRLINES']):
            return mcc_description
        
        # Generic merchants - use description
        return mcc_description
    
    def generate_amount_for_mcc(self, mcc_row, account_type='personal'):
        """
        Generate a realistic amount based on MCC category and account type.
        
        Args:
            mcc_row: Row from MCC dataframe
            account_type: 'personal' or 'business'
            
        Returns:
            Float amount
        """
        category = mcc_row['category']
        tran_type = mcc_row['Tran_Type']
        
        # Base amount ranges by category
        amount_ranges = {
            'Retail outlets': (10, 500),
            'Restaurants': (15, 150),
            'Fast Food': (5, 30),
            'Hotels': (80, 500),
            'Airlines': (150, 1500),
            'Auto Rental': (40, 300),
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
            'Incoming Direct Deposit': (2000, 5000),
            'Incoming Wire Transfer': (500, 10000),
            'ACH Deposit': (100, 3000),
            'ATM Deposit': (20, 500),
            'Branch Deposit': (50, 5000),
            'Zelle Credit': (10, 1000),
            'Interest Income': (0.50, 50),
            'Wire Transfer Fee': (15, 50),
            'Monthly Service Fee': (5, 35),
            'ACH Fee': (1, 5),
            'Loan Fee': (10, 100),
            'Late Fee': (15, 50),
            'Overdraft Fee': (25, 40),
            'NSF Fee': (25, 40),
            'Loan Payment': (200, 2000),
            'Credit Card Payment': (50, 3000),
            'Interest Accrued': (1, 100),
        }
        
        # Get range, default to generic range
        min_amt, max_amt = amount_ranges.get(category, (10, 300))
        
        # Adjust amounts for business accounts
        if account_type.lower() == 'business':
            # Business accounts typically have higher transaction amounts
            multiplier = 1.0
            
            if category in ['Business services', 'Professional services and membership organizations', 
                          'Contracted services', 'Retail outlets']:
                multiplier = 2.5  # Much higher for B2B services
            elif category in ['Utilities', 'Hotels', 'Airlines']:
                multiplier = 1.8  # Higher for business travel/utilities
            elif category in ['Repair services', 'Transportation']:
                multiplier = 1.5
            else:
                multiplier = 1.3  # Slight increase for other categories
            
            min_amt = min_amt * multiplier
            max_amt = max_amt * multiplier
        
        # Generate amount with some variation
        amount = round(random.uniform(min_amt, max_amt), 2)
        
        return amount
    
    def generate_transactions(self, account_ids, start_date, end_date, num_records, 
                            account_types=None, sf_account_ids=None, contact_ids=None,
                            direct_deposit_amount=3000.00, bonus_amount=500.00,
                            include_direct_deposits=True, include_bonuses=True):
        """
        Generate financial transactions.
        
        Args:
            account_ids: List of account IDs (account numbers) or single account ID string
            start_date: Start date for transactions (string or datetime)
            end_date: End date for transactions (string or datetime)
            num_records: Total number of records to generate
            account_types: Dict mapping account_id to 'personal' or 'business', or single type string
                          If None, defaults to 'personal' for all accounts
            sf_account_ids: Dict/list mapping account_id to Salesforce Account ID, or single SF ID
                           If None, defaults to account_ids
            contact_ids: Dict/list mapping account_id to Contact ID, or single Contact ID
                        If None, defaults to empty string
            direct_deposit_amount: Fixed amount for direct deposits (default: 3000.00)
                                  Generated twice per month on 1st and 15th
            bonus_amount: Fixed amount for quarterly bonuses (default: 500.00)
                         Generated on 1st of Jan, Apr, Jul, Oct
            include_direct_deposits: Whether to include direct deposits (default: True)
            include_bonuses: Whether to include quarterly bonuses (default: True)
            
        Returns:
            DataFrame with generated transactions
        """
        # Convert to list if single account ID
        if isinstance(account_ids, str):
            account_ids = [account_ids]
        
        # Handle account_types parameter
        if account_types is None:
            # Default all to personal
            account_types_map = {acc_id: 'personal' for acc_id in account_ids}
        elif isinstance(account_types, str):
            # Single type for all accounts
            account_types_map = {acc_id: account_types.lower() for acc_id in account_ids}
        elif isinstance(account_types, dict):
            # Use provided mapping, default to personal if not specified
            account_types_map = {acc_id: account_types.get(acc_id, 'personal').lower() 
                               for acc_id in account_ids}
        elif isinstance(account_types, list):
            # List of types matching account_ids order
            if len(account_types) != len(account_ids):
                raise ValueError("Length of account_types list must match account_ids list")
            account_types_map = {account_ids[i]: account_types[i].lower() 
                               for i in range(len(account_ids))}
        else:
            raise ValueError("account_types must be None, string, dict, or list")
        
        # Handle sf_account_ids parameter
        if sf_account_ids is None:
            # Default to account_ids
            sf_account_ids_map = {acc_id: acc_id for acc_id in account_ids}
        elif isinstance(sf_account_ids, str):
            # Single SF Account ID for all accounts
            sf_account_ids_map = {acc_id: sf_account_ids for acc_id in account_ids}
        elif isinstance(sf_account_ids, dict):
            # Use provided mapping, default to account_id if not specified
            sf_account_ids_map = {acc_id: sf_account_ids.get(acc_id, acc_id) 
                                 for acc_id in account_ids}
        elif isinstance(sf_account_ids, list):
            # List of SF IDs matching account_ids order
            if len(sf_account_ids) != len(account_ids):
                raise ValueError("Length of sf_account_ids list must match account_ids list")
            sf_account_ids_map = {account_ids[i]: sf_account_ids[i] 
                                 for i in range(len(account_ids))}
        else:
            raise ValueError("sf_account_ids must be None, string, dict, or list")
        
        # Handle contact_ids parameter
        if contact_ids is None:
            # Default to empty string
            contact_ids_map = {acc_id: '' for acc_id in account_ids}
        elif isinstance(contact_ids, str):
            # Single Contact ID for all accounts
            contact_ids_map = {acc_id: contact_ids for acc_id in account_ids}
        elif isinstance(contact_ids, dict):
            # Use provided mapping, default to empty string if not specified
            contact_ids_map = {acc_id: contact_ids.get(acc_id, '') 
                              for acc_id in account_ids}
        elif isinstance(contact_ids, list):
            # List of Contact IDs matching account_ids order
            if len(contact_ids) != len(account_ids):
                raise ValueError("Length of contact_ids list must match account_ids list")
            contact_ids_map = {account_ids[i]: contact_ids[i] if contact_ids[i] else '' 
                              for i in range(len(account_ids))}
        else:
            raise ValueError("contact_ids must be None, string, dict, or list")
        
        # Convert dates to datetime
        if isinstance(start_date, str):
            start_date = pd.to_datetime(start_date)
        if isinstance(end_date, str):
            end_date = pd.to_datetime(end_date)
        
        # Calculate date range in days
        date_range = (end_date - start_date).days
        
        transactions = []
        data_date = datetime.now()
        
        # Calculate how many direct deposits and bonuses to generate per account
        months_in_range = max(1, (end_date.year - start_date.year) * 12 + end_date.month - start_date.month + 1)
        
        # Generate direct deposits (twice a month) and bonuses (once a month) per account
        if include_direct_deposits and self.direct_deposit_mcc is not None:
            for account_id in account_ids:
                account_type = account_types_map[account_id]
                
                # Adjust description and amounts for business accounts
                if account_type == 'business':
                    deposit_desc = 'Business Revenue Deposit'
                    # Business accounts might have higher/variable deposits
                    base_deposit = direct_deposit_amount * 2.5
                else:
                    deposit_desc = self.generate_merchant_name(self.direct_deposit_mcc['description'])
                    base_deposit = direct_deposit_amount
                
                # Generate direct deposits on 1st and 15th of each month
                current_date = start_date.replace(day=1)
                while current_date <= end_date:
                    # First deposit (1st of month)
                    if current_date >= start_date:
                        trans_date = current_date
                        transactions.append({
                            'AccountID': account_id,
                            'TransactionID': str(uuid.uuid4()),
                            'PostingDate': trans_date,
                            'TransactionDate': trans_date,
                            'Amount': base_deposit,
                            'Description': deposit_desc,
                            'Transaction_Category': self.direct_deposit_mcc['Tran_category'],
                            'MCC': self.direct_deposit_mcc['mcc'],
                            'MCC_Description': self.direct_deposit_mcc['description'],
                            'Transaction_status': 'Posted',
                            'Currency': 'USD',
                            'Transaction_Type': self.direct_deposit_mcc['Tran_Type'],
                            'Source_Transaction_Type': self.direct_deposit_mcc['Tran_Type'],
                            'Data_Date': data_date,
                            'SFAccountID': sf_account_ids_map[account_id],
                            'ContactID': contact_ids_map[account_id],
                            'Account_Type': account_type.title()
                        })
                    
                    # Second deposit (15th of month)
                    if current_date.day == 1:
                        try:
                            mid_month = current_date.replace(day=15)
                            if mid_month >= start_date and mid_month <= end_date:
                                transactions.append({
                                    'AccountID': account_id,
                                    'TransactionID': str(uuid.uuid4()),
                                    'PostingDate': mid_month,
                                    'TransactionDate': mid_month,
                                    'Amount': base_deposit,
                                    'Description': deposit_desc,
                                    'Transaction_Category': self.direct_deposit_mcc['Tran_category'],
                                    'MCC': self.direct_deposit_mcc['mcc'],
                                    'MCC_Description': self.direct_deposit_mcc['description'],
                                    'Transaction_status': 'Posted',
                                    'Currency': 'USD',
                                    'Transaction_Type': self.direct_deposit_mcc['Tran_Type'],
                                    'Source_Transaction_Type': self.direct_deposit_mcc['Tran_Type'],
                                    'Data_Date': data_date,
                                    'SFAccountID': sf_account_ids_map[account_id],
                                    'ContactID': contact_ids_map[account_id],
                                    'Account_Type': account_type.title()
                                })
                        except ValueError:
                            pass  # Handle months with fewer than 15 days (shouldn't happen)
                    
                    # Move to next month
                    if current_date.month == 12:
                        current_date = current_date.replace(year=current_date.year + 1, month=1, day=1)
                    else:
                        current_date = current_date.replace(month=current_date.month + 1, day=1)
        
        # Generate bonuses (QUARTERLY - on 1st of Jan, Apr, Jul, Oct)
        if include_bonuses:
            bonus_mcc = self.mcc_data[self.mcc_data['mcc'] == 9963].iloc[0] if 9963 in self.mcc_data['mcc'].values else None
            if bonus_mcc is not None:
                for account_id in account_ids:
                    account_type = account_types_map[account_id]
                    
                    # Adjust bonus description and amount for business accounts
                    if account_type == 'business':
                        bonus_amt = bonus_amount * 2.0  # Higher bonuses for business
                    else:
                        bonus_amt = bonus_amount
                    
                    # Generate quarterly bonuses on 1st of Jan (Q1), Apr (Q2), Jul (Q3), Oct (Q4)
                    quarterly_months = [1, 4, 7, 10]
                    current_date = start_date.replace(day=1)
                    
                    while current_date <= end_date:
                        # Check if this is a quarterly bonus month
                        if current_date.month in quarterly_months and current_date.day == 1:
                            if current_date >= start_date and current_date <= end_date:
                                # Determine quarter for description
                                quarter = (current_date.month - 1) // 3 + 1
                                
                                if account_type == 'business':
                                    bonus_desc = f'Q{quarter} Business Bonus - ' + self.generate_merchant_name(bonus_mcc['description'])
                                else:
                                    bonus_desc = f'Q{quarter} Quarterly Bonus - ' + self.generate_merchant_name(bonus_mcc['description'])
                                
                                transactions.append({
                                    'AccountID': account_id,
                                    'TransactionID': str(uuid.uuid4()),
                                    'PostingDate': current_date,
                                    'TransactionDate': current_date,
                                    'Amount': bonus_amt,
                                    'Description': bonus_desc,
                                    'Transaction_Category': bonus_mcc['Tran_category'],
                                    'MCC': bonus_mcc['mcc'],
                                    'MCC_Description': bonus_mcc['description'],
                                    'Transaction_status': 'Posted',
                                    'Currency': 'USD',
                                    'Transaction_Type': bonus_mcc['Tran_Type'],
                                    'Source_Transaction_Type': bonus_mcc['Tran_Type'],
                                    'Data_Date': data_date,
                                    'SFAccountID': sf_account_ids_map[account_id],
                                    'ContactID': contact_ids_map[account_id],
                                    'Account_Type': account_type.title()
                                })
                        
                        # Move to next month
                        if current_date.month == 12:
                            current_date = current_date.replace(year=current_date.year + 1, month=1, day=1)
                        else:
                            current_date = current_date.replace(month=current_date.month + 1, day=1)
        
        # Calculate total credits per account (for overdraft prevention)
        account_credits = {}
        for txn in transactions:
            acc = txn['AccountID']
            if acc not in account_credits:
                account_credits[acc] = 0.0
            # Credits have positive amounts (deposits, income)
            if txn['Transaction_Type'] == 'Credit':
                account_credits[acc] += txn['Amount']
        
        # Initialize debit tracking (80% of credits to leave buffer)
        account_debits = {acc_id: 0.0 for acc_id in account_ids}
        max_debit_per_account = {acc_id: account_credits.get(acc_id, 0) * 0.80 
                                  for acc_id in account_ids}
        
        # Calculate remaining transactions to generate
        remaining_records = num_records - len(transactions)
        
        # Generate remaining random transactions (with overdraft prevention)
        attempts = 0
        max_attempts = remaining_records * 3  # Allow some failed attempts
        
        while len(transactions) - len([t for t in transactions if t['Transaction_Type'] == 'Credit']) < remaining_records and attempts < max_attempts:
            attempts += 1
            
            # Randomly select an account
            account_id = random.choice(account_ids)
            account_type = account_types_map[account_id]
            
            # Get filtered MCCs based on account type
            filtered_mccs = self.get_filtered_mccs(account_type)
            
            # Randomly select an MCC from filtered list
            mcc_row = filtered_mccs.sample(n=1).iloc[0]
            
            # Generate random date within range
            random_days = random.randint(0, date_range)
            trans_date = start_date + timedelta(days=random_days)
            
            # Generate amount based on account type
            amount = self.generate_amount_for_mcc(mcc_row, account_type)
            
            # Check if this is a debit transaction and would overdraft the account
            is_debit = mcc_row['Tran_Type'] == 'Debit'
            
            if is_debit:
                # Check if adding this debit would exceed the budget
                if account_debits[account_id] + amount > max_debit_per_account[account_id]:
                    # Try to adjust amount to fit within budget
                    remaining_budget = max_debit_per_account[account_id] - account_debits[account_id]
                    if remaining_budget > 10:  # Only create transaction if at least $10 available
                        amount = round(random.uniform(5, min(amount, remaining_budget)), 2)
                    else:
                        # Skip this transaction - account is at limit
                        continue
                
                # Track the debit
                account_debits[account_id] += amount
            
            # Create transaction
            transactions.append({
                'AccountID': account_id,
                'TransactionID': str(uuid.uuid4()),
                'PostingDate': trans_date,
                'TransactionDate': trans_date,
                'Amount': amount,
                'Description': self.generate_merchant_name(mcc_row['description']),
                'Transaction_Category': mcc_row['Tran_category'],
                'MCC': mcc_row['mcc'],
                'MCC_Description': mcc_row['description'],
                'Transaction_status': 'Posted',
                'Currency': 'USD',
                'Transaction_Type': mcc_row['Tran_Type'],
                'Source_Transaction_Type': mcc_row['Tran_Type'],
                'Data_Date': data_date,
                'SFAccountID': sf_account_ids_map[account_id],
                'ContactID': contact_ids_map[account_id],
                'Account_Type': account_type.title()
            })
        
        # Create DataFrame
        df = pd.DataFrame(transactions)
        
        # Sort by TransactionDate
        df = df.sort_values('TransactionDate').reset_index(drop=True)
        
        return df


def main():
    """Main function to run the transaction simulator."""
    parser = argparse.ArgumentParser(description='Generate simulated financial transactions')
    parser.add_argument('--mcc-file', type=str, default='MCCs.csv',
                       help='Path to MCC CSV file')
    parser.add_argument('--account-ids', type=str, nargs='+', required=True,
                       help='One or more account IDs (space-separated)')
    parser.add_argument('--account-types', type=str, nargs='+', default=None,
                       help='Account types for each account ID: "personal" or "business" (space-separated, must match account-ids order). If not provided, defaults to personal for all accounts.')
    parser.add_argument('--sf-account-ids', type=str, nargs='+', default=None,
                       help='Salesforce Account IDs for each account (space-separated, must match account-ids order). If not provided, defaults to account-ids.')
    parser.add_argument('--contact-ids', type=str, nargs='+', default=None,
                       help='Contact IDs for each account (space-separated, must match account-ids order). If not provided, defaults to empty string.')
    parser.add_argument('--start-date', type=str, required=True,
                       help='Start date for transactions (YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, required=True,
                       help='End date for transactions (YYYY-MM-DD)')
    parser.add_argument('--num-records', type=int, default=100,
                       help='Number of records to generate (default: 100)')
    parser.add_argument('--output-file', type=str, default='generated_transactions.csv',
                       help='Output CSV file name (default: generated_transactions.csv)')
    parser.add_argument('--direct-deposit-amount', type=float, default=3000.00,
                       help='Fixed amount for direct deposits (default: 3000.00)')
    parser.add_argument('--bonus-amount', type=float, default=500.00,
                       help='Fixed amount for quarterly bonuses (default: 500.00)')
    parser.add_argument('--no-direct-deposits', action='store_true',
                       help='Exclude direct deposits (bi-monthly on 1st and 15th)')
    parser.add_argument('--no-bonuses', action='store_true',
                       help='Exclude quarterly bonuses (1st of Jan, Apr, Jul, Oct)')
    
    args = parser.parse_args()
    
    # Initialize simulator
    print("Initializing Transaction Simulator...")
    simulator = TransactionSimulator(args.mcc_file)
    
    # Validate account types if provided
    if args.account_types:
        if len(args.account_types) != len(args.account_ids):
            print(f"ERROR: Number of account types ({len(args.account_types)}) must match number of account IDs ({len(args.account_ids)})")
            sys.exit(1)
        
        # Validate each account type
        valid_types = ['personal', 'business']
        for acc_type in args.account_types:
            if acc_type.lower() not in valid_types:
                print(f"ERROR: Invalid account type '{acc_type}'. Must be 'personal' or 'business'")
                sys.exit(1)
    
    # Validate sf_account_ids if provided
    if args.sf_account_ids:
        if len(args.sf_account_ids) != len(args.account_ids):
            print(f"ERROR: Number of SF Account IDs ({len(args.sf_account_ids)}) must match number of account IDs ({len(args.account_ids)})")
            sys.exit(1)
    
    # Validate contact_ids if provided
    if args.contact_ids:
        if len(args.contact_ids) != len(args.account_ids):
            print(f"ERROR: Number of Contact IDs ({len(args.contact_ids)}) must match number of account IDs ({len(args.account_ids)})")
            sys.exit(1)
    
    # Generate transactions
    print(f"Generating {args.num_records} transactions...")
    print(f"Account IDs: {', '.join(args.account_ids)}")
    if args.account_types:
        print(f"Account Types: {', '.join(args.account_types)}")
    else:
        print(f"Account Types: personal (default for all)")
    if args.sf_account_ids:
        print(f"SF Account IDs: {', '.join(args.sf_account_ids)}")
    if args.contact_ids:
        print(f"Contact IDs: {', '.join(args.contact_ids)}")
    print(f"Date Range: {args.start_date} to {args.end_date}")
    
    df = simulator.generate_transactions(
        account_ids=args.account_ids,
        start_date=args.start_date,
        end_date=args.end_date,
        num_records=args.num_records,
        account_types=args.account_types,
        sf_account_ids=args.sf_account_ids,
        contact_ids=args.contact_ids,
        direct_deposit_amount=args.direct_deposit_amount,
        bonus_amount=args.bonus_amount,
        include_direct_deposits=not args.no_direct_deposits,
        include_bonuses=not args.no_bonuses
    )
    
    # Convert date columns to Timestamp_NTZ format (timezone-naive timestamps)
    date_columns = ['PostingDate', 'TransactionDate', 'Data_Date']
    for col in date_columns:
        if col in df.columns:
            # Convert to pandas datetime (if not already) and ensure timezone-naive
            df[col] = pd.to_datetime(df[col]).dt.tz_localize(None)
            # Format as string in Timestamp_NTZ format (YYYY-MM-DD HH:MM:SS.ffffff)
            df[col] = df[col].dt.strftime('%Y-%m-%d %H:%M:%S.%f')
    
    # Save to CSV with proper quoting to handle commas and special characters
    # quoting=0 is csv.QUOTE_MINIMAL - only quotes fields containing special characters
    df.to_csv(args.output_file, index=False, quoting=0)
    print(f"\nSuccess! Generated {len(df)} transactions.")
    print(f"Output saved to: {args.output_file}")
    
    # Display summary statistics
    print("\n" + "="*60)
    print("TRANSACTION SUMMARY")
    print("="*60)
    print(f"Total Transactions: {len(df)}")
    print(f"Date Range: {df['TransactionDate'].min()} to {df['TransactionDate'].max()}")
    print(f"\nAccount Types:")
    print(df['Account_Type'].value_counts())
    print(f"\nTransaction Types:")
    print(df['Transaction_Type'].value_counts())
    print(f"\nTotal Debits: ${df[df['Transaction_Type'] == 'Debit']['Amount'].sum():,.2f}")
    print(f"Total Credits: ${df[df['Transaction_Type'] == 'Credit']['Amount'].sum():,.2f}")
    print(f"\nTop 5 Transaction Categories:")
    print(df['Transaction_Category'].value_counts().head())
    
    # Show breakdown by account type
    if len(df['Account_Type'].unique()) > 1:
        print(f"\n" + "-"*60)
        print("BREAKDOWN BY ACCOUNT TYPE")
        print("-"*60)
        for acc_type in df['Account_Type'].unique():
            acc_df = df[df['Account_Type'] == acc_type]
            print(f"\n{acc_type} Accounts:")
            print(f"  Transactions: {len(acc_df)}")
            print(f"  Total Credits: ${acc_df[acc_df['Transaction_Type'] == 'Credit']['Amount'].sum():,.2f}")
            print(f"  Total Debits: ${acc_df[acc_df['Transaction_Type'] == 'Debit']['Amount'].sum():,.2f}")
            print(f"  Avg Transaction: ${acc_df['Amount'].mean():.2f}")
            print(f"  Top 3 Categories: {', '.join(acc_df['Transaction_Category'].value_counts().head(3).index.tolist())}")
    
    # Show account balance verification (overdraft check)
    print(f"\n" + "-"*60)
    print("ACCOUNT BALANCE VERIFICATION")
    print("-"*60)
    for account_id in df['AccountID'].unique():
        acc_df = df[df['AccountID'] == account_id]
        credits = acc_df[acc_df['Transaction_Type'] == 'Credit']['Amount'].sum()
        debits = acc_df[acc_df['Transaction_Type'] == 'Debit']['Amount'].sum()
        balance = credits - debits
        utilization = (debits / credits * 100) if credits > 0 else 0
        
        print(f"\nAccount {account_id}:")
        print(f"  Total Credits: ${credits:,.2f}")
        print(f"  Total Debits:  ${debits:,.2f}")
        print(f"  Net Balance:   ${balance:,.2f}")
        print(f"  Utilization:   {utilization:.1f}% of available credits")
        if balance < 0:
            print(f"  ⚠️  WARNING: Account is OVERDRAWN!")
        else:
            print(f"  ✓ Account is in good standing")


if __name__ == "__main__":
    main()
