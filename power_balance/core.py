#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Core session definitions
========================

Definitions for the Power Balance class which handles running of the
simulation procedure via specified inputs.

Contents
========

Session classes
---------------

    PowerBalance - main class which handles inputs and outputs, and simulation running

"""

__date__ = "2021-06-10"

import datetime
import glob
import itertools
import logging
import os
import platform
import re
import shutil
import subprocess
import tempfile
import typing

import numpy as np
import pandas as pd
import pkg_resources
import pydantic
import pydelica
import toml

import power_balance
import power_balance.browser as pbm_browser
import power_balance.configs as pbm_config
import power_balance.exceptions as pbm_exc
import power_balance.modelica_templating.pfmagnets as pbm_pfmagnet_templates
import power_balance.models as pbm_models
import power_balance.parameters as pbm_params
import power_balance.plotting.common as pbm_plot
import power_balance.plugins as pbm_plugin
import power_balance.profiles as pbm_profiles
import power_balance.validation.config as pbm_valid

logging.basicConfig()

config_default = os.path.join(
    os.path.dirname(__file__),
    "configs",
    "default_config.toml",
)

MATLAB_FILE_GLOB = "*.mat"


def get_plugins(plugin_order_list: typing.List[str] = None) -> typing.Tuple[str, ...]:
    _plugins = pbm_plugin.get_plugin_listing()

    if plugin_order_list is None:
        return tuple(map(str, _plugins.keys()))
    for plugin in plugin_order_list:
        if plugin.lower() not in [i.lower() for i in _plugins]:
            raise pbm_exc.InvalidConfigurationError(f"Plugin '{plugin}' not recognised")
    return tuple(
        plugin
        for plugin in _plugins
        if plugin.lower() in [i.lower() for i in plugin_order_list]
    )


def save_plugin_displays(output_directory: str) -> None:
    """Save the plugin display files so they can be loaded later

    Parameters
    ----------
    output_directory : str
        directory to save the display folder to
    """
    _display_files = glob.glob(os.path.join(pbm_plugin.PLUGIN_DISPLAY_DIR, "*"))
    _out_dir = os.path.join(output_directory, "plugin_displays")
    if not os.path.exists(_out_dir):
        os.mkdir(_out_dir)
    for display_file in _display_files:
        _out_file = os.path.join(_out_dir, os.path.basename(display_file))
        shutil.copy(display_file, _out_file)


class PowerBalance:
    """
    Main Power Balance class for running the Modelica models contained within
    the 'models' submodule. This class handles compiling and running, as well
    as the setting of parameter values.

    Attributes
    ----------
    power_data : typing.Dict[str, pd.DataFrame]
        power data stored after a simulation run (else None)
    configuration : typing.Dict[str, typing.Any]
        current configuration options as dictionary
    """

    def __init__(
        self,
        config: str = config_default,
        no_browser: bool = False,
        modelica_file_dir: str = "Default",
        profiles_directory: str = "Default",
        parameter_directory: str = "Default",
        print_intro: bool = False,
    ) -> None:
        """
        Parameters
        ----------
        config : str, optional
            configuration file to use for model selection and
            behaviour relating to this class
        no_browser : bool, optional
            boolean to set whether or not to launch the browser for graph
            display at the end of the run
        modelica_file_dir : str, optional
            location of modelica files containing models, default is the
            internal module model directory
        profiles_directory : str, optional
            directory containing '.mat' profiles, default is the internal
            module location
        parameter_directory : str, optional
            directory containing model parameter TOML files for inputs,
            by default 'Default'
        print_intro : bool, optional
            print intro message

        Raises
        ------
        AssertionError
            If 'profiles_directory' is None and not present in config
        AssertionError
            If 'parameters_directory' is None and not present in config
        AssertionError
            If 'modelica_file_directory' is None and not present in config
        """
        self._logger = logging.getLogger("PowerBalance")
        logging.getLogger("PyDelica.Compiler").setLevel(
            self._logger.getEffectiveLevel()
        )
        _pde_ll = pydelica.logger.OMLogLevel.NORMAL
        if self._logger.getEffectiveLevel() == logging.DEBUG:
            _pde_ll = pydelica.logger.OMLogLevel.DEBUG
        self._no_browser = no_browser
        self.power_data: typing.Dict[str, pd.DataFrame] = {}
        self.pydelica_session = pydelica.Session(_pde_ll)

        # PBM only compatible with MSL 3.2.3 at present but library switch
        # only works with UNIX based OSes
        if platform.system() != "Windows":
            self.pydelica_session.use_library("Modelica", "3.2.3")
        else:
            self._logger.warning(
                "Cannot set MSL version explicitly on Windows, "
                "assuming MSL is version 3.2.3"
            )

        self.configuration = pbm_config.read_options_from_config(config)

        self._plugins = get_plugins(self.configuration.get("plugins", None))

        self._output_dir = os.getcwd()
        self._bin_dir: str = ""
        self._models_list: typing.Dict[str, pbm_models.Model] = {}

        # If a profile directory is given as an argument this overrides any
        # given within the config file, hence update the configuration to
        # match that override. Else throw an exception as no such key is found.
        if profiles_directory:
            self.configuration["profiles_directory"] = profiles_directory

        if modelica_file_dir:
            self.configuration["modelica_file_directory"] = modelica_file_dir

        # If no parameter directory argument given, assume this is present in
        # the configuration, else throw exception
        if parameter_directory:
            self.configuration["parameters_directory"] = parameter_directory

        # Get time at session start, this forms the timestamp of all outputs
        _time_now = datetime.datetime.now()
        self._time_stamp = _time_now.strftime("%Y_%m_%d_%H_%M_%S")
        self._time_now_str = _time_now.strftime("%d/%m/%Y %H:%M:%S")

        # Retrieve the OpenModelica version
        self._om_version = (
            subprocess.check_output(
                [self.pydelica_session._compiler._omc_binary, "--version"],
                shell=False,
                text=True,
            )
            .split(" ")[1]
            .strip()
        )

        if print_intro:
            self._print_intro(config)
        else:
            print("Initialising session, please wait...")

        try:
            _validation = pbm_valid.ConfigModel(**self.configuration)
            self.configuration = _validation.dict()
        except pydantic.ValidationError as e:
            raise pbm_exc.ValidationError(e.json(), "session config") from e

        self._profile_sweep = self._check_for_profile_sweep()

        self._parameter_set = pbm_params.PBMParameterSet(**self.configuration)

        self._plasma_scenario = self._parameter_set.get_plasma_scenario()

        self._check_profiles()

        self._check_for_model_mods()
        self.read_models_from_directory()

    def _deduce_profile_max_values(self) -> typing.Dict[str, float]:
        """
        For the current parameter set deduce the maximum values for profiles

        Using the current parameter set the maximum values are obtained, these
        then being used during the generation of the default profiles
        """
        _max_val_mappings = {
            "thermal": "thermalpower",
            "tf": "tf.maxcurrent",
            "cs": "cs.maxcurrent",
        }
        _max_current_prefixes = [f"pf{i}" for i in range(1, 7)]
        _max_val_mappings.update(
            {prefix: f"{prefix}.maxcurrent" for prefix in _max_current_prefixes}
        )

        return {key: next(
                (
                    self._parameter_set.get_parameter(k)
                    for k in self._parameter_set
                    if max_val_search_str in k
                ),
                None,  # type: ignore
            ) for key, max_val_search_str in _max_val_mappings.items()}

    def _check_profiles(self) -> None:
        """Check if profiles exist within the directory, else generate them

        Raises
        ------
        AssertionError
            if no directory is specified
        """
        if not self.configuration["profiles_directory"]:
            raise AssertionError("No directory specified for 'profiles_directory'")

        # If mat files already exist in the profile directory assume
        # these have already been generated correctly
        if glob.glob(
            os.path.join(self.configuration["profiles_directory"], MATLAB_FILE_GLOB)
        ):
            return

        os.makedirs(self.configuration["profiles_directory"], exist_ok=True)

        self._logger.info(
            "The specified profiles directory '%s' does not contain"
            " any profile '.mat' files, these will be generated.",
            self.configuration["profiles_directory"],
        )

        plasma_tuple = tuple(self._plasma_scenario.values())

        _stop_time = self._parameter_set.get_simulation_options("stopTime")
        _time_step = self._parameter_set.get_simulation_options("stepSize")

        pbm_profiles.generate_all(
            output_directory=self.configuration["profiles_directory"],
            time_range=plasma_tuple,
            stop_time=_stop_time,
            time_step=_time_step,
            max_values=self._deduce_profile_max_values(),
        )

    def _check_for_model_mods(self) -> bool:
        """Checks if any model extending parameters have been set

        Checks if any parameters have been provided which require extension
        of one of the Modelica models, for example if more than 6 PF magnets
        have been given then additional magnets must be modelled. If such a
        modification exists the model directory to be read from is updated to
        a temporary location where these extending models are placed.
        """
        # Check if any modification to PF magnet model required, if no PF
        # parameters found at all, assume default model (6 x PF)
        try:
            _pf_magnet_ids = pbm_pfmagnet_templates.get_pfmagnet_ids_from_params(
                self._parameter_set
            )
        except pbm_exc.InvalidInputError:
            return False

        if all(i <= 6 for i in _pf_magnet_ids):
            return False

        self._logger.debug("Additional PF magnets specified, will update Magnets model")

        _model_dir = tempfile.mkdtemp()
        _model_files = glob.glob(
            os.path.join(self.configuration["modelica_file_directory"], "*.mo")
        )

        for mod_file in _model_files:
            shutil.copy(mod_file, os.path.join(_model_dir, os.path.basename(mod_file)))

        _resource_folder = os.path.join(
            self.configuration["modelica_file_directory"], "Resources", "Include"
        )

        if os.path.exists(_resource_folder):
            shutil.copytree(
                _resource_folder, os.path.join(_model_dir, "Resources", "Include")
            )

        with open(os.path.join(_model_dir, "Magnets.mo"), "w") as mod_f:
            mod_f.write(pbm_pfmagnet_templates.generate_pfmagnets(self._parameter_set))

        self.configuration["modelica_file_directory"] = _model_dir

        self._logger.debug("Updated model input directory to '%s'", _model_dir)

        return True

    def read_models_from_directory(self) -> None:
        """Read all Modelica '.mo' files from the directory given

        Reads the models from the directory given within the configuration
        this directory is changed to a temporary directory if any templating
        of the Modelica models is required (e.g. addition of PF magnets)

        Raises
        ------
        FileNotFoundError
            if the given directory does not exist
        """
        self._bin_dir, self._models_list = self._prepare_local_models()

        # Verify values have indeed been set correctly
        for parameter in self._parameter_set:
            # Skip valid non-modelica parameters
            if self._parameter_set.is_valid_non_modelica_param(parameter):
                continue
            _val = self._get_internal_parameter_value(parameter)
            if isinstance(_val, dict):
                raise AssertionError(
                    "Verification of retrieved parameter values failed, "
                    f"expected value for '{_val}' but returned dictionary"
                )

        # Check that the model names given within the config are recognised
        self._check_model_names(self.configuration)

    def _prepare_local_models(self):
        """typing.Tupleup all the models within the specified model directory and set
        parameters and input paths to the models.

        Returns
        -------
        str
            address of the temporary folder where they were compiled
        dict
            dictionary of the models as ModelicaSystem object
        """
        _mod_file_dir = self.configuration["modelica_file_directory"]
        if not os.path.exists(_mod_file_dir):
            raise FileNotFoundError(
                "The Modelica Files input directory '{}' "
                "does not exist".format(_mod_file_dir)
            )

        if "structural_params_file" in self.configuration:
            _struct_param_file = os.path.join(
                self.configuration["parameters_directory"],
                self.configuration["structural_params_file"],
            )
            if not os.path.exists(_struct_param_file):
                raise FileNotFoundError(
                    "Expected structural parameters file "
                    f"'{_struct_param_file}', but file does not exist."
                )
        else:
            _struct_param_file = ""

        # Get models contained within the specified models directory
        _local_models = pbm_models.get_local_models(
            session=self.pydelica_session,
            profile_dir=self.configuration["profiles_directory"],
            model_name_list=self.configuration["models"],
            model_file_dir=_mod_file_dir,
            parameter_set=self._parameter_set,
        )

        _binaries_folder = None

        for model in _local_models:
            if not _local_models[model].binary_folder:
                continue
            if not _binaries_folder:
                _binaries_folder = _local_models[model].binary_folder
            # Update paths to input files
            self._logger.info(
                "%s: Updating input file paths", _local_models[model].name
            )

            self.update_model_input_paths()

            # Apply parameter values within the parameter set to the Modelica
            # model system. As some parameters may not be specified within the
            # given parameter inputs, allow failure and use existing values for
            # this case
            self._logger.info(
                "%s: Applying Parameter values to model.",
                _local_models[model].name,
            )
            self.set_model_parameters(model_name=model, allow_param_failure=True)

            # Apply the simulation options to the given model
            self.apply_model_configuration(model)

            # Also add any parameters not present in the parameter files but
            # present in the model
            self._parameter_set.update_from_model(model, self.pydelica_session)

        return _binaries_folder, _local_models

    def _print_intro(self, config_file_addr: str) -> None:
        """Print information message at start of session

        Parameters
        ----------
        config_file_addr : str
            address of input configuration file
        """
        if "models" in self.configuration:
            _models_list = "- "
            _models_list += "\n\t -                  ".join(
                self.configuration["models"]
            )
        else:
            _models_list = "All"
            self.configuration["models"] = None

        if "sweep" in self.configuration:
            _sweep = self.configuration["sweep_mode"].title()
        else:
            _sweep = "False"

        if "structural_params_file" in self.configuration:
            _struct_param = self.configuration["structural_params_file"]
        else:
            _struct_param = "None"

        _intro_str = """
===============================================================================

                        Power Balance Model v{version}
            (with OpenModelica v{om_version} and PyDelica v{pyd_version})

                    Tokamak Power Infrastructure Simulation

                            {time}

    Config File                : {config_addr}
    Parameters Directory       : {param_dir}
    Profiles Directory         : {profile_dir}
    Simulation Options File    : ${dir_str}/{sim_params}
    Plasma Scenario File       : ${dir_str}/{plasma}
    Structural Parameters File : ${dir_str}/{struct}
    Modelica File Directory    : {model_dir}
    Mode                       : {mode}
    Model                      : {models}
    Sweep                      : {sweep}
    Plugins                    : {plugins}

===============================================================================
        """.format(
            time=self._time_now_str,
            om_version=self._om_version,
            pyd_version=pkg_resources.get_distribution("pydelica").version,
            version=power_balance.__version__,
            model_dir=self.configuration["modelica_file_directory"],
            profile_dir=self.configuration["profiles_directory"],
            dir_str="{Parameters Directory}",
            struct=_struct_param,
            param_dir=self.configuration["parameters_directory"],
            config_addr=config_file_addr,
            sim_params=self.configuration["simulation_options_file"],
            plasma=self.configuration["plasma_scenario_file"],
            models=_models_list,
            sweep=_sweep,
            mode="Browser" if not self._no_browser else "Terminal Only",
            plugins=", ".join(self._plugins) if self._plugins else "None",
        )
        print(_intro_str)

        self._profile_sweep = self._check_for_profile_sweep()

        if "sweep" in self.configuration:
            self._param_sweep_print()

        elif self._profile_sweep:
            self._profile_sweep_print()

    def _profile_sweep_print(self) -> None:
        _sweep_param_str = ""
        _sweep_profile_str = ""

        _out_print = {
            v[0]["param_name"]: [i["param_value"] for i in v]
            for v in self._profile_sweep.values()
        }
        _sweep_profile_str = (
            "\tProfile Sweep:\n\t - "
            + "\n\n\t - ".join(
                "\n \t\t".join([k, str(v)]) for k, v in _out_print.items()
            )
            + "\n"
        )
        _sweep_str = """
