# -*- coding: utf-8 -*-
"""
Created on Wed Jul 14 14:42:26 2021

@author: Fin Christie, Timothy Jackson, Kristian Zarebski
"""

import os
import pathlib
from typing import List, Tuple

import pydelica
import pytest
import toml
from conftest import MODELS, MODELS_DIR
from pydelica import Session, exception

from power_balance.environment import MODELICA_ENVIRONMENT


def param_sets(model_name) -> Tuple[Tuple[float, float]]:
    _param_sets: List[Tuple[str, str]] = []
    # Loads input_parameter_ranges.json
    param_dict = toml.load(
        os.path.join(
            pathlib.Path(__file__).parent,
            "input_parameter_ranges.toml",
        )
    )

    _param_sets.extend((key, value) for key, value in param_dict[model_name].items())

    return tuple(_param_sets)


@pytest.fixture(scope="module")
def build_all_component_models(generate_profiles):
    # building model instance
    with Session() as session:
        session.use_libraries(MODELICA_ENVIRONMENT)

        for package_model in MODELS:
            package, model, _, _, _ = package_model
            _model_path = os.path.join(MODELS_DIR, f"{package}.mo")
            session.build_model(_model_path, f"{package}.{model}")
            _params = session.get_parameters(f"{package}.{model}")

            for path_parameter, path_value in _params.items():
                _value = path_value["value"]
                if "DataPath" in path_parameter and isinstance(_value, str):
                    session.set_parameter(os.path.join(generate_profiles, _value))
        yield session


# Tests input parameters, from a specified model, within their acceptable range
def inside_parameter_range_test(
    model_session: pydelica.Session,
    pkg_name: str,
    model_name: str,
    param_name: str,
    default_value: List[float],
    param_range: List[float],
):

    _lower_bound, _upper_bound = param_range

    # Test lower limit
    model_session.set_parameter(param_name, _lower_bound)
    model_session.simulate(model_name=f"{pkg_name}.{model_name}")

    # Test upper limit
    model_session.set_parameter(param_name, _upper_bound)
    model_session.simulate(model_name=f"{pkg_name}.{model_name}")

    # Reset parameter for session
    model_session.set_parameter(param_name, default_value[0])


# Checks that error assertion is raised when a negative value is
# given for a positive parameter
def parameter_negative_test(
    model_session: pydelica.Session,
    pkg_name: str,
    model_name: str,
    param_name: str,
    default_value: List[float],
):

    # Test below lower limit
    model_session.set_parameter(param_name, -1)

    with pytest.raises(exception.OMAssertionError):
        model_session.simulate(model_name=f"{pkg_name}.{model_name}")

    # Reset parameter for session
    model_session.set_parameter(param_name, default_value[0])


# Checks that an assertion warning was triggered when
# value positive but outside of range
def outside_parameter_range_test(
    model_session: pydelica.Session,
    pkg_name: str,
    model_name: str,
    param_name: str,
    default_value: List[float],
    param_range: List[float],
):

    # Temporarily switch to a fail on warning so we can detect
    # a warning is given
    model_session.fail_on_assert_level("warning")

    if param_range[0] > 0:
        _lower_val = param_range[0] / 2

        # Test lower limit
        model_session.set_parameter(param_name, _lower_val)

        with pytest.raises(exception.OMAssertionError):
            model_session.simulate(model_name=f"{pkg_name}.{model_name}")

    # Test upper limit
    _upper_val = param_range[1] * 1.5
    model_session.set_parameter(param_name, _upper_val)

    with pytest.raises(exception.OMAssertionError):
        model_session.simulate(model_name=f"{pkg_name}.{model_name}")

    # Reset parameter for session and fail level
    model_session.fail_on_assert_level("error")
    model_session.set_parameter(param_name, default_value[0])


@pytest.mark.parametrize("package,model_name,param,param_values,param_default", MODELS)
def test_negative_parameter_assert_error(
    build_all_component_models: pydelica.Session,
    package: str,
    model_name: str,
    param: str,
    param_values: List[float],
    param_default: float,
):
    parameter_negative_test(
        model_session=build_all_component_models,
        pkg_name=package,
        model_name=model_name,
        param_name=param,
        default_value=param_default,
    )


@pytest.mark.parametrize("package,model_name,param,param_values,param_default", MODELS)
def test_outside_parameter_assert_warning(
    build_all_component_models: pydelica.Session,
    package: str,
    model_name: str,
    param: str,
    param_values: List[float],
    param_default: float,
):
    outside_parameter_range_test(
        model_session=build_all_component_models,
        pkg_name=package,
        model_name=model_name,
        param_name=param,
        default_value=param_default,
        param_range=param_values,
    )


@pytest.mark.model_stability
@pytest.mark.parametrize("package,model_name,param,param_values,param_default", MODELS)
def test_inside_parameter_range(
    build_all_component_models: pydelica.Session,
    package: str,
    model_name: str,
    param: str,
    param_values: List[float],
    param_default: float,
):
    inside_parameter_range_test(
        model_session=build_all_component_models,
        pkg_name=package,
        model_name=model_name,
        param_name=param,
        default_value=param_default,
        param_range=param_values,
    )


@pytest.mark.model_stability
def test_struct_params(generate_profiles, build_all_component_models):
    Tokamak_MODEL = "Tokamak.Interdependencies"

    with Session() as session:
        session.use_libraries(MODELICA_ENVIRONMENT)

        input_file = os.path.join(MODELS_DIR, "Tokamak.mo")
        test_configs = toml.load(
            os.path.join(
                pathlib.Path(os.path.dirname(__file__)).parent,
                "test_struct_params_stability.toml",
            )
        )

        dependent_models = [
            file_name
            for file_name in os.listdir(MODELS_DIR)
            if ".mo" in file_name and file_name != os.path.basename(input_file)
        ]

        session.build_model(input_file, Tokamak_MODEL, dependent_models)

        for config_name in test_configs.keys():
            if config_name in ["Config_1", "Config_3", "Config_6"]:
                print(f"Test with {config_name}")

            params = session.get_parameters(Tokamak_MODEL)

            for parameter, value in params.items():
                if "DataPath" in parameter and isinstance(value["value"], str):
                    session.set_parameter(
                        parameter, os.path.join(generate_profiles, value["value"])
                    )

            session.simulate(Tokamak_MODEL)
