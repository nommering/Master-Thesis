"""
Define error function.

"""
from fastdtw import fastdtw
import pandas as pd

# Load data
data = pd.read_csv('solar_pv_training_data.csv')
y_train = data.iloc[:, 1:].values  # Extracting all municipalities' data

# Find Vaals's data
Vaals_index = data[data.iloc[:, 0] == 'Vaals'].index[0]
data_municipality = y_train[Vaals_index]

def my_metric(x, y):
    """
    Custom metric function for calculating distance between two arrays.

    """
    return abs(x - y)

def error(predictions, data_municipality):
    """
    Calculate error between predictions and actual data using Dynamic Time Warping.

    """
    if isinstance(data_municipality, pd.DataFrame):
        data_municipality = data_municipality.values.ravel()
    else:
        data_municipality = data_municipality.ravel()

    # x is model data, y is target data
    distance, _ = fastdtw(predictions, data_municipality, dist=my_metric)
    
    return distance
