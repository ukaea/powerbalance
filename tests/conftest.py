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

MODELS_DIR = os.path.join(pathlib.Path(__file__).parents[1], "power_balance", "models")


def _model_list():
    # Loads input_parameter_ranges.json
    param_dict = toml.load(
        os.path.join(
            pathlib.Path(__file__).parent,
            "input_parameter_ranges.toml",
        )
    )

    _model_list = (
        ("CryogenicPlant", "CryogenicPower"),
        ("HCDSystemPkg", "HCDSystem"),
        ("Magnets", "MagnetPower"),
    )

    _range_list = []

    for model_package, model_name in _model_list:
        _model_dict = param_dict[model_name]
        _range_list.extend(
            (model_package, model_name, param, *range)
            for param, range in _model_dict.items()
        )

        return tuple(_range_list)

    return tuple(_range_list)


MODELS = _model_list()


@pytest.fixture
def test_directory():
    return os.path.dirname(__file__)


@pytest.fixture(scope="module")
def generate_profiles():
    with tempfile.TemporaryDirectory() as tempd:
        generate_all(tempd)
        yield tempd


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
