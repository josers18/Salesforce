import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from faker import Faker
fake = Faker()

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
df['TranDeposits'] = np.random.choice([1, 0], size, p=[0.90, 0.1])
df['TranDepositBalance'] = [np.random.uniform(low=3500,high=800000) if df['TranDeposits'][i] == 1 else 0 for i in range(size)]
df['TranDepositCount'] = [np.random.randint(low=1,high=3) if df['TranDeposits'][i] == 1 else 0 for i in range(size)]
df.head(200)
df['TranDepositBalance'].describe()
plt.hist(df['TranDepositBalance'])
plt.show()
