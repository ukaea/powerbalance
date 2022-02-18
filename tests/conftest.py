import glob
import os
import pathlib
import shutil
import tempfile

import pytest
import toml

from power_balance.parameters import PBMParameterSet
from power_balance.profiles import generate_all

PROFILES_DIR = os.path.join(
    pathlib.Path(os.path.dirname(__file__)).parent,
    "power_balance",
    "profiles",
    "mat_profile_files",
)


@pytest.fixture
def test_directory():
    return os.path.dirname(__file__)


@pytest.fixture(scope="module")
def generate_profiles():
    # Checks if profiles_directory exists, creates it if it doesn't
    # generates .mat profiles within profiles_directory
    if not glob.glob(os.path.join(PROFILES_DIR, "*.mat")):
        if not os.path.exists(PROFILES_DIR):
            os.mkdir(PROFILES_DIR)
        generate_all(PROFILES_DIR)
    return PROFILES_DIR


@pytest.fixture()
def parameter_obj_struct(test_directory):
    _tempdir = tempfile.mkdtemp()
    _model_name = "StructParamTestModel"
    shutil.copy(
        os.path.join(test_directory, f"{_model_name}.mo"),
        os.path.join(_tempdir, f"{_model_name}.mo"),
    )

    shutil.copy(
        os.path.join(
            pathlib.Path(test_directory).parent,
            "power_balance",
            "parameters",
            "simulation_options.toml",
        ),
        os.path.join(_tempdir, "simulation_options.toml"),
    )

    shutil.copy(
        os.path.join(
            pathlib.Path(test_directory).parent,
            "power_balance",
            "parameters",
            "plasma_scenario.toml",
        ),
        os.path.join(_tempdir, "plasma_scenario.toml"),
    )

    shutil.copy(
        os.path.join(test_directory, "test_struct_params.toml"),
        os.path.join(_tempdir, "structural_parameters.toml"),
    )

    _config = {
        "parameters_directory": _tempdir,
        "modelica_file_directory": _tempdir,
        "plasma_scenario_file": "plasma_scenario.toml",
        "simulation_options_file": "simulation_options.toml",
        "structural_params_file": "structural_parameters.toml",
        "profiles_directory": "Default",
    }

    return PBMParameterSet(**_config)


@pytest.fixture()
def parameter_obj_norm(test_directory):
    _config = os.path.join(test_directory, "test_config.toml")
    _config_dict = toml.load(_config)
    _config_dict["parameters_directory"] = os.path.join(
        pathlib.Path(test_directory).parent, "power_balance", "parameters"
    )
    return PBMParameterSet(**_config_dict)
