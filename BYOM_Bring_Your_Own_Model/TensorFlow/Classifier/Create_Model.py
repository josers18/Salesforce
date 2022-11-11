# ***************************************************************************************************
# PROJECT: BYOM Create TF Neural Net Classifier for Retail Attrition
# AUTHOR: Jose Sifontes
# ORIGIN: 2022-05-13
# PURPOSE: Create neural network example for BYOM 
# STEPS:
# 1) Load packages & data, initialize static parameters
# 2) Create train/test split & conduct data normalization
# 3) Create, compile, & fit neural network
# 4) Save model as .pb file
# ***************************************************************************************************

### Load packages & data, initialize static parameters
# Load imports
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import InputLayer, Dense
from tensorflow.keras.optimizers import Adam
from sklearn.model_selection import train_test_split


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
DATAFILE = 'Retail_Attrition.csv'
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


#create model
LNN_model = Sequential()
LNN_model.add(InputLayer(input_shape=(23,)))
LNN_model.add(Dense(1,activation='sigmoid'))
LNN_model.summary()

#Compile the model
optimizer = Adam(learning_rate=0.001)
LNN_model.compile(optimizer=optimizer, loss='binary_crossentropy', metrics=['accuracy'])

#Execute the model run
history = LNN_model.fit(x_train, y_train, epochs=100, batch_size=32, validation_split=0.2, shuffle=False)
test_loss, test_acc = LNN_model.evaluate(x_test, y_test)
print("Test loss:", test_loss)
print("Test accuracy:", test_acc)

#save Model
LNN_model.save('/root/')


# ^ This line saves our model and produces three files:
# 1) saved_model.pb
# 2) assets/
# 3) variables/

# ---Create Validation File ----

# Read and process validation base dataset with no target variable
df_source = pd.read_csv('validation_bk.csv')
df = read_dataset('validation_bk.csv')
df.info()

# Predict target on dataset
predictions = (LNN_model.predict(df) > 0.5).astype("int32")
print(predictions)

# Define dataframes to append and create new dataframe for validation
target = pd.DataFrame(predictions, columns=['Churned_c'])
validation = pd.concat([df_source,target], axis=1)
print(validation)

# Write results to validation.csv file which will be used to upload to Model Manager zip
validation.to_csv('validation.csv', index=False)