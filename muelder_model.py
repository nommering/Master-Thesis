import pynetlogo
import pandas as pd
import numpy as np

def run_model_with_parameters(parameters):
    """
    Run NetLogo model with given parameters and return the count of turtles with pv-yes? per tick.

    """
    # Start a NetLogo instance
    netlogo = pynetlogo.NetLogoLink(gui=False)

    # Load your model
    netlogo.load_model('Muelder_Filatova_Model.nlogo')

    # Load model data
    netlogo.command('load_data')

    # Set input parameters
    for key, value in parameters.items():
        if value is not None:  # Check if value is not None
            if isinstance(value, bool):
                value_str = str(value).lower()
            else:
                value_str = value
            netlogo.command(f'set {key} {value_str}')

    # Setup the model
    netlogo.command('setup')

    # Run the model with 'go' button which is a forever button
    num_ticks = 11  # Assuming you have 11 ticks
    solar_pv_installations_per_tick = []  # Renamed variable to snake_case
    for _ in range(num_ticks):
        netlogo.command('go')
        count_pv = netlogo.report('count turtles with [pv-yes? = true]')
        solar_pv_installations_per_tick.append(count_pv)

    # Remember to kill the link when you're done
    netlogo.kill_workspace()

    # Create dataframe with data per tick
    data_frame = pd.DataFrame({'count turtles with [pv-yes? = true]': solar_pv_installations_per_tick})

    # Convert to right data format
    data_frame = np.array(data_frame)
    data_frame = data_frame.reshape(-1)
    return data_frame
