# **************************************************************************************************
# PROJECT: BYOM Isolation Forest test for Anomaly Detection Classification Sample using Scikit Learn
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-11-16
# PURPOSE: Create Anomaly Classification Model for BYOM Isolation Forest
# STEPS:
# 1) Import necessary libraries
# 2) Read the training data, process the variables and prepare the training data
# 3) Define and Create the Isolation Forest model
# 4) Serialize model into a pkl file to create final zip file to upload in Model Manager
# **************************************************************************************************

# Import Necessary Packages

import pandas as pd
import numpy as np
from sklearn.ensemble import IsolationForest
import pickle

#Create a Random State for Reproducibility
rng = np.random.RandomState(18)

# Change Pandas to be able to preview the data without truncation
pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)

# Add LABEL_COLUMN (===REQUIRED===)

LABEL_COLUMN = 'Anomaly'

# Define function to read and process dataset for training

def read_dataset(file_path: str):
    raw_data = pd.read_csv(file_path)
    digested_dataset = raw_data.dropna()
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns),axis=1)
    return digested_dataset

# Execute read_dataset function from data processor and create x and y for model training
DATAFILE = '/root/Anomaly_Training.csv'
raw_data = read_dataset(DATAFILE)
y = raw_data[LABEL_COLUMN]
x = raw_data.drop(LABEL_COLUMN, axis=1)

# Define Isolation Forest Model and Train on dataset
clf = IsolationForest()
model = clf.fit(x)
y_pred = clf.predict(x)

# Save Model (Serialization to JSON)
filename = 'saved_model.pkl'
pickle.dump(model, open(filename,'wb'))

# Generate some new observations for our validation set
x = 0.3 * rng.randn(40, 2)
x_test = np.r_[x + 2, x - 2]
y_pred_test = clf.predict(x_test)

# Create the validation dataset
variables = pd.DataFrame(x_test, columns=['Var1','Var2'])
target = np.where(y_pred_test == 1, 0, 1)
target = pd.DataFrame(target, columns=['Anomaly'])
df = pd.concat([variables, target],axis=1)

df.to_csv('validation.csv', index=False)