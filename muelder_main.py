import pandas as pd
import numpy as np
from sklearn.model_selection import RandomizedSearchCV
from muelder_optimise import MyModel
from muelder_custom_cv import CustomCV
from muelder_plot_fit import plot_fit
from muelder_error import error
import csv
import matplotlib
matplotlib.use('Agg')

# Number of runs
num_runs = 1

def load_data(filepath):
    # Load your training data
    data = pd.read_csv(filepath)
    return data

def custom_discrete(low, high, step):
    return list(np.arange(low, high, step))

# Function to save error values and parameter values to a CSV file
def save_results_to_csv(error_values_list, parameter_values_list):
    with open('error_and_parameter_values.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        # Write header
        writer.writerow(['Error'] + list(param_grid.keys()))  # Add parameter names
        # Write data for each run
        for i in range(num_runs):
            error_value = error_values_list[i]  
            parameters = parameter_values_list[i]
            writer.writerow([error_value] + [parameters[param] for param in param_grid.keys()])

if __name__ == '__main__':
    # Load your training data
    data = load_data('solar_pv_training_data.csv')

    # Extract X_train_years
    X_train_years = np.array([int(year) for year in data.columns[1:]])

    # Extract the solar PV adoption data for all municipalities
    X_train_all = data.iloc[:, 1:].values  # Exclude the municipality names

    # Extract y_train
    y_train = data.iloc[:, 1:].values  # Extracting all municipalities' data
    y_train_all = y_train.reshape(-1, len(X_train_years))  # Reshape to (number of municipalities, number of years)

    model = MyModel()

    # Define the parameter distributions
    param_grid = {
        "Visibility": [True, False],
        "Sparking_Events": [False, False],
        "Uncertainty": [True, False],
        "Info_Costs": [True, False],
        "Info_Costs_Revenue": [True, False],
        "Info_Costs_Income": [True, False],
        "Information_Threshold": [True, False],
        "InputRandomSeed": [10],
        "initial_pv_share": [0.08],
        "interest_rate": custom_discrete(0, 0.1, 0.02),
        "pv_SDE_premium": custom_discrete(0, 0.3, 0.05),
        "close_links": custom_discrete(0, 5, 1),
        "random_links": custom_discrete(0, 0.1, 0.05),
        "weight_eco": custom_discrete(0, 1, 0.2),
        "weight_env": custom_discrete(0, 1, 0.2),
        "weight_soc": custom_discrete(0, 1, 0.2),
        "influence_cost_time": custom_discrete(0, 1, 0.2),
        "information_threshold_value": custom_discrete(0, 1, 0.2),
    }

    # Lists to store error values and corresponding parameter values for each run
    error_values_list = []
    parameter_values_list = []

for _ in range(num_runs):
    random_search = RandomizedSearchCV(model, param_distributions=param_grid,
                                       cv=CustomCV(n_splits=2),
                                       verbose=1, n_jobs=-1, n_iter=2)
    random_search.fit(X_train_all, y_train_all)  # No need to flatten y_train_all for fitting

    # Use the best model to make predictions on the training data  
    best_model = random_search.best_estimator_
    predictions = best_model.predict(X_train_all)

    # # Compute the error between the predictions and the actual values
    error_value = error(predictions, y_train_all)

    # Append error value and corresponding parameters to the lists
    error_values_list.append(error_value)
    parameter_values_list.append(random_search.best_params_)
    
    # Print predictions, actual values, and error
    print(f"Run {_+1}:")
    print("Predictions:", predictions)
    print("Error:", error_value)

# Save error values and parameter values to a CSV file
save_results_to_csv(error_values_list, parameter_values_list)

# Print error values
print(f"Error_value: {error_value}")

# Plot the fit of the best estimator
plot_fit(X_train_years, y_train_all, best_model,
         error=error_values_list[-1],  
         params=random_search.best_params_)

