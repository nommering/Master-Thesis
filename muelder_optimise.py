from sklearn.model_selection import RandomizedSearchCV
from sklearn.base import BaseEstimator, RegressorMixin
from sklearn.model_selection import cross_val_score
from scipy.stats import randint, uniform
from muelder_model import run_model_with_parameters
from muelder_error import error
import numpy as np

class MyModel(BaseEstimator, RegressorMixin):
    def __init__(self, Visibility="true", Sparking_Events="false", Uncertainty="false", Info_Costs="true",
                 Info_Costs_Revenue="false", Info_Costs_Income="true",
                 Information_Threshold="false", InputRandomSeed=10,
                 initial_pv_share=0.08, interest_rate=0, pv_SDE_premium=0, close_links=5, random_links=0, weight_eco=0.2, weight_env=0.3,
                 weight_soc=0.1, influence_cost_time=1,
                 information_threshold_value=0):
        self.Visibility = Visibility
        self.Sparking_Events = Sparking_Events
        self.Uncertainty = Uncertainty
        self.Info_Costs = Info_Costs
        self.Info_Costs_Revenue = Info_Costs_Revenue
        self.Info_Costs_Income = Info_Costs_Income
        self.Information_Threshold = Information_Threshold
        self.InputRandomSeed = InputRandomSeed
        self.initial_pv_share = initial_pv_share
        self.interest_rate = interest_rate
        self.pv_SDE_premium = pv_SDE_premium 
        self.close_links = close_links
        self.random_links = random_links
        self.weight_eco = weight_eco
        self.weight_env = weight_env
        self.weight_soc = weight_soc
        self.influence_cost_time = influence_cost_time 
        self.information_threshold_value = information_threshold_value
        self.parameters = {
            'Visibility': self.Visibility,
            'Sparking_Events': self.Sparking_Events,
            'Uncertainty': self.Uncertainty,
            'Info_Costs': self.Info_Costs,
            'Info_Costs_Revenue': self.Info_Costs_Revenue,
            'Info_Costs_Income': self.Info_Costs_Income,
            'Information_Threshold': self.Information_Threshold,
            'InputRandomSeed': self.InputRandomSeed,
            'initial_pv_share': self.initial_pv_share,
            'interest_rate': self.interest_rate,
            'pv_SDE_premium': self.pv_SDE_premium,
            'close_links': self.close_links,
            'random_links': self.random_links,
            'weight_eco': self.weight_eco,
            'weight_env': self.weight_env,
            'weight_soc': self.weight_soc,
            'influence_cost_time': self.influence_cost_time,  
            'information_threshold_value': self.information_threshold_value
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
        return

def custom_discrete(low, high, step):
    return list(np.arange(low, high, step))