-------------------------------------------------------------------------------
                                Sweep Summary

{}{}
-------------------------------------------------------------------------------
            """.format(
            _sweep_param_str, _sweep_profile_str
        )
        self._logger.info(_sweep_str)

    def _param_sweep_print(self) -> None:
        _sweep_param_str = ""
        if "sweep" in self.configuration:
            _sweep_param_str = (
                "\n\tParameter Sweep:\n\t  - "
                + "\n\n\t  - ".join(
                    "\n  \t".join([k, str(v)])
                    for k, v in self.configuration["sweep"].items()
                )
                + "\n"
            )
        _sweep_profile_str = ""

        if self._profile_sweep:
            _out_print = {
                v[0]["param_name"]: [i["param_value"] for i in v]
                for v in self._profile_sweep.values()
            }
            _sweep_profile_str = (
                "\tProfile Sweep:\n\t - "
                + "\n\n\t - ".join(
                    "\n \t\t".join([k, str(v)]) for k, v in _out_print.items()
                )
                + "\n"
            )
        _sweep_str = """
-------------------------------------------------------------------------------
                                Sweep Summary

{}{}
-------------------------------------------------------------------------------
            """.format(
            _sweep_param_str, _sweep_profile_str
        )
        self._logger.info(_sweep_str)

    def _check_for_profile_sweep(self):
        _profile_dir = self.configuration["profiles_directory"]
        _profile_files = glob.glob(os.path.join(_profile_dir, MATLAB_FILE_GLOB))
        _swappable_profile_files = [i for i in _profile_files if "sweep" in i]

        _swappable_profile_dict = {}

        if _swappable_profile_files:
            for file_name in _swappable_profile_files:
                _var_metadata = re.findall(
                    r"_sweep_([a-z_]+)_([\-\d_]+)\.mat", file_name
                )
                if not _var_metadata:
                    raise AssertionError(
                        f"Failed to retrieve value data from '{file_name}' filename"
                        " during profile sweep, expected file in form like: "
                        "'currentPF6_sweep_1_6E5.mat'"
                    )
                _value_name = _var_metadata[0][0]
                _value_val = float(_var_metadata[0][1].replace("_", ""))
                _key_file = file_name.split("sweep")[0][:-1] + ".mat"
                if _key_file not in _swappable_profile_dict:
                    _swappable_profile_dict[_key_file] = []
                _swappable_profile_dict[_key_file].append(
                    {
                        "file_name": file_name,
                        "param_name": _value_name,
                        "param_value": _value_val,
                    }
                )

        return _swappable_profile_dict

    def add_models(self, model_path: str, model_names: typing.List[str] = None) -> None:
        """Read model(s) from a given OM file and add to simulation list.

        Parameters
        ----------
        model_path : str
            file address of the modelica file containing the models
        model_names : typing.List[str], optional
            list of models to import by name, by default all

        Raises
        ------
        FileNotFoundError
            If the given modelica file does not exist
        AssertionError
            If the API fails to identify any models within the given file
        """
        if not os.path.exists(model_path):
            raise FileNotFoundError(
                "Could not find Modelica file '{}'".format(model_path)
            )

        _models = pbm_models.extract_models_from_file(
            model_path,
            profile_dir=self.configuration["profiles_directory"],
            session=self.pydelica_session,
            model_name_list=model_names,
            parameter_set=self._parameter_set,
            original_model_dir=self.configuration["modelica_file_directory"],
        )

        if not _models:
            raise AssertionError(
                "File '{}' does not contain a recognised Modelica"
                " model".format(model_path)
            )

        self._models_list.update(_models)

        # If a list of model names has been given, update the parameter set
        # from the models given, else update from all models
        if model_names:
            for model in model_names:
                self._parameter_set.update_from_model(
                    model, pyd_session=self.pydelica_session
                )
        else:
            for model in _models:
                self._parameter_set.update_from_model(
                    model, pyd_session=self.pydelica_session
                )

    def remove_models(self, model_names: typing.List[str]) -> None:
        """Remove models from the `power_balance.PowerBalance` instance
        so they are not run during simulation

        Parameters
        ----------
        model_names : typing.List[str]
            list of names of models to remove
        """
        _param_names = list(self._parameter_set.keys())

        for model in model_names:
            if model in self.configuration["models"]:
                self.configuration["models"].remove(model)
            for parameter in _param_names:
                if model.lower() in parameter:
                    del self._parameter_set[parameter]

            del self._models_list[model]

    def _check_model_names(
        self, config_dict: typing.MutableMapping[str, typing.Any]
    ) -> None:
        """Confirm that models listed in configuration exist.

        Parameters
        ----------
        config_dict : typing.MutableMapping[str, typing.Any]
            dictionary containing configurations

        Raises
        ------
        ValueError
            If a given name within the configuration is not a recognised model
        """
        # If a 'models' key is not present in the config, run all models
        if "models" not in config_dict:
            self._logger.info(
                "No 'models' choice configuration specified, "
                " will run using all models"
            )
            config_dict["models"] = list(self._models_list.keys())
            return

        # If a list has been given confirm that all members of that
        # list are valid models
        self._logger.debug("Validating input model names")
        for name in self.configuration["models"]:
            if name not in self._models_list:
                _list_models = "\n\t- ".join(self._models_list)
                raise ValueError(
                    f"Unknown model '{name}' specified."
                    f" Available models are:\n\t- {_list_models}"
                )

    def set_parameter_value(self, parameter_name: str, value: typing.Any) -> typing.Any:
        """typing.Tuple a parameter within the parameter set to a given value.

        Parameters
        ----------
        parameter_name : str
            name of the parameter to be modified
        value : typing.Any
            new value to assign to that parameter

        Returns
        -------
        typing.Any
            the value read from the parameter after it has been set
        """
        return self._parameter_set.set_parameter(parameter_name, value)

    def update_model_input_paths(self) -> None:
        """Replace all variables defined as 'Path' variables with an absolute
        path in order to correctly read in the required inputs.
        """
        # NOTE: Input path variable types, this dictionary should be updated
        # if any other input path types are defined in any models. Using this
        # form allows input files to be placed in multiple locations.
        _locations_dict = {
            "currentdata": self.configuration["profiles_directory"],
            "powerdata": self.configuration["profiles_directory"],
        }

        for name, value in self.pydelica_session.get_parameters().items():
            for in_type, addr in _locations_dict.items():
                if in_type in name.lower() and "path" in name.lower():
                    self.pydelica_session.set_parameter(
                        name, os.path.join(addr, value["value"])
                    )

    def apply_model_configuration(self, model_name: str) -> None:
        """Applies the configuration within the configuration options provided.

        Parameters
        ----------
        model_name : str
            name of model to apply configuration to
        """
        self._logger.info("%s: Applying Configurations.", model_name)

        # Get only the simulation option parameters from the parameter set
        _simulation_options = self._parameter_set.get_simulation_options()

        _opt_strs = [
            "{}={}".format(parameter, value)
            for parameter, value in _simulation_options.items()
        ]

        self._logger.debug(
            "%s: Applying:\n\t- %s", model_name, "\n\t- ".join(_opt_strs)
        )

        # Apply these options to the model
        for option, val in _simulation_options.items():
            self.pydelica_session.set_simulation_option(option, val, model_name)

        self._logger.info("%s: Configurations applied successfully.", model_name)

    def modifiable_parameters(self) -> typing.List[str]:
        """Get a list of parameters that can be modified by the user

        Returns
        -------
        typing.List[str]
            list of parameters which can be modified
        """
        return list(self._parameter_set.keys())

    def get_parameters(
        self, model: str = None, include_undefined: bool = False
    ) -> typing.Any:
        """Retrieve all model parameters including those that cannot be modified

        Parameters
        ----------
        model : str, optional
            name of model to retrieve parameters from, by default first compiled
        include_undefined : bool, optional
            include parameters with a value of 'None', by default False

        Returns
        -------
        typing.Any
            a dictionary of the model parameters and their values
        """
        # If no model has been specified use the first compiled model
        if not model:
            _compiled = [k for k in self._models_list if self._models_list[k].compiled]
            model = _compiled[0]
        return {
            f'{model}.{name.replace("__", "")}': value["value"]
            for name, value in self.pydelica_session.get_parameters(model).items()
            if include_undefined or value["value"]
        }

    def _fuzzy_param_search(self, parameter_search_str: str) -> typing.Optional[typing.Any]:
        """Loosest form of parameter search for when parameter not directly recognised
        
        Parameters
        ----------
        parameter_search_str : str
            search string to find the parameter value

        Returns
        -------
        typing.Any
            value of the given parameter

        Raises
        ------
        power_balance.exceptions.TranslationError
            if the value extracted from the API is not the same as that of the
            same variable within the Modelica System.
        """
        for model in self._models_list:
            if not self._models_list[model].binary_folder:
                continue
            try:
                _var = "{}.{}".format(model.lower(), parameter_search_str.lower())
                _param = self._parameter_set.get_parameter(_var)

                _modelica_var_key = self._find_modelica_variable(
                    model, parameter_search_str.replace(model, "")
                )
                _param_set = self.pydelica_session.get_parameters(model)
                _modelica_var_value = _param_set[_modelica_var_key]["value"]

                if str(_modelica_var_value).lower() != str(_param).lower():
                    raise pbm_exc.TranslationError(
                        "Modelica internal parameter value does not "
                        "match that of API{}: {} != {}".format(
                            parameter_search_str.lower(),
                            _modelica_var_value,
                            _param,
                        )
                    )
                self._logger.debug(
                    "Modelica vs API:%s: %s == %s",
                    parameter_search_str,
                    _modelica_var_value,
                    _param,
                )
                return _param
            except pbm_exc.UnidentifiedParameterError:
                continue
        return None

    def _get_internal_parameter_value(
        self, parameter_search_str: str
    ) -> typing.Optional[typing.Any]:
        """Looser parameter search using a search string.

        This function searches the API parameter value storage for a parameter
        using a slightly more generic search string, it also checks
        that the value given in the parameter set object matches
        that retrieved from Modelica before returning.

        Parameters
        ----------
        parameter_search_str : str
            search string to find the parameter value

        Returns
        -------
        typing.Any
            value of the given parameter

        Raises
        ------
        power_balance.exceptions.TranslationError
            if the value extracted from the API is not the same as that of the
            same variable within the Modelica System.
        """
        _param = None

        try:
            _param = self._parameter_set.get_parameter(parameter_search_str.lower())

            for model in self._models_list:
                if not self._models_list[model].binary_folder:
                    continue
                if model.lower() in parameter_search_str.lower():
                    _modelica_var_key = self._find_modelica_variable(
                        model, parameter_search_str.replace(model, "")
                    )
                    _param_set = self.pydelica_session.get_parameters(model)
                    _modelica_var_value = _param_set[_modelica_var_key]["value"]

                    # Sanity check, if the value within the parameter set object
                    # is not the same as that retrieved from the model,
                    # this means the setting of parameters is wrong
                    if str(_modelica_var_value).lower() != str(_param).lower():
                        raise pbm_exc.TranslationError(
                            "Modelica internal parameter value does not "
                            "match that of API:{}: {} != {}".format(
                                parameter_search_str.lower(),
                                _modelica_var_value,
                                _param,
                            )
                        )
                    self._logger.debug(
                        "Modelica vs API:%s: %s == %s",
                        parameter_search_str,
                        _modelica_var_value,
                        _param,
                    )
                    return _param

        except pbm_exc.UnidentifiedParameterError:
            return self._fuzzy_param_search(parameter_search_str)

        return None

    def _find_modelica_variable(
        self, model_name: str, parameter_name: str
    ) -> typing.Any:
        """Search the given modelica system model object for a parameter matching
        a given search string

        Parameters
        ----------
        model_name : str
            name of the model to search
        parameter_name : str
            parameter name as string

        Returns
        -------
        str
            parameter name as defined within modelica

        Raises
        ------
        AssertionError
            If no match is found for the given search term
        """
        _param_str_ls: typing.List[str] = parameter_name.split(".")
        _param_str_ls[-1] = "__" + _param_str_ls[-1]
        _param_str: str = ".".join(i for i in _param_str_ls if i)
        _param_str = _param_str.replace(model_name.lower() + ".", "")

        for var in self.pydelica_session.get_parameters(model_name):
            if var.lower() == _param_str.lower():
                return var

        raise AssertionError(
            "Could not find a variable within Modelica matching" f" '{_param_str}'"
        )

    def set_model_parameters(
        self, model_name: str, allow_param_failure: bool = False
    ) -> None:
        """Read parameters from the parameter set object within the API and
        then assign them to the given Modelica System

        Parameters
        ----------
        model_name : str
            the name of the model
        allow_param_failure : bool, optional
            whether or not a failed parameter search during assignment
            throws an exception, by default False

        Raises
        ------
        power_balance.exceptions.ModelicaParameterError
            if any of the parameters within the parameter set cannot be
            assigned due to their being no Modelica parameter match
        """

        # In case parameters are deleted need to use a copy of the key list
        # as Python does not like dictionaries changing size during iteration
        _param_candidates = list(self._parameter_set.keys())

        for parameter in _param_candidates:
            # Skip recognised non-modelica parameters
            if self._parameter_set.is_valid_non_modelica_param(parameter):
                continue

            # Skip non base model parameters
            if model_name.lower() not in parameter.lower():
                continue

            _value = self._parameter_set.get_parameter(parameter)

            _parameter = parameter.replace(model_name.lower() + ".", "")

            _modelica_param_addr = self._find_modelica_variable(model_name, _parameter)

            if not _modelica_param_addr:
                if allow_param_failure:
                    self._logger.warning(
                        "Parameter '%s' read from inputs is not recognised by any"
                        " of the currently registered models and will be ignored.",
                        _parameter,
                    )
                    del self._parameter_set[parameter]
                    continue
                raise pbm_exc.ModelicaParameterError(_parameter)

            self.pydelica_session.set_parameter(_modelica_param_addr, _value)

    def save_parameters(self, output_directory: str) -> None:
        """Save parameters for the session so they can be loaded later

        Parameters
        ----------
        output_directory : str
            directory to save the parameter sets to
        """
        _param_dir = os.path.join(output_directory, "parameters")
        self._parameter_set.save_to_directory(_param_dir)

    def save_configuration(self, output_directory: str) -> None:
        """Save configuration for the session so it can be loaded later

        Parameters
        ----------
        output_directory : str
            directory to save the config folder to
        """
        if not os.path.exists(os.path.join(output_directory, "configs")):
            os.mkdir(os.path.join(output_directory, "configs"))
        _config_out = os.path.join(output_directory, "configs", "configuration.toml")
        toml.dump(self.configuration, open(_config_out, "w"))

    def save_profiles(self, output_directory: str) -> None:
        """Save profiles for the session so they can be loaded later

        Parameters
        ----------
        output_directory : str
            directory to save the profile folder to
        """
        _profiles = glob.glob(
            os.path.join(self.configuration["profiles_directory"], MATLAB_FILE_GLOB)
        )
        _out_dir = os.path.join(output_directory, "profiles")
        if not os.path.exists(_out_dir):
            os.mkdir(_out_dir)
        for profile_file in _profiles:
            _out_file = os.path.join(_out_dir, os.path.basename(profile_file))
            shutil.copy(profile_file, _out_file)

    def load_parameters(self, directory: str) -> None:
        """Load parameters from a given directory specifying which file is the
        simulation options file

        Parameters
        ----------
        directory : str
            directory containing all parameter TOML files

        Raises
        ------
        FileNotFoundError
            if the given directory does not exist
        """
        if not os.path.exists(directory):
            raise FileNotFoundError("Location '{}' does not exist.".format(directory))

        self._parameter_set.load_from_directory(directory)

    def get_power(self, model_name: str) -> pd.DataFrame:
        """Retrieve the power results from a Modelica model after simulation

        Parameters
        ----------
        model_name : str
            name of the Modelica model

        Returns
        -------
        pd.DataFrame
            dataframe containing the power values for each of the subsystems

        Raises
        ------
        AssertionError
            if the model solution variables do not match the expected form
        """

        if model_name not in self.pydelica_session.get_solutions():
            raise AssertionError(
                "Failed to retrieve solutions for model '{}', "
                "available solutions are: {}".format(
                    model_name,
                    list(self.pydelica_session.get_solutions().keys()),
                )
            )

        _solution = self.pydelica_session.get_solutions()[model_name]

        if not isinstance(_solution, pd.DataFrame):
            raise TypeError(
                "Expected DataFrame for model solutions"
                " but got {}".format(type(_solution))
            )

        _elec_con_columns = [
            col for col in _solution.columns if "ElecPowerConsumed" in col
        ]

        _elec_gen_columns = [col for col in _solution.columns if "ElecPowerGen" in col]

        _df = pd.DataFrame()

        self._logger.info("%s: Retrieving solutions", model_name)

        for sol in _elec_con_columns:
            # Assumes composite in the form 'magnetpower.ElecPowerConsumed'
            try:
                col_name = sol.split(".")[0] if "." in sol else sol
                if (
                    self._models_list[model_name].submodels
                    and col_name in self._models_list[model_name].submodels
                ):
                    _submodels = self._models_list[model_name].submodels
                    col_name = _submodels[col_name].split(".")[-1]
            except IndexError:
                raise AssertionError(
                    "Expected model solutions to be in the form 'model.variable'",
                    " but got: {}".format(sol),
                )
            _df[col_name.lower()] = _solution[sol]

        _net_power = -_df.loc[:, _df.columns != "time"].sum(1)
        _df["netpowerconsumption"] = np.abs(_net_power)

        _df["time"] = _solution["time"]

        for column in _elec_gen_columns:
            new_col_name = column.split(".")[0] if "." in column else column
            _df[new_col_name] = _solution[column]
            _net_power += _solution[column]

        _df["netpowergeneration"] = _net_power

        # Modelica can produce multiple values for a given value
        # only keep one for each interval
        _step_size = self._parameter_set.get_simulation_options("stepSize")
        _df["time"] = round(_df["time"] / _step_size) * _step_size
        _df = _df.drop_duplicates(subset=["time"], ignore_index=True)

        return _df

    def _run_models(
        self, sweep_dict_args: typing.Dict = None
    ) -> typing.Dict[str, pd.DataFrame]:
        """Run simulation for all models, if the session is a parameter sweep
        append each iteration to the current dataframe

        Parameters
        ----------
        sweep_dict_args : typing.Dict, optional
            dictionary containing ranges of parameters to perform a parameter
            sweep, by default None (no sweep)

        Returns
        -------
        typing.Dict[str, pd.DataFrame]
            dictionary containing dataframes for each model simulated
        """
        _power_data: typing.Dict[str, pd.DataFrame] = {}
        for model_name in self.configuration["models"]:
            self._logger.info(
                "%s: Simulating and retrieving power data from model.",
                model_name,
            )

            self.pydelica_session.simulate(model_name)

            _power_data[model_name] = self.get_power(model_name)

            if sweep_dict_args:
                for variable, value in sweep_dict_args.items():
                    _power_data[model_name][variable.lower()] = [value] * len(
                        _power_data[model_name]
                    )

                    # Verify variable retrieval successful
                    self._get_internal_parameter_value(variable)

            self._logger.info("%s:SUCCESS: Run complete.", model_name)

        return _power_data

    def _sweep_on_profiles(
        self, index: int, output_dfs: typing.Dict[str, pd.DataFrame], model_name: str
    ) -> typing.Dict[str, float]:
        _iteration_dict: typing.Dict[str, float] = {}
        for mat_file in self._profile_sweep:
            self._logger.debug(
                "ProfileFileSweep: Replacing '%s' with '%s'",
                mat_file,
                self._profile_sweep[mat_file][index]["file_name"],
            )
            if os.path.exists(mat_file):
                os.remove(mat_file)
            os.rename(self._profile_sweep[mat_file][index]["file_name"], mat_file)
            _name = self._profile_sweep[mat_file][index]["param_name"]
            _value = self._profile_sweep[mat_file][index]["param_value"]
            _iteration_dict[_name] = _value

        self._logger.info(
            "Running profile sweep iteration:\n\t- %s",
            "\n\t- ".join(
                ": ".join([str(k), str(v)]) for k, v in _iteration_dict.items()
            ),
        )

        for var in _iteration_dict:
            _col = len(output_dfs[model_name]) * [_iteration_dict[var]]
            output_dfs[model_name][var] = _col

        return _iteration_dict

    def run_simulation(
        self,
        output_directory: str = "",
        sweep_dict: typing.Optional[typing.Dict[str, typing.Any]] = None,
    ) -> None:
        """Acts as a driver for the back end functions handling
        the interface with OpenModelica

        Parameters
        ----------
        output_directory : str
            directory for output files
        sweep_dict : typing.Dict[str, typing.Dict[str, typing.Tuple]], optional
            perform sweep for the given parameters using a
            dictionary containing range information, by default None (no sweep)

        Raises
        ------
        RuntimeError
            if retrieval of power data fails after the models have been run
        """

        self._logger.info("-------- RUNNING POWER BALANCE SIMULATIONS --------")

        # NOTE: 'input' mid run removed, hence reinitialisation not required
        # as the user cannot now modify parameters during the run

        # If a parameter sweep is defined re-run the simulation for each
        # combination across the phase space appending the results
        # else run a single time
        _no_sweep = not sweep_dict and "sweep" not in self.configuration
        # If another directory has been specified for simulating we need to
        # update the relevant member variable so the browser works
        if output_directory:
            self._output_dir = output_directory

        if _no_sweep := _no_sweep and not self._profile_sweep:
            self.power_data.update(self._run_models())
        elif "sweep" not in self.configuration and self._profile_sweep:
            self._logger.info("Performing profile only sweep in 'set' mode")
            _n_vals = len(list(self._profile_sweep.values())[0])

            for model in self._models_list.keys():
                if not self._models_list[model].compiled:
                    continue

                for i in range(_n_vals):

                    _output_dfs = self._run_models()

                    self._sweep_on_profiles(i, _output_dfs, model)

                    if model in self.power_data:
                        self.power_data[model] = pd.concat(
                            [
                                self.power_data[model],
                                _output_dfs[model],
                            ],
                            ignore_index=True,
                        )
                    else:
                        self.power_data[model] = _output_dfs[model]
        else:
            self._perform_sweeps(sweep_dict)
        if not self.power_data:
            raise RuntimeError("Failed to retrieve power data for this run.")

        self._write_outputs(output_directory)

    def _collate_sweep_run_dfs(self, index: int, combination_dict: typing.Dict):
        for model in self._models_list:
            # If the model is a submodel skip
            if not self._models_list[model].binary_folder:
                continue

            _result_dict = self._run_models(combination_dict)

            # Tedious way of swapping profile files as part of a sweep
            # currently only works in 'set' mode
            if self.configuration["sweep_mode"] == "set" and self._profile_sweep:
                self._sweep_on_profiles(index, _result_dict, model)

            if model in self.power_data:
                self.power_data[model] = pd.concat(
                    [self.power_data[model], _result_dict[model]], ignore_index=True
                )
            else:
                self.power_data[model] = _result_dict[model]
    
    def _assemble_sweep_combos(self, sweep_dict: typing.Dict, var_len: int):
        for var_val_list in sweep_dict.values():
            if len(var_val_list) != var_len:
                raise AssertionError(
                    "For sweep of type 'set' all parameter statements"
                    " must have the same number of elements: "
                    "{} != {}".format(len(var_val_list), var_len)
                )

        return [
            (value[i] for value in sweep_dict.values()) for i in range(var_len)
        ]


    def _perform_sweeps(self, sweep_dict):
        # If a sweep dict is not specified by argument, retrieve it from
        # the config
        if "sweep" in self.configuration:
            sweep_dict = self.configuration["sweep"]
        elif sweep_dict:
            sweep_dict.update(self.configuration["sweep"])
            self.configuration["sweep"] = sweep_dict

        # Should not enter this statement but here to cover possibility
        if not sweep_dict:
            raise RuntimeError("Failed to create sweep cut combinations")

        self._logger.info("Performing parameter sweep")

        _var_len = len(list(sweep_dict.values())[0])

        _all_combinations: typing.Iterable[typing.Any] = []

        if self.configuration["sweep_mode"] == "set":
            _all_combinations = self._assemble_sweep_combos(sweep_dict, _var_len)
        else:
            _all_combinations = itertools.product(*sweep_dict.values())

        for i, combo in enumerate(_all_combinations):
            _dict_combo = dict(zip(sweep_dict.keys(), combo))
            self._logger.info(
                "Running Combination:\n\t- %s",
                "\n\t- ".join("{}={}".format(k, v) for k, v in _dict_combo.items()),
            )

            # typing.Tuple parameters in the parameter set to values for this sweep
            for name, value in _dict_combo.items():
                self.set_parameter_value(name, value)

            for model in self._models_list:
                # If the model is a submodel skip
                if not self._models_list[model].binary_folder:
                    continue

                self.set_model_parameters(model_name=model)
            
            self._collate_sweep_run_dfs(i, _dict_combo)

    def _write_outputs(self, output_directory: str):
        """Prepare output directory structure and write outputs of a
        simulation run to it

        Parameters
        ----------
        output_directory : str
            directory to write output files to
        """
        _session_directory = os.path.join(
            output_directory, "pbm_results_{}".format(self._time_stamp)
        )

        if not os.path.exists(_session_directory):
            os.makedirs(_session_directory)
            os.mkdir(os.path.join(_session_directory, "data"))
            os.mkdir(os.path.join(_session_directory, "parameters"))
            if self._plugins:
                os.mkdir(os.path.join(_session_directory, "plugin_displays"))

        # record all session data
        self._logger.info("Exporting to HDF5 format")
        self.write_data(_session_directory)
        self._logger.info("Saving parameter values for session.")
        self.save_parameters(_session_directory)
        self._logger.info("Saving configuration for session.")
        self.save_configuration(_session_directory)
        self._logger.info("Saving profiles for session.")
        self.save_profiles(_session_directory)

        if self._plugins:
            self._logger.info("Saving plugin display files")
            save_plugin_displays(_session_directory)

        # Create plots
        self.plot_results(_session_directory)

        self._logger.info(
            "Run completed succesfully. Outputs written to '%s'",
            _session_directory,
        )

    def plot_results(self, output_directory: str) -> typing.List[str]:
        """Create all plots images for all power variables.

        Parameters
        ----------
        output_directory : str
            directory to save created images.

        Returns
        -------
        typing.List[str]
            list of output plot file names
        """
        _plot_dir = os.path.join(output_directory, "plots")

        if not os.path.exists(_plot_dir):
            os.mkdir(_plot_dir)

        _plot_list: typing.List[str] = []

        for dataset in self.power_data:
            # In the case of a parameter sweep only plot the last entry
            if "sweep" in self.configuration:
                _data_frame = self.power_data[dataset].copy()
                for param, value in self.configuration["sweep"].items():
                    _data_frame = _data_frame[_data_frame[param.lower()] == value[-1]]
            else:
                _data_frame = self.power_data[dataset].copy()

            _time = _data_frame["time"]
            for variable in _data_frame.columns:
                if variable == "time":
                    continue
                _file_name = os.path.join(
                    _plot_dir,
                    "{}_{}.jpg".format(
                        dataset.replace(".", "_"), variable.replace(".", "_")
                    ),
                )

                _data = _data_frame[variable]

                _plot_list.append(_file_name)

                # plots power against time and saves to a .jpg file
                pbm_plot.plot_to_image(_time, _data, "Time/s", "Power/W", _file_name)

        self._logger.info(
            "Plotting:SUCCESS: The following files were created:\n\t- %s",
            "\n\t- ".join(_plot_list),
        )

        return _plot_list

    def write_data(self, output_directory: str) -> None:
        """Write the resulting data frames to a HDF5 file which allows inclusion
        of various key metadata alongside the datasets

        Parameters
        ----------
        output_directory : str
            location to write output data files
        """
        _output_hdf5_file = os.path.join(output_directory, "data", "session_data.h5")

        _hdf_store = pd.HDFStore(_output_hdf5_file)

        # Write dataset to HDF5 using the model name as a key
        for name, dataset in self.power_data.items():
            _hdf_store.put(name.lower().replace(".", "_"), dataset)

            _meta_data = {
                "pbm_version": power_balance.__version__,
                "time": self._time_now_str,
                "om_version": self._om_version,
            }

            for key, value in _meta_data.items():
                setattr(
                    _hdf_store.get_storer(name.lower().replace(".", "_")).attrs,
                    key,
                    value,
                )

        _hdf_store.close()

    def launch_browser(self) -> None:
        """Opens local web browser to view result plots"""
        self._logger.info("Initialising Plot Display")
        _browser = pbm_browser.PBMBrowser(
            os.path.join(self._output_dir, "pbm_results_{}".format(self._time_stamp))
        )
        _browser.build(self._plasma_scenario)
        _browser.launch()
