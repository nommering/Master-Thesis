from fastdtw import fastdtw
from scipy.spatial.distance import euclidean
from functools import partial
import numpy as np
import pandas as pd

# Define a custom distance metric
def my_metric(x, y, model_std, *args, **kwargs):
    # Calculate the median and mean of the model data
    model_median = np.median(x)
    model_mean = np.mean(x)
    # Check if the absolute difference between model data and target data
    # is within the model standard deviation
    if (abs(model_median - y) <= model_std).any() or (abs(model_mean - y) <= model_std).any():
        return 0
    else:
        # Return the absolute difference between model data and target data
        return abs(x - y)

# Define the error function
def error(predictions, target_df):
    # Extract model data from predictions
    model_data = predictions
    
    # Check the type of target data and handle accordingly
    if isinstance(target_df, pd.DataFrame): 
        target_data = target_df.values.ravel()
    else:
        target_data = target_df.ravel()

    # Calculate the standard deviation of the model data
    model_std = np.std(model_data, axis=0)  # Specify axis=0 to calculate the standard deviation along columns

    # Calculate the distance using Dynamic Time Warping with the custom distance metric
    distance, _ = fastdtw(model_data, target_data, dist=partial(my_metric, model_std=model_std))
    
    return distance
