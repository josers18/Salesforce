# **************************************************************************************************
# PROJECT: BYOM Random Forest for Species Prediction Multiclass Sample using Scikit Learn
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-11-08
# PURPOSE: Create MultiClass Classification Model for BYOM Random Forest
# STEPS:
# 1) Import necessary libraries
# 2) Read the training data, process the variables and prepare the training data
# 3) Define and Create the Random Forest model, verify accuracy scores
# 4) Serialize model into a pkl file to create final zip file to upload in Model Manager
# **************************************************************************************************

# Import Necessary Packages

import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import matplotlib.pyplot as plt
import pickle

# Change Pandas to be able to preview the data without truncation
pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', None)


# Add LABEL_COLUMN (===REQUIRED===)

LABEL_COLUMN = 'Species'

# Define function to read and process dataset for training

def read_dataset(file_path: str):
    raw_data = pd.read_csv(file_path)
    digested_dataset = raw_data.dropna()
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns),axis=1)
    return digested_dataset

# Execute read_dataset function from data processor and create x and y for model training
DATAFILE = '/root/Iris.csv'
raw_data = read_dataset(DATAFILE)
y = raw_data[LABEL_COLUMN]
x = raw_data.drop(LABEL_COLUMN, axis=1)
 

# Do some data exploration on our dataset to verify

raw_data.info()
raw_data.describe()
raw_data.isnull().sum()
raw_data.head(100)

# Train test split data
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=.20, random_state=18)


# Create model
rf = RandomForestClassifier()

# Execute the model run
model = rf.fit(x_train, y_train)
y_pred = model.predict(x_test)

# Testing Accuracy
fig, ax = plt.subplots(figsize=(8,5))
cmp = ConfusionMatrixDisplay(confusion_matrix(y_test, y_pred), display_labels=['Virginica','Versicolor','Setosa'])
cmp.plot(ax=ax)
plt.show()

classification_report(y_test, y_pred)
accuracy_score(y_test,y_pred)
f1_score(y_test,y_pred, average=None)
model.score(x_test, y_test)

# Save Model (Serialization to JSON)
filename = 'saved_model.pkl'
pickle.dump(model, open(filename,'wb'))