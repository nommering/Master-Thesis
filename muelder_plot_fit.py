"""
Module to define a function for plotting the fit of a regression model.
"""
from scipy.interpolate import interp1d
import matplotlib.pyplot as plt
import numpy as np

def plot_fit(X, y, model, error=None, params=None):
    """
    Plot the fit of a model against true values.

    """
    predictions = model.predict(X)  # Calculate predictions

    # Assuming y is a dataframe, convert it to a numpy array
    y = y.values.ravel() if hasattr(y, 'values') else y.ravel()

    # Original time axes
    x_orig = np.linspace(0, 1, len(y))
    x_pred = np.linspace(0, 1, len(predictions))

    # Common time axis for interpolation
    x_common_length = min(len(x_orig), len(x_pred))
    x_common = np.linspace(0, 1, x_common_length)

    # Convert to right data format
    predictions = np.array(predictions).reshape(-1)

    # Interpolate onto the common time axis
    f_true = interp1d(x_orig, y, kind='linear', fill_value='extrapolate')
    f_pred = interp1d(x_pred, predictions, kind='linear', fill_value='extrapolate')
    y_interp = f_true(x_common)
    predictions_interp = f_pred(x_common)

    # Plot the results
    plt.figure(figsize=(10, 6))
    plt.plot(x_common, y_interp, 'o', label='True values')
    plt.plot(x_common, predictions_interp, 'r', label='Fitted values')

    # Add error to plot if provided
    if error is not None:
        plt.text(0.02, 0.02, f'Error: {error}', transform=plt.gca().transAxes)

    # Add parameters to plot if provided
    if params is not None:
        param_text = ", ".join([f"{k}: {v}" for k, v in params.items()])
        props = {"boxstyle": 'round', "facecolor": 'wheat', "alpha": 0.5}
        plt.gca().text(0, -0.05, param_text, transform=plt.gca().transAxes, fontsize=10,
                       verticalalignment='top', bbox=props)

    # Set X-axis ticks to represent years 2012-2022
    years = range(2012, 2023)
    plt.xticks(x_common, years)

    plt.legend()
    plt.show()
