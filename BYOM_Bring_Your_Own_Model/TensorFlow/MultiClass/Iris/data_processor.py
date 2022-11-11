# **************************************************************************************************
# PROJECT: BYOM Data Preprocessor for Random Forest MultiClass Classification Sample using Tensorflow
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-11-08
# PURPOSE: Create necessary pre/post processing functions for BYOM functionality
# STEPS:
# 1) Specify LABEL_COLUMN to indicate outcome variable/field (required)
# 2) Define preprocessor() to handle data pre-processing
# 3) Define postprocessor() to tidy up data after running through model and append predictions to a list 
# **************************************************************************************************

# Import necessary packages
import pandas as pd

# Define variable for target 
LABEL_COLUMN = 'Species'

# Function to take in csv and read the dataset
def read_dataset(file_path: str):
    """This function reads the CSV file, then drops all observations with missing values, next, 
    it converts categorical variables using one-hot encoding, and finally re-orders the index of the dataframe
    """
    raw_data = pd.read_csv(file_path)
    digested_dataset = raw_data.dropna()
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns),axis=1)
    return digested_dataset

# Function to process the dataset and apply any transformations
def preprocessor(file_path: str):
    """This function takes the dataframe that was read as input and drops the target variable if found, returning a clean set for training"""
    dataset = read_dataset(file_path)
    if LABEL_COLUMN in dataset.columns:
        dataset.pop(LABEL_COLUMN)
    return dataset

# Function to process the predictions into a list for ingestion
def postprocessor(predictions):
    """This function takes a list of predictions from our model and returns a list"""
    results = []

    for prediction in predictions:
        species_dict = {"Setosa": prediction[0], "Versicolor": prediction[1], "Virginica": prediction[2]}
        results.append(species_dict)
    return results
