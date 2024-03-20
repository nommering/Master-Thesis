import pandas as pd
import numpy as np
from sklearn.model_selection import RandomizedSearchCV
from functools import reduce
from kam_optimise import MyModel
from kam_custom_cv import CustomCV
from kam_plot_fit import plot_fit
from kam_error import error
import csv
import matplotlib
matplotlib.use('Agg')

# Number of runs
num_runs = 5

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
            error_value = error_values_list[i][0]  # Convert error value to scalar
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
        "neighbourhood_effect": [True, False],
        "word_of_mouth": [True, False],
        "tenants_can_install": [True, False],
        "historic_houses_can_install_PV": [True, False],
        "sensitivity_analysis": [False],
        "households": [8001],
        "number_of_neighbours": custom_discrete(0, 20, 10),
        "stimulate_social_interaction": custom_discrete(0.0, 1.0, 0.5),
        "subsidy_PV": custom_discrete(0.0, 1.0, 0.5),
        "PV_net_bill_after_adoption": custom_discrete(0, 1000, 500),
        "learning_rate_life_cycle_ghg_PV": custom_discrete(0.0, 1.0, 0.5),
        "PV_self_sufficiency_potential_global": custom_discrete(0.0, 1.0, 0.5),
        "information_campaign_PV_year": custom_discrete(2012, 2023, 1)
    }

    # Lists to store error values and corresponding parameter values for each run
    error_values_list = []
    parameter_values_list = []

    # Perform multiple runs
    for _ in range(num_runs):
        random_search = RandomizedSearchCV(model, param_distributions=param_grid,
                                           cv=CustomCV(n_splits=2),
                                           verbose=1, n_jobs=-1, n_iter=2)
        random_search.fit(X_train_all, y_train_all)  # No need to flatten y_train_all for fitting

        # Use the best model to make predictions on the training data
        best_model = random_search.best_estimator_
        predictions = best_model.predict(X_train_all)

        # Compute the error between the predictions and the actual values
        error_value = error(predictions, y_train_all)

        # Append error value and corresponding parameters to the lists
        error_values_list.append(error_value)
        parameter_values_list.append(random_search.best_params_)

    # Save error values and parameter values to a CSV file
    save_results_to_csv(error_values_list, parameter_values_list)

    # Print error values
    for i, error_value in enumerate(error_values_list):
        print(f"Error value {i+1}: {error_value[0]}")  # Print error value as scalar

    # Plot the fit of the best estimator
    plot_fit(X_train_years, y_train_all, best_model,
             error=error_values_list[-1][0],  # Plot the error value of the last run as scalar
             params=random_search.best_params_)
