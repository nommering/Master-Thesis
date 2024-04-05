import numpy as np
import pandas as pd

def calculate_mae(array, value):
    errors = np.abs(array - value)
    mae = np.mean(errors)
    return mae

# # Determine data
data = pd.read_csv('solar_pv_training_data.csv')
data= data.iloc[0:, 1:]

# # Extract X_train_years
X_train_years = np.array([int(year) for year in data.columns[1:]])

# # Error function
def error(predictions,b):
    counter =0
    errorcalclist=[]
    for column in data:
        b=(data[column].values)
        errorcalclist.append(calculate_mae(b,predictions[counter]))
        counter = counter+1
    error_value = np.mean(errorcalclist)
    return error_value

#predictions=np.array([5455., 5836., 5973., 6094., 6242., 6296., 6377., 6437., 6496.,6560., 6598.])
#b=np.array([187,62,109,660,68,148,94,77,160,200,59,141])

#for element in a:
#    calculate_mae(b,element)
# counter=0
# errorcalclist=[]
# for column in data:
#     b=(data[column].values)
#     errorcalclist.append(calculate_mae(b,predictions[counter]))
#     counter=counter+1

# print("This is your mean", np.mean(errorcalclist))
# error_value = np.mean(errorcalclist)
# return error_value

        
# # Define a custom distance metric
# def my_metric(x, y, model_std, *args, **kwargs):
#     # Calculate the median and mean of the model data
#     model_median = np.median(x)
#     model_mean = np.mean(x)
#     # Check if the absolute difference between model data and target data
#     # is within the model standard deviation
#     if (abs(model_median - y) <= model_std).any() or (abs(model_mean - y) <= model_std).any():
#         return 0
#     else:
#         # Return the absolute difference between model data and target data
#         return abs(x - y)
    
# def error(predictions, target_df):
#     # Calculate the error for each year by comparing predictions to target values using Dynamic Time Warping.
#     # Use predicted values for each year, and target_df dataframe containing actual values for each year
#     # Returns an array containing the mean error for each year and the average error over all years. 

#     # Initialize an empty list to store mean errors for each year
#     year_mean_errors = []

#     # Iterate over each item in the target DataFrame
#     for year_index, actual_value in enumerate(target_df):
#         # Calculate the distance using Dynamic Time Warping between the current actual value and its corresponding prediction

#         # Convert actual_value to a NumPy array
#         actual_value_np = np.array(actual_value)

#         # Convert actual_value to a NumPy array
#         if np.isscalar(actual_value):
#             actual_value_np = np.array([actual_value])  # Convert scalar to 1D array
#         else:
#             actual_value_np = np.array(actual_value)
#         distance, _ = fastdtw([[predictions[year_index],1]], [[actual_value,1]], dist=partial(my_metric, model_std=np.std(predictions)))
        
#         # Append the distance to the list of distances
#         year_mean_errors.append(distance)

    
    
#     # Calculate the mean error for each year
#     year_mean_errors = np.array(year_mean_errors)
#     print(year_mean_errors)
#     mean_error_per_year = np.mean(year_mean_errors)
#     print(mean_error_per_year)

#     # Calculate the average error over all years
#     avg_error = np.mean(mean_error_per_year)
    
#     print(avg_error)
#     return avg_error