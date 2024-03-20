import pynetlogo
import pandas as pd
import numpy as np

def run_model_with_parameters(parameters):

    # Start a NetLogo instance
    netlogo = pynetlogo.NetLogoLink(gui=False)

    # Load your model
    netlogo.load_model('kam_solar_pv_adoption.nlogo')

    # Set input parameters
    netlogo.command(f'set neighbourhood_effect {str(parameters["neighbourhood_effect"]).lower()}')
    netlogo.command(f'set word_of_mouth {str(parameters["word_of_mouth"]).lower()}')
    netlogo.command(f'set tenants_can_install {str(parameters["tenants_can_install"]).lower()}')
    netlogo.command(f'set historic_houses_can_install_PV {str(parameters["historic_houses_can_install_PV"]).lower()}')
    netlogo.command(f'set households {parameters["households"]}')
    netlogo.command(f'set number_of_neighbours {parameters["number_of_neighbours"]}')
    netlogo.command(f'set stimulate_social_interaction {parameters["stimulate_social_interaction"]}')
    netlogo.command(f'set subsidy_PV {parameters["subsidy_PV"]}')
    netlogo.command(f'set PV_net_bill_after_adoption {parameters["PV_net_bill_after_adoption"]}')
    netlogo.command(f'set learning_rate_life_cycle_ghg_PV {parameters["learning_rate_life_cycle_ghg_PV"]}')
    netlogo.command(f'set PV_self_sufficiency_potential_global {parameters["PV_self_sufficiency_potential_global"]}')
    netlogo.command(f'set information_campaign_PV_year {parameters["information_campaign_PV_year"]}')
    netlogo.command(f'set sensitivity_analysis {str(parameters["sensitivity_analysis"]).lower()}')

    # Setup the model
    netlogo.command('setup')

    # Run the model with 'go' button which is a forever button
    netlogo.command('go')

    # Gather the output as a pandas dataframe
    # Gather the output as a pandas dataframe
    solarPVinstallations = np.array(netlogo.report('count pv-solar-panels'))
    data = {"count pv-solar-panels": solarPVinstallations}
    data_frame = pd.DataFrame(data, index=[0])  # Assuming data is a dictionary containing scalar values


    # Remember to kill the link when you're done
    netlogo.kill_workspace()

    return data_frame
