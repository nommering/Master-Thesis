import pandas as pd
import numpy as np
from skopt import BayesSearchCV
from muelder_optimise import MyModel
from muelder_custom_cv import CustomCV
from muelder_plot_fit import plot_fit
from muelder_error import error
import csv
import matplotlib
# matplotlib.use('Agg')

# Number of runs
num_runs = 25

def load_data(filepath):
    # Load your training data
    data = pd.read_csv(filepath)
    return data

def custom_discrete(low, high, step):
    return list(np.arange(low, high, step))

# Function to save error values and parameter values to a CSV file
def save_results_to_csv(error_values_list, parameter_values_list, predictions_list):
    with open('error_and_parameter_values.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        # Write header
        writer.writerow(['Error'] + list(param_grid.keys()) + ['Predictions'])  # Add parameter names and Predictions
        # Write data for each run
        for i in range(num_runs):
            error_value = error_values_list[i]  
            parameters = parameter_values_list[i]
            predictions = predictions_list[i]
            writer.writerow([error_value] + [parameters[param] for param in param_grid.keys()] + [predictions])


if __name__ == '__main__':
    # Load your training data
    data = load_data('solar_pv_training_data.csv')

    # Extract X_train_years
    X_train_years = np.array([int(year) for year in data.columns[1:]])
    print("X_train_years:", X_train_years)

    # Extract the solar PV adoption data for all municipalities
    X_train_init = data.iloc[:, 1:].values  # Exclude the municipality names

    # Transpose the original matrix
    X_train = X_train_init.transpose()

    print("X Train", X_train)

    y_train_init = data.iloc[:, 1:].values  # Extracting all municipalities' data

    # Extract y_train for the municipality of Laren
    municipality_index = data[data.iloc[:, 0] == 'Laren'].index[0]  # Find the row index for Laren
    y_train = y_train_init[municipality_index]  # Extract Laren's data

    print("y train", y_train)

    model = MyModel()

    # Define the parameter distributions
    param_grid = {
        "weight_eco": custom_discrete(0, 1, 0.1),
        "weight_env": custom_discrete(0, 1, 0.1),
        "weight_cof": custom_discrete(0, 1, 0.1),
        "weight_soc": custom_discrete(0, 1, 0.1),
    }

    # Lists to store error values and corresponding parameter values for each run
    error_values_list = []
    parameter_values_list = []
    predictions_list = []

    for _ in range(num_runs):
        bayesian_search = BayesSearchCV(model, search_spaces=param_grid,
                                cv=CustomCV(n_splits=2),
                                verbose=1, n_jobs=-1, n_iter=15, n_points=15)
        bayesian_search.fit(X_train, y_train)  # No need to flatten y_train for fitting

        # Use the best model to make predictions on the training data  
        best_model = bayesian_search.best_estimator_
        predictions = best_model.predict(X_train)

        # Compute the error between the predictions and the actual values
        error_value = error(predictions, y_train)

        # Append error value and corresponding parameters to the lists
        error_values_list.append(error_value)
        parameter_values_list.append(bayesian_search.best_params_)
        predictions_list.append(predictions)
    
    # Print predictions, actual values, and error
    print(f"Run {_+1}:")
    print("Predictions:", predictions)
    print("Shape of Y_train_municipality:", y_train.shape)
    print("Shape of y_train", y_train.shape)
    print("Shape of Xtrainall", X_train.shape)   
    print("Shape of predictions:", predictions.shape)
    print("Error:", error_value)

    # Save error values and parameter values to a CSV file
    save_results_to_csv(error_values_list, parameter_values_list, predictions_list)

    # Print error values
    print(f"Error_value: {error_value}")

    # Plot the fit of the best estimator
    plot_fit(X_train_years, y_train, best_model,
            error=error_values_list[-1],  
            params=bayesian_search.best_params_)