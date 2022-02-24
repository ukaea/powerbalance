import os
import pathlib

import pydantic
import pytest
import toml

from power_balance.validation.config import ConfigModel
from power_balance.validation.modelica_simulation_options import (
    PlasmaScenario,
    SimOptsModel,
)

_BAD_CONFIG = os.path.join(
    pathlib.Path(os.path.join(os.path.dirname(__file__))).parent, "bad_config.toml"
)

_GOOD_CONFIG = os.path.join(
    pathlib.Path(os.path.join(os.path.dirname(__file__))).parent, "test_config.toml"
)

_GOOD_SIMOPTS = os.path.join(
    pathlib.Path(os.path.join(os.path.dirname(__file__))).parents[1],
    "power_balance",
    "parameters",
    "simulation_options.toml",
)

_GOOD_PLASMA_PROFILE = os.path.join(
    pathlib.Path(os.path.join(os.path.dirname(__file__))).parents[1],
    "power_balance",
    "parameters",
    "plasma_scenario.toml",
)


@pytest.mark.validation
def test_config_validator_fail():
    """Test validation fails"""
    _config = toml.load(_BAD_CONFIG)
    with pytest.raises(pydantic.ValidationError):
        ConfigModel(**_config)


@pytest.mark.validation
def test_config_validator_pass():
    """Test validation fails"""
    _config = toml.load(_GOOD_CONFIG)
    ConfigModel(**_config)


@pytest.mark.validation
def test_simopts_validator_pass():
    _config = toml.load(_GOOD_SIMOPTS)
    SimOptsModel(**_config)


@pytest.mark.validation
def test_simopts_validator_fail():
    _config = toml.load(_GOOD_SIMOPTS)

    # Check that non-numeric or negative values are not allowed
    for key, value in _config.items():
        if isinstance(value, (int, float)):
            _test = _config.copy()
            _test[key] = -100
            with pytest.raises(pydantic.ValidationError):
                SimOptsModel(**_test)
            _test = _config.copy()
            _test[key] = f"{value}"
            with pytest.raises(pydantic.ValidationError):
                SimOptsModel(**_test)
        if key != "solver":
            _test = _config.copy()
            del _test[key]
            with pytest.raises(pydantic.ValidationError):
                SimOptsModel(**_test)

    _test = _config.copy()
    _test["not_an_option"] = 10
    with pytest.raises(pydantic.ValidationError):
        SimOptsModel(**_test)

    # Check bad solver is not allowed
    _test = _config.copy()
    _test["solver"] = "not_a_solver"
    with pytest.raises(pydantic.ValidationError):
        SimOptsModel(**_test)


@pytest.mark.validation
def test_plasma_validator_pass():
    _plasma_profile = toml.load(_GOOD_PLASMA_PROFILE)
    PlasmaScenario(**_plasma_profile)


@pytest.mark.validation
def test_plasma_validator_fail():
    _plasma_profile = toml.load(_GOOD_PLASMA_PROFILE)

    for key, value in _plasma_profile.items():
        _test = _plasma_profile.copy()
        del _test[key]
        with pytest.raises(pydantic.ValidationError):
            PlasmaScenario(**_test)
        _test = _plasma_profile.copy()
        _test[key] = f"{value}"
        with pytest.raises(pydantic.ValidationError):
            PlasmaScenario(**_test)
        _test = _plasma_profile.copy()
        _test[key] = float(value)
        with pytest.raises(pydantic.ValidationError):
            PlasmaScenario(**_test)

    _test = _plasma_profile.copy()
    _test["not_an_option"] = 10
    with pytest.raises(pydantic.ValidationError):
        PlasmaScenario(**_test)
