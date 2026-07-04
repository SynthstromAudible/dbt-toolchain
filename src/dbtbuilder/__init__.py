"""dbtbuilder — fetch, verify, and package the DBT toolchain."""

import warnings

from tqdm import TqdmExperimentalWarning

warnings.filterwarnings("ignore", category=TqdmExperimentalWarning)

__version__ = "1.0.0"
