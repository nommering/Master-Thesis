import numpy as np
from sklearn.model_selection import BaseCrossValidator

class CustomCV(BaseCrossValidator):
    def __init__(self, n_splits=5):
        self.n_splits = n_splits

    def get_n_splits(self, X=None, y=None, groups=None):
        return self.n_splits

    def split(self, X, y=None, groups=None):
        n_samples = len(X)
        fold_sizes = ((n_samples // self.n_splits) * np.ones(self.n_splits, dtype=int))
        fold_sizes[:n_samples % self.n_splits] += 1
        current = 0
        for fold_size in fold_sizes:
            start, stop = current, current + fold_size
            current = stop
            test_indices = np.arange(start, stop)
            if start == 0:
                train_indices = []
            else:
                train_indices = np.arange(0, start)
            yield train_indices, test_indices