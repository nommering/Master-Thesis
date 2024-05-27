from sklearn.model_selection import RandomizedSearchCV
from sklearn.base import BaseEstimator, RegressorMixin
from sklearn.model_selection import cross_val_score
from scipy.stats import randint, uniform
from muelder_model import run_model_with_parameters
from muelder_error import error
import numpy as np

class MyModel(BaseEstimator, RegressorMixin):
    def __init__(self, weight_eco=0.8, weight_env=0.3, 
                 weight_soc=0.4, weight_cof=0.3 ):
        self.weight_eco = weight_eco    
        self.weight_env = weight_env
        self.weight_soc = weight_soc
        self.weight_cof = weight_cof
        self.parameters = {
            'weight_eco': self.weight_eco,
            'weight_env': self.weight_env,
            'weight_cof': self.weight_cof,
            'weight_soc': self.weight_soc,
        }

    def fit(self, X, y=None):
        return self
    
    def fit(self, X, y=None):
        self.parameters = {
            'weight_eco': self.weight_eco,
            'weight_env': self.weight_env,
            'weight_cof': self.weight_cof,
            'weight_soc': self.weight_soc,

        }
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