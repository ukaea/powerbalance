#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Configuration File Validation
=============================

Validation of configurations/options given during the initialisation of a
PBM session.

Contents
========

Validator classes
-----------------

    SweepMode - allowed options for sweep mode
    ConfigModel - checks the API configuration file

Functions
---------

    validate_config - check a configuration given as a mutable mapping

"""

__date__ = "2021-06-10"

import enum
import os
import pathlib
import typing

import pydantic
import pydelica

import power_balance.validation as pbm_check
from power_balance.models import get_local_models
from power_balance.profiles import DEFAULT_PROFILES_DIR
from power_balance.utilities import flatten_dictionary


class SweepMode(str, enum.Enum):
    SET = "set"
    COMBINATIONS = "combinations"


class AssertLevels(str, enum.Enum):
    NEVER = "never"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    DEBUG = "debug"


NOT_A_PATH_REGEX = "^[^/]+$"


class ConfigModel(pydantic.BaseModel):
    models: typing.List[str] = pydantic.Field(
        ..., title="Models List", description="List of modelica models to run"
    )
    modelica_file_directory: pydantic.DirectoryPath = pydantic.Field(
        ...,
        title="Modelica File Directory",
        description="Directory containing modelica model files",
    )
    parameters_directory: pydantic.DirectoryPath = pydantic.Field(
        ...,
        title="Parameter File Directory",
        description="Directory containing parameters files",
    )
    profiles_directory: pydantic.DirectoryPath = pydantic.Field(
        ...,
        title="Profiles Directory",
        description="Directory containing profiles files",
    )
    simulation_options_file: str = pydantic.Field(
        ...,
        title="Simulation Options File",
        regex=NOT_A_PATH_REGEX,
        description="Identifier for the simulation options "
        "file in the parameters directory",
    )
    plasma_scenario_file: str = pydantic.Field(
        ...,
        title="Plasma Scenario File",
        regex=NOT_A_PATH_REGEX,
        description="Identifier for the plasma scenario options "
        "file in the parameters directory",
    )
    structural_params_file: str = pydantic.Field(
        ...,
        title="Structural Parameters File",
        regex=NOT_A_PATH_REGEX,
        description="Identifier for the structural parameters "
        "file in the parameters directory",
    )
    sweep_mode: SweepMode = pydantic.Field(
        SweepMode.SET,
        title="Sweep Mode",
        description="Mode to use when performing parameter sweep",
    )
    sweep: typing.Optional[typing.Dict[str, typing.Any]] = pydantic.Field(
        None,
        title="Sweep Definitions",
        description="Dictionary containing sweep values for parameters",
    )

    @pydantic.root_validator(pre=True)
    def replace_default(cls, values: typing.Dict):
        if values.get("modelica_file_directory") == "Default":
            modelica_file_dir = os.path.join(
                pathlib.Path(os.path.dirname(__file__)).parent, "models"
            )
            values["modelica_file_directory"] = modelica_file_dir

        # Default parameter directory is: power_balance/parameters
        if values.get("parameters_directory") == "Default":
            parameter_directory = os.path.join(
                pathlib.Path(os.path.dirname(__file__)).parent, "parameters"
            )
            values["parameters_directory"] = parameter_directory

        # Default location for profile setup/use is within the module
        # at power_balance/profiles/mat_profile_files
        if values.get("profiles_directory") == "Default":
            os.makedirs(DEFAULT_PROFILES_DIR, exist_ok=True)
            values["profiles_directory"] = DEFAULT_PROFILES_DIR

        return values

    @pydantic.validator("sweep")
    def check_sweep(cls, values: typing.Dict[str, typing.Any]):
        if not values:
            return values
        _flattened = flatten_dictionary(values)

        if any(not isinstance(i, list) for i in _flattened.values()):
            raise AssertionError(
                "Expected all values to be of type 'list' in sweep setup"
            )

        for param, value in _flattened.items():
            if any(not isinstance(i, type(value[0])) for i in value):
                raise AssertionError(
                    f"All values for sweep item {param} must be the same type"
                )

        return values

    @pydantic.root_validator(skip_on_failure=True)
    def check_model_list(cls, values: typing.Dict):
        modelica_file_dir = values["modelica_file_directory"]

        _local_models = list(
            get_local_models(
                model_file_dir=modelica_file_dir,
                names_only=True,
                session=pydelica.Session(),
                quiet=True,
            )
        )

        for model in values["models"]:
            if model not in _local_models:
                raise AssertionError(f"Model '{model}' not recognised")

        return values

    # 'dummy' validators which act as post-validation tidy up methods
    @pydantic.root_validator(skip_on_failure=True)
    def prepare_key_values(cls, values: typing.Dict):
        """Remove keys from sweep if not required"""
        if "sweep" in values:
            if values["sweep"]:
                values["sweep"] = flatten_dictionary(values["sweep"])
            else:
                del values["sweep"]
                values.pop("sweep_mode", None)
        return values

    @pydantic.root_validator(skip_on_failure=True)
    def posix_to_str(cls, values: typing.Dict):
        """Convert PosixPaths back to strings before continuing"""
        for key, value in values.items():
            if isinstance(value, pathlib.PosixPath):
                values[key] = str(value)
        return values

    class Config(pbm_check.ModelConfig):
        pass
