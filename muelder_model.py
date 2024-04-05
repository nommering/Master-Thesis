import pynetlogo
import pandas as pd
import numpy as np

def run_model_with_parameters(parameters):

    # Start a NetLogo instance
    netlogo = pynetlogo.NetLogoLink(gui=False)

    # Load your model
    netlogo.load_model('Muelder_Filatova_Model.nlogo')

    # Load model data
    netlogo.command('load_data')

    # Set input parameters
    netlogo.command(f'set Visibility {str(parameters["Visibility"]).lower()}')
    netlogo.command(f'set Sparking_Events {str(parameters["Sparking_Events"]).lower()}')
    netlogo.command(f'set Uncertainty {str(parameters["Uncertainty"]).lower()}')
    netlogo.command(f'set Info_Costs {str(parameters["Info_Costs"]).lower()}')
    netlogo.command(f'set Info_Costs_Revenue {str(parameters["Info_Costs_Revenue"]).lower()}')
    netlogo.command(f'set Info_Costs_Income {str(parameters["Info_Costs_Income"]).lower()}')
    netlogo.command(f'set Information_Threshold {str(parameters["Information_Threshold"]).lower()}')
    netlogo.command(f'set InputRandomSeed {parameters["InputRandomSeed"]}')
    netlogo.command(f'set initial_pv_share {parameters["initial_pv_share"]}')
    netlogo.command(f'set interest_rate {parameters["interest_rate"]}')
    netlogo.command(f'set pv_SDE_premium {parameters["pv_SDE_premium"]}')
    netlogo.command(f'set close_links {parameters["close_links"]}')
    netlogo.command(f'set random_links {parameters["random_links"]}')
    netlogo.command(f'set weight_eco {parameters["weight_eco"]}')
    netlogo.command(f'set weight_env {parameters["weight_env"]}')
    netlogo.command(f'set weight_soc {parameters["weight_soc"]}')
    netlogo.command(f'set influence_cost_time {parameters["influence_cost_time"]}')
    netlogo.command(f'set information_threshold_value {parameters["information_threshold_value"]}')

    # Setup the model
    netlogo.command('setup')

   # Run the model with 'go' button which is a forever button
    num_ticks = 11  # Assuming you have 11 ticks
    solarPVinstallations_per_tick = []
    for _ in range(num_ticks):
        netlogo.command('go')
        solarPVinstallations_per_tick.append(netlogo.report('count turtles with [pv-yes? = true]'))

    # Remember to kill the link when you're done
    netlogo.kill_workspace()

    # Create dataframe with data per tick
    data_frame = pd.DataFrame({'count turtles with [pv-yes? = true]': solarPVinstallations_per_tick})

    # Convert to right data format
    data_frame = np.array(data_frame)
    data_frame = data_frame.reshape(-1)
    return data_frame

# #Define your parameters
# parameters = {
#         "Visibility": True,
#         "Sparking_Events": False,
#         "Uncertainty": False,
#         "Info_Costs": True,
#         "Info_Costs_Revenue": False,
#         "Info_Costs_Income": True,
#         "Information_Threshold": False,
#         "InputRandomSeed": 10,
#         "initial_pv_share": 0.08,
#         "interest_rate": 0,
#         "pv_SDE_premium": 0,
#         "close_links": 5,
#         "random_links": 0,
#         "weight_eco": 0.2,
#         "weight_env": 0.3,
#         "weight_soc": 0.1,
#         "influence_cost_time": 1,
#         "information_threshold_value": 0,
#     }

# #Run the model with the parameters
# result_df = run_model_with_parameters(parameters)

# #Print the dataframe


    

