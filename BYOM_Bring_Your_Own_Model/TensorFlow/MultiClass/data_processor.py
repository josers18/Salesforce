"""
This script is required as an input for Einstein Discovery - Bring your own model (BYOM)
This script is used to convert raw input into digested input that the model recognizes,
and also convert raw predict to user readable output to be send/stored by Einstein Discovery Predictions.

The mandatory functions/variables in this file are marked by a comment.
"""

import pandas as pd

# This is a mandatory variable, and is required.
# This specifics the name of the field to be used as label column/ outcome column in validation.csv
LABEL_COLUMN = 'Origin'
COLUMN_NAMES = ['MPG', 'Cylinders', 'Displacement', 'Horsepower', 'Weight', 'Acceleration', 'Model_Year', 'Origin']


def read_dataset(file_path):
    raw_dataset = pd.read_csv(file_path, na_values='?', skipinitialspace=True)
    digested_dataset = raw_dataset.dropna()

    # Make sure the columns are always ordered the same way
    digested_dataset = digested_dataset.reindex(sorted(digested_dataset.columns), axis=1)
    return digested_dataset


def preprocessor(file_path):
    """
    This is a mandatory function with a single argument for the file_path to the csv data.
    The CSV file with data is RFC4180 formatted.
    :param file_path: string
    :return:
    """
    dataset = read_dataset(file_path)

    # Remove LABEL_COLUMN if is accidentally exists in the dataset
    if LABEL_COLUMN in dataset.columns:
        dataset.pop(LABEL_COLUMN)

    return dataset.values


def postprocessor(predictions):
    """
    This is a mandatory function with a single input argument with array of predictions.
    :param predictions: array of array of string
    :return:
    """
    results = []
    for prediction in predictions:
        results.append({"USA": prediction[0], "Europe": prediction[1], "Japan": prediction[2]})

    return results
