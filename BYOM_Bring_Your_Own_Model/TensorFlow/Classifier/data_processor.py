# **************************************************************************************************
# PROJECT: BYOM Data Preprocessor for Retail Attrition using TensorFlow
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-05-13
# PURPOSE: Create necessary pre/post processing functions for BYOM functionality
# STEPS:
# 1) Specify LABEL_COLUMN to indicate outcome variable/field (required)
# 2) Define preprocessor() to handle data preprocessing
# 3) Define postprocessor() to tidy up data after running through model
# **************************************************************************************************

# Import necessary packages
import pandas as pd
import numpy as np

# Define variable for target 
LABEL_COLUMN = 'Churned_c'

# Function to take in csv and read the dataset
def read_dataset(file_path: str):
    """This function reads the CSV file, then drops all observations with missing values, next, 
    it converts categorical variables using one-hot encoding, and finally re-orders the index of the dataframe
    """
    raw_data = pd.read_csv(file_path)
    digested_dataset = raw_data.dropna()
    digested_dataset = pd.get_dummies(digested_dataset, columns=['Customer_Segment_c','Online_Banking_c','Mobile_Banking_c','Direct_Deposit_c','Single_Product_Customer_c','Promotional_Product_c','NPS_Score_c'])
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns),axis=1)
    return digested_dataset

# Function to process the dataset and apply any transformations
def preprocessor(file_path: str):
    """This function takes the dataframe that was read as input and drops the target variable if found, returning a clean set for training"""
    dataset = read_dataset(file_path)
    if LABEL_COLUMN in dataset.columns:
        dataset.pop(LABEL_COLUMN)
    return dataset.values


# Function to process the predictions into a list for ingestion
def postprocessor(predictions):
    """
    This is a mandatory function with a single input argument with array of predictions.
    :param predictions: array of array of string
    :return:
    """
    results = []
    for prediction in predictions:
        results.append(prediction[0])

    return results