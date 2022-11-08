# **************************************************************************************************
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-11-08
# PURPOSE: Create quick script to prepare the validation file for Model Manager upload
# STEPS:
# 1) Import necessary libraries
# 2) Read validation dataset (99 records) not containing target variable, execute read_dataset function against it
# 3) Loan the serialized model and run predictions on processed dataset
# 4) Crate a validation dataset that takes the original dataset and append the predictions, output to csv as validation.csv
# **************************************************************************************************

# Import Packages
import pandas as pd
import pickle
import data_processor as dp

# Load serialized model
filename = 'saved_model.pkl'
loaded_model = pickle.load(open(filename,'rb'))

# Read and process validation base dataset with no target variable
df_source = pd.read_csv('validation_bk.csv')
df = dp.read_dataset('validation_bk.csv')
df.info()

# Predict target on dataset
predictions = loaded_model.predict(df)
print(predictions)

# Define dataframes to append and create new dataframe for validation
target = pd.DataFrame(predictions, columns=['Churned_c'])
validation = pd.concat([df_source,target], axis=1)
print(validation)

# Write results to validation.csv file which will be used to upload to Model Manager zip
validation.to_csv('validation.csv', index=False)
