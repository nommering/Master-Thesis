from sklearn.model_selection import RandomizedSearchCV
from sklearn.base import BaseEstimator, RegressorMixin
from sklearn.model_selection import cross_val_score
from scipy.stats import randint, uniform
from kam_model import run_model_with_parameters
from kam_error import error
import numpy as np

class MyModel(BaseEstimator, RegressorMixin):
    def __init__(self, neighbourhood_effect="true", word_of_mouth="true", tenants_can_install="true",
                 historic_houses_can_install_PV="true", sensitivity_analysis="false", households=8001,
                 number_of_neighbours=5, stimulate_social_interaction=1, subsidy_PV=0,
                 PV_net_bill_after_adoption=90, learning_rate_life_cycle_ghg_PV=0,
                 PV_self_sufficiency_potential_global=1, information_campaign_PV_year=2023):
        self.neighbourhood_effect = neighbourhood_effect
        self.word_of_mouth = word_of_mouth
        self.tenants_can_install = tenants_can_install
        self.historic_houses_can_install_PV = historic_houses_can_install_PV
        self.sensitivity_analysis = sensitivity_analysis
        self.households = households
        self.number_of_neighbours = number_of_neighbours
        self.stimulate_social_interaction = stimulate_social_interaction
        self.subsidy_PV = subsidy_PV
        self.PV_net_bill_after_adoption = PV_net_bill_after_adoption
        self.learning_rate_life_cycle_ghg_PV = learning_rate_life_cycle_ghg_PV
        self.PV_self_sufficiency_potential_global = PV_self_sufficiency_potential_global
        self.information_campaign_PV_year = information_campaign_PV_year
        self.parameters = {
            'neighbourhood_effect': self.neighbourhood_effect,
            'word_of_mouth': self.word_of_mouth,
            'tenants_can_install': self.tenants_can_install,
            'historic_houses_can_install_PV': self.historic_houses_can_install_PV,
            'sensitivity_analysis': self.sensitivity_analysis,
            'households': self.households,
            'number_of_neighbours': self.number_of_neighbours,
            'stimulate_social_interaction': self.stimulate_social_interaction,
            'subsidy_PV': self.subsidy_PV,
            'PV_net_bill_after_adoption': self.PV_net_bill_after_adoption,
            'learning_rate_life_cycle_ghg_PV': self.learning_rate_life_cycle_ghg_PV,
            'PV_self_sufficiency_potential_global': self.PV_self_sufficiency_potential_global,
            'information_campaign_PV_year': self.information_campaign_PV_year,
        }


    def fit(self, X, y=None):
        return self

    def predict(self, X):
        self.predictions_ = run_model_with_parameters(self.parameters)
        return self.predictions_


    def score(self, X, y):
        if hasattr(self, 'predictions_'):
            predictions = self.predictions_
        else:
            predictions = self.predict(X)
        return -error(predictions, y)  # Note the negative sign because RandomizedSearchCV tries to maximize the score

def custom_discrete(low, high, step):
    return list(np.arange(low, high, step))

