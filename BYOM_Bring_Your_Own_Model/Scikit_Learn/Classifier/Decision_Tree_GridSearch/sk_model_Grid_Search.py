# **************************************************************************************************
# PROJECT: BYOM Decision Tree Classifier with GridSearch Hyperparameter Tuning for Retail Attrition Sample using Scikit Learn
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-11-08
# PURPOSE: Create Classification Model with Grid Search for BYOM Decision Tree
# STEPS:
# 1) Import necessary libraries
# 2) Read the training data, process the variables and prepare the training data
# 3) Define and Create the Decision Tree model, define Grid Search Parameters and run testing, verify accuracy scores
# 4) Serialize model into a pkl file to create final zip file to upload in Model Manager
# **************************************************************************************************

# Import Necessary Packages

import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import GridSearchCV
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import pickle


# Add LABEL_COLUMN (===REQUIRED===)

LABEL_COLUMN = 'Churned_c'

# Define function to read and process dataset for training

def read_dataset(file_path: str):
    raw_data = pd.read_csv(file_path)
    digested_dataset = raw_data.dropna()
    digested_dataset = pd.get_dummies(digested_dataset, columns=['Customer_Segment_c','Online_Banking_c','Mobile_Banking_c','Direct_Deposit_c','Single_Product_Customer_c','Promotional_Product_c','NPS_Score_c'])
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns),axis=1)
    return digested_dataset

# Execute read_dataset function from data processor and create x and y for model training
DATAFILE = '/root/Retail_Attrition.csv'
raw_data = read_dataset(DATAFILE)
y = raw_data[LABEL_COLUMN]
x = raw_data.drop(LABEL_COLUMN, axis=1)
 

# Do some data exploration on our dataset to verify
raw_data.info()
raw_data.describe()
raw_data.isnull().sum()
raw_data.head(100)

# Train test split data
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=.20, random_state=18, stratify=y)

# Define Hyperparameter dictionary for different testing options
criterion = ['gini', 'entropy']
max_depth = [2,4,6,8,10,12]

parameters = dict(criterion=criterion,max_depth=max_depth)

# Create model
dt = DecisionTreeClassifier()
dt_grid = GridSearchCV(dt, parameters)

# Execute the model run
model = dt_grid.fit(x_train, y_train)
y_pred = model.predict(x_test)

# Print out best Hyperparameter settings
print('Best Criterion:', dt_grid.best_estimator_.get_params()['criterion'])
print('Best max_depth:', dt_grid.best_estimator_.get_params()['max_depth'])

# Testing Accuracy
classification_report(y_test,y_pred)
accuracy_score(y_test,y_pred)
model.score(x_test, y_test)

# Save Model (Serialization to JSON)
filename = 'saved_model.pkl'
pickle.dump(model, open(filename,'wb'))