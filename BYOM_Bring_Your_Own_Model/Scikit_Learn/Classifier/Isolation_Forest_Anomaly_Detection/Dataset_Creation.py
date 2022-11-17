
# Import Necessary Packages
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest

# Create a random state for reproducibility purposes
rng = np.random.RandomState(18)

# Generate train data
x = 0.3 * rng.randn(2500, 2)
x_train = np.r_[x + 2, x - 2]

# Define and train model
clf = IsolationForest(max_samples=100, random_state=rng)
clf.fit(x_train)
y_pred_train = clf.predict(x_train)

# Create Main Dataset to train our model
variables = pd.DataFrame(x_train, columns=['Var1','Var2'])
target = np.where(y_pred_train == 1, 0, 1)
target = pd.DataFrame(target, columns=['Anomaly'])
df = pd.concat([variables, target],axis=1)

df.to_csv('Anomaly_Training.csv', index=False)
