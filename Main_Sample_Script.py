import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from faker import Faker
fake = Faker()
pd.options.display.float_format = '{:.2f}'.format
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
maindf = pd.read_csv('/Users/jsifontes/Documents/TCRM Assets/DataSet Creation/Amerant_CustomerMaster.csv', header=0)
businessdf = maindf[maindf['Segment'] == 'Business Banking']
size  = 20000
df = pd.DataFrame()

df['Segment'] = ['Business Banking'] * size
df['Branch'] = np.random.randint(1, size, size)
df['OpenDate'] = [fake.date() for i in range(size)]
df['PersonalNonPersonal'] = ['N'] * size
df['ValidEmail'] = np.random.choice([1, 0], size, p=[0.80, 0.2])
df['ValidPhone'] = np.random.choice([1, 0], size, p=[0.90, 0.1])
df['Checking'] = np.random.choice([1, 0], size, p=[0.90, 0.1])
df['CheckingBalance'] = [np.random.uniform(low=3500,high=800000) if df['Checking'][i] == 1 else 0 for i in range(size)]
df['CheckingCount'] = [np.random.randint(low=1,high=3) if df['Checking'][i] == 1 else 0 for i in range(size)]
df['Savings'] = np.random.choice([1, 0], size, p=[0.90, 0.1])
df['SavingsBalance'] = [np.random.uniform(low=3500,high=800000) if df['Savings'][i] == 1 else 0 for i in range(size)]
df['SavingsCount'] = [np.random.randint(low=1,high=3) if df['Savings'][i] == 1 else 0 for i in range(size)]
df['MoneyMarket'] = np.random.choice([1, 0], size, p=[0.90, 0.1])
df['MoneyMarketBalance'] = [np.random.uniform(low=3500,high=800000) if df['MoneyMarket'][i] == 1 else 0 for i in range(size)]
df['MoneyMarketCount'] = [np.random.randint(low=1,high=3) if df['MoneyMarket'][i] == 1 else 0 for i in range(size)]
df['TranDepositBalance'] = np.sum(df[['CheckingBalance', 'SavingsBalance', 'MoneyMarketBalance']], axis=1)
df['TranDepositCount'] = np.sum(df[['CheckingCount', 'SavingsCount', 'MoneyMarketCount']], axis=1)
df['TranDeposits'] = np.where(df['TranDepositCount'] > 0, 1, 0)
df['DormantCount'] = np.where((df['TranDepositCount'] > 0) & (df['TranDepositCount']<=3), np.random.randint(1,3), 0)
df['Dormant'] = np.where(df['DormantCount'] > 0, 1, 0)
df.head(200)
df['TranDepositBalance'].describe()
plt.hist(df['TranDepositBalance'])
plt.show()



def rfmodel(x,y):
    '''create random forest model utilizing x as features and y as target implementing randomized grid search'''


