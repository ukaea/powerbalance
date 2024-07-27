#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Parameter Set
=============

Create a parameter set object which contains all parameters defined by
the user and is then used to assign them to the model. Also stores any
additional unspecified parameters and writes all of them to file.

Contents
========

Parameter classes
=================

    PBMParameterSet - container for power balance models parameters

"""

__date__ = "2021-06-08"

import glob
import logging
import os
import re
import shutil
import tempfile
import typing
from collections.abc import MutableMapping
from typing import Optional

import pydantic
import pydelica
import toml

import power_balance.exceptions as pbm_exc
import power_balance.utilities as pbm_util
import power_balance.validation.modelica_simulation_options as pbm_mso

logging.basicConfig()

DEFAULT_PARAM_DIR = os.path.dirname(__file__)


def remove_do_not_edit_header(parameter_file: str, output_file: str) -> None:
    """Removes the DO NOT EDIT header when copying a parameter file"""
    _file_lines = open(parameter_file).readlines()

    # Do not edit header covers two lines so need index of the actual statement
    # line and the next
    _dne_line = [i for i, line in enumerate(_file_lines) if "DO NOT EDIT" in line]
    _dne_line.extend(line_index + 1 for line_index in _dne_line.copy())
    _out_lines = _file_lines.copy()
    for line_i in _dne_line:
        _out_lines.remove(_file_lines[line_i])
    with open(output_file, "w") as out_f:
        out_f.writelines(_out_lines)


class PBMParameterSet(MutableMapping):
    """Class for storing all parameter values read from TOML files within a
    directory, these then being the inputs to the Power Balance models
    within Modelica. The parameters are stored as a 'flattened' dictionary,
    for example:

    model1.toml -- toml --> dict_1[{'X': 'Y', 'Z': {'W': 'V'}}]

    model2.toml -- toml --> dict_2[{'A': {'B': 'C'}}]

    would become:

    {'model1.X': 'Y', 'model1.Z.W': 'V', 'model2.A.B': 'C'}

    when saving the parameters, the dictionary is re-expanded and each TOML
    file written.

    Parameter sets are initialised using TOML files from a given
    directory and defining one file as the Modelica internal parameters
    (i.e. containing variables such as 'stepSize' etc. which are
    embedded into all Modelica model runs)
    """

    def __init__(
        self,
        parameters_directory: str,
        simulation_options_file: str,
        plasma_scenario_file: str,
        structural_params_file: str = "",
        modelica_file_directory: str = "",
        **kwargs,
    ) -> None:
        """
        Parameters
        ----------
        simopts_filename : str
            TOML file containing simulation options for
                               Modelica system (base filename only)
        parameter_directory : str
            Directory containing all parameter TOML files
        """
        self._logger = logging.getLogger("PowerBalance.Parameters")
        self._model_param_files: typing.List[str] = []
        self._input_files: typing.Dict[str, str] = {
            "simulation_options_file": simulation_options_file,
            "parameters_directory": parameters_directory,
            "plasma_scenario_file": plasma_scenario_file,
            "structural_params_file": structural_params_file,
            "modelica_file_directory": modelica_file_directory,
        }

        self._simopts = self.load_simulation_options()

        # For the case where an extra parameter is defined which is not used
        # in the Modelica itself, this member keeps track of such special
        # case parameters
        self._extra_params: typing.List[str] = []

        self._parameters = self.load_modelica_parameters()

        self._plasma_scenario = self.load_plasma_scenario()

        self._structural_parameters = self.load_structural_parameters()

    def load_from_directory(self, parameter_directory: str) -> None:
        """Load parameters from an alternative directory

        Parameters
        ----------
        parameter_directory : str
            parameter directory path
        """
        if not os.path.exists(parameter_directory):
            raise FileNotFoundError(
                f"Cannot load parameters from directory '{parameter_directory}', "
                "directory does not exist."
            )
        self._input_files["parameters_directory"] = parameter_directory
        self._simopts = self.load_simulation_options()
        self._parameters = self.load_modelica_parameters()
        self._plasma_scenario = self.load_plasma_scenario()
        self._structural_parameters = self.load_structural_parameters()

    def get_file_location(self, file_label: str) -> typing.Optional[str]:
        """Return input file path

        Parameters
        ----------
        file_label : str
            label of input file

        Returns
        -------
        str
            input file path for given label
        """
        param_dir_key = "parameters_directory"

        if file_label not in self._input_files:
            raise KeyError(
                f"Cannot retrieve item '{file_label}' from parameter set "
                f"inputs. Allowed values are: {self._input_files.keys()}"
            )

        if not self._input_files[param_dir_key]:
            raise pbm_exc.InvalidConfigurationError(
                f"Expected '{param_dir_key}' entry in configuration"
            )

        if file_label == param_dir_key or not self._input_files[file_label]:
            return self._input_files[file_label]
        else:
            return os.path.join(
                self._input_files[param_dir_key], self._input_files[file_label]
            )

    def __delitem__(self, parameter_name: str) -> None:
        """Delete item from parameter set

        Parameters
        ----------
        parameter_name : str
            name of parameter to remove
        """
        del self._parameters[parameter_name]

    def __getitem__(self, parameter_name: str):
        """Retrieve item from the parameter set

        Parameters
        ----------
        parameter_name : str
            name of the parameter to retrieve

        Returns
        -------
        typing.Any
            value for the given parameter
        """
        return self._parameters[parameter_name]

    def __iter__(self):
        return iter(self._parameters)

    def __setitem__(self, param_name: str, value: typing.Any):
        self._parameters[param_name] = value

    def __len__(self):
        return len(self._parameters)

    def keys(self):
        return self._parameters.keys()

    def items(self):
        return self._parameters.items()

    def values(self):
        return self._parameters.values()

    def get_simulation_options(
        self, param_names: Optional[typing.Union[str, typing.List[str]]] = None
    ) -> typing.Any:
        """Retrieve simulation options from the parameter set

        Parameters
        ----------
        param_names : typing.Union[str, typing.List[str]], optional
            names of simulation options to retrieve, by default all

        Returns
        -------
        typing.Any, typing.Dict[str, typing.Any]
            either a single option value or all options
        """
        if param_names:
            if isinstance(param_names, list):
                return [self._simopts[i] for i in param_names]

            return self._simopts[param_names]
        return self._simopts

    def get_plasma_scenario(
        self, param_names: Optional[typing.Union[str, typing.List[str]]] = None
    ) -> typing.Any:
        """Retrieve timings from the plasma scenario set

        Parameters
        ----------
        param_names : typing.Union[str, typing.List[str]], optional
            names of plasma scenario timings to retrieve, by default all

        Returns
        -------
        typing.Any, typing.Dict[str, typing.Any]
            either a single option value or all options
        """
        if param_names:
            if isinstance(param_names, list):
                return [self._plasma_scenario[i] for i in param_names]

            return self._plasma_scenario[param_names]
        return self._plasma_scenario

    def load_plasma_scenario(self) -> typing.MutableMapping[str, typing.Any]:
        """
        Read plasma scenario from the specified file. The values
        must be in ascending order.
        """
        _plasma_scenario = self._get_input_path(
            "plasma_scenario_file",
            "Expected 'plasma_scenario_file' entry in configuration",
        )

        if not os.path.exists(_plasma_scenario):
            raise FileNotFoundError(
                f"Failed to open plasma scenario file '{_plasma_scenario}'"
            )

        _dict = toml.load(_plasma_scenario)

        try:
            pbm_mso.PlasmaScenario(**_dict)
        except pydantic.ValidationError as e:
            raise pbm_exc.ValidationError(e.json(), "plasma scenario") from e

        _is_valid = [
            self._simopts["startTime"] < _dict["plasma_ramp_up_start"],
            _dict["plasma_ramp_up_start"] < _dict["plasma_flat_top_start"],
            _dict["plasma_flat_top_start"] < _dict["plasma_flat_top_end"],
            _dict["plasma_flat_top_end"] < _dict["plasma_ramp_down_end"],
            _dict["plasma_ramp_down_end"] < self._simopts["stopTime"],
        ]

        if not all(_is_valid):
            raise ValueError(
                "Plasma scenario is not valid. "
                " Double-check that all timings are correct "
                "and within the specified simulation time."
            )

        return _dict

    def load_simulation_options(self) -> typing.MutableMapping[str, typing.Any]:
        """
        Read simulation options from the specified file. These options are
        special Modelica variables which must be of a given name so this
        method also corrects closely matching names if required
        """
        _simulation_options = self._get_input_path(
            "simulation_options_file",
            "Expected 'simulation_options_file' entry in configuration",
        )

        if not os.path.exists(_simulation_options):
            raise FileNotFoundError(
                "Failed to open simulation options file" " '{}'".format(
                    _simulation_options
                )
            )

        _dict = toml.load(_simulation_options)

        try:
            pbm_mso.SimOptsModel(**_dict)
        except pydantic.ValidationError as e:
            raise pbm_exc.ValidationError(e.json(), "simulation options") from e

        if any(isinstance(i, dict) for i in _dict):
            raise ValueError(
                "Global configuration variables should be values not "
                "nested dictionaries (do not use '.' in keys for this file)"
            )

        return _dict

    def _get_input_path(self, file_name: str, exception_msg: str) -> str:
        if not self._input_files[file_name]:
            raise pbm_exc.InvalidConfigurationError(exception_msg)

        if not self._input_files["parameters_directory"]:
            raise pbm_exc.InvalidConfigurationError(
                "Expected 'parameters_directory' entry in configuration"
            )

        return os.path.join(
            self._input_files["parameters_directory"], self._input_files[file_name]
        )

    def load_modelica_parameters(self) -> typing.Dict[str, typing.Any]:
        """Load all parameter sets from TOML files in the specified directory

        Returns
        -------
        typing.Dict[str, typing.Any]
            dictionary containing all parameters read from the input files
        """
        _toml_files = [
            toml_file
            for toml_file in glob.glob(
                os.path.join(self._input_files["parameters_directory"], "*.toml")
            )
            if os.path.basename(toml_file)
            not in [
                self._input_files["plasma_scenario_file"],
                self._input_files["simulation_options_file"],
                self._input_files["structural_params_file"],
            ]
        ]

        self._model_param_files += _toml_files

        _params: typing.Dict[str, typing.Any] = {}

        for toml_f in _toml_files:
            _toml_input = open(toml_f).read()

            _name = os.path.basename(toml_f).split(".")[0]

            # Underscore in filename is assumed to be '.' in model name
            # e.g. A_B.toml -> A.B
            _name = _name.replace("_", ".")

            # Set all keys to lower case
            _dict = toml.loads(_toml_input)

            _dict = pbm_util.flatten_dictionary(dict(_dict))

            _dict = {k.lower(): v for k, v in _dict.items()}

            _dict = {f"{_name}.{k}": v for k, v in _dict.items()}

            _params.update(_dict)

        return _params

    def load_structural_parameters(self) -> typing.MutableMapping:
        """Load the structural parameters if file given

        Returns
        -------
        MutableMapping
            typing.Dictionary containing structural parameter substitutions
        """
        if not self._input_files["structural_params_file"]:
            return {}

        if not self._input_files["parameters_directory"]:
            raise pbm_exc.InvalidConfigurationError(
                "Expected 'parameters_directory' entry in configuration"
            )

        _struct_param_addr = os.path.join(
            self._input_files["parameters_directory"],
            self._input_files["structural_params_file"],
        )

        if not os.path.exists(_struct_param_addr):
            raise FileNotFoundError(
                "Expected structural parameters file "
                f"'{_struct_param_addr}', but file does not exist."
            )

        return toml.load(_struct_param_addr)

    def append(self, parameter_name: str, value: typing.Any):
        """Add a parameter to the parameter set.

        This will occur AFTER the models have been initialised and exists
        simply to dump the value in the parameter list at the end of the run.
        i.e. this is for values that the user did not specify in their
        chosen parameter input file.

        Parameters
        ----------
        parameter_name : str
            name of parameter to add
        value : typing.Any
            value assigned to that parameter
        """
        self._parameters[parameter_name.lower()] = value

    def update_from_model(self, model_name: str, pyd_session: pydelica.Session) -> None:
        """Update the parameters using information obtained from the pydelica
        parameters.

        Parameters
        ----------
        model_name: str
            model name as string
        pyd_session: dict
            pydelica session
        """
        for name, value in pyd_session.get_parameters(model_name).items():
            if "__" not in name:
                continue

            if name.lower().replace("__", "") in self._parameters:
                continue

            if not value["value"]:
                continue

            _label = "{}.{}".format(model_name.lower(), name.lower().replace("__", ""))

            self._parameters[_label] = value["value"]

    def _retrieve_parameter(
        self, param_name: str, new_val: Optional[typing.Any] = None
    ) -> typing.Any:
        """Retrieve a parameter from the set and if a new value is specified
        set the parameter to that value.

        Parameters
        ----------
        param_name : str
            name of the parameter to retrieve/assign
        new_val : typing.Any, optional
            if specified, overwrite the value of the parameter to be this
            new value

        Returns
        -------
        typing.Any
            the value of the specified parameter

        Raises
        ------
        power_balance.exceptions.UnidentifiedParameterError
            if the requested parameter is not present in the set
        """
        # Need to allow possibility of PF magnet addition which is an exception
        # to the check that a parameter exists before returning it but also
        # ensure that it is a valid name
        _reg_pfmag = re.compile("magnetPF([0-9]+)", re.IGNORECASE)
        _is_magpf_param = _reg_pfmag.findall(param_name)

        if param_name.lower() not in self._parameters:
            _invalid_param_name = True
            # Check if valid PF parameter by substituting in an existing magnet
            # ID and confirming the name after substitution is in the
            # existing parameter list
            if _is_magpf_param:
                _expected_param = param_name.replace(f"pf{_is_magpf_param[0]}", "pf1")
                if _expected_param.lower() in self._parameters:
                    _invalid_param_name = False

            if _invalid_param_name:
                raise pbm_exc.UnidentifiedParameterError(
                    "Could not find parameter '{}' in modifiable parameters set, "
                    "available parameters are: "
                    "{}".format(
                        param_name.lower(),
                        "\n\t- " + "\n\t- ".join(self._parameters.keys()),
                    )
                )

        if new_val:
            self._parameters[param_name.lower()] = new_val

        return self._parameters[param_name.lower()]

    def search(self, search_str: str) -> typing.List[str]:
        """Search for parameters matching a given search string

        Parameters
        ----------
        search_str : str
            search term to use for finding parameters

        Returns
        -------
        typing.List[str]
            list of parameters matching search by name
        """
        return [
            p_name for p_name in self._parameters.keys() if search_str.lower() in p_name
        ]

    def get_parameter(self, param_name: str) -> typing.Any:
        """Retrieve a parameter by name from the whole parameter set.

        Parameters
        ----------
        param_name : str
            name of parameter from which to retrieve value

        Returns
        -------
        typing.Any
            current value of the specified parameter
        """
        return self._retrieve_parameter(param_name)

    def set_parameter(self, param_name: str, value: typing.Any) -> typing.Any:
        """Set a parameter by name to a given value.

        Parameters
        ----------
        param_name : str
            parameter to apply new value to
        value : typing.Any
            value to assign

        Returns
        -------
        typing.Any
            value retrieved from parameter after the assign
        """
        if param_name in self._extra_params:
            self[param_name] = value
            return value
        return self._retrieve_parameter(param_name, value)

    def save_to_directory(self, output_directory: str) -> None:
        """Save parameters to a given directory ensuring they are in a form
        in which they can later be reimported if needed to ensure consistency
        between runs and storage of conditions.

        Parameters
        ----------
        output_directory : str
            location to store the generated TOML files
        """
        _out_files: typing.Dict[str, typing.Any] = {
            os.path.basename(f): {} for f in self._model_param_files
        }

        for param, value in self._parameters.items():
            for _filename in _out_files:
                _file_in_param = os.path.splitext(_filename)[0]
                _file_in_param = _file_in_param.replace("_", ".")
                if _file_in_param in param:
                    _new_param_name = param.replace(f"{_file_in_param}.", "")
                    _out_files[_filename][_new_param_name] = pbm_util.convert_to_value(
                        value
                    )
                    break

        _out_files = {k: pbm_util.expand_dictionary(v) for k, v in _out_files.items()}

        for toml_file in _out_files:
            with open(os.path.join(output_directory, toml_file), "w") as out_f:
                toml.dump(_out_files[toml_file], out_f)

        _output = os.path.join(
            output_directory, self._input_files["simulation_options_file"]
        )

        with open(_output, "w") as out_f:
            toml.dump(self._simopts, out_f)

        _output = os.path.join(
            output_directory, self._input_files["plasma_scenario_file"]
        )

        with open(_output, "w") as out_f:
            toml.dump(self._plasma_scenario, out_f)

        if self._input_files["structural_params_file"]:
            _output = os.path.join(
                output_directory, self._input_files["structural_params_file"]
            )

            with open(_output, "w") as out_f:
                toml.dump(self._structural_parameters, out_f)

    def add_non_modelica_parameter(
        self, parameter_name: str, value: typing.Any
    ) -> None:
        """Add a parameter which is used for templating but not in Modelica sources

        Parameters
        ----------
        parameter_name : str
            name of parameter to add
        value : typing.Any
            value to assign to the parameter
        """
        self._extra_params.append(parameter_name)
        self.set_parameter(parameter_name, value)

    def is_valid_non_modelica_param(self, parameter_name: str) -> bool:
        """Returns if the specified name is a recognised non-modelica parameter

        Non-Modelica parameters are used during the templating of modelica code
        they allow the user to specify additional options relating model
        construction, for example in the case of PF magnets specification of
        what combitimetable to use. This property is used for templating,
        but not in Modelica itself.

        Parameters
        ----------
        parameter_name : str
            name of parameter to check

        Returns
        -------
        bool
            whether the parameter is a recognised non-modelica parameter
        """
        return parameter_name.lower() in self._extra_params

    def _perform_struct_subs(self, model_file: str, output_dir: str) -> str:
        self._logger.debug(
            "Checking structural parameter substitutions for input file '%s'",
            model_file,
        )

        _model_name = os.path.splitext(os.path.basename(model_file))[0]

        # If the substitutions do not include the current model return
        if _model_name not in self._structural_parameters:
            self._logger.debug("No substitutions found, copying original.")
            shutil.copy(
                model_file, os.path.join(output_dir, os.path.basename(model_file))
            )
            return ""

        struct_param_values = self._structural_parameters[_model_name]
        # Reads in a Modelica model and saves the lines into a list
        with open(model_file) as model_in:
            all_lines = model_in.readlines()

        # Saves a list of the original unedited lines
        for line_no, line in enumerate(all_lines):
            # Searches for structural parameters
            if "STRUCTURAL_PARAMETER" not in line:
                continue

            for parameter, new_param_value in struct_param_values.items():
                if parameter not in line:
                    continue
                self._logger.debug(
                    "Substituting parameter '%s' with value %s",
                    parameter,
                    new_param_value,
                )
                # Checks type of the parameter value and formats it accordingly
                if isinstance(new_param_value, str):
                    new_param_value = f'"{new_param_value}"'
                elif isinstance(new_param_value, bool):
                    new_param_value = str(new_param_value).lower()
                elif isinstance(new_param_value, (int, float)):
                    new_param_value = str(new_param_value)

                # Writes the new parameter value to the line
                if "(unit" in line:
                    temp = line.split("=", 2)
                    p_name = f"{temp[0]}{temp[1]}"
                else:
                    p_name, _ = line.split("=", 1)
                all_lines[line_no] = f"{p_name}= {new_param_value};\n"

        _out_file_name = os.path.join(output_dir, os.path.basename(model_file))

        # Write new model file
        with open(_out_file_name, "w") as out_file:
            out_file.writelines(all_lines)

        return _out_file_name

    def set_struct_parameters(
        self,
        model_file: str,
        dependency_files: typing.Optional[typing.List[str]] = None,
    ) -> str:
        """
        Set values of structural parameters in Modelica models.

        This edits the hardcoded values in a modelica model allowing
        certain hardcoded parameters to be changed.
        A dictionary containing the original Modelica models' code is returned
        at the end. This enables the Models to be restored to their
        original state after the build stage.

        Parameters
        ----------
        model_file : str
            Modelica model file
        dependency_files : typing.List[str], optional
            Additional Modelica files containing dependencies

        Returns
        -------
        str
            filepath to temporary file containing modified model
        """
        if not dependency_files:
            dependency_files = []

        # If no structural parameter substitutions exist return
        if not self._structural_parameters:
            self._logger.debug("No substitutions found, skipping.")
            return ""

        _subs_model_dir = tempfile.mkdtemp()

        _out_file = self._perform_struct_subs(model_file, _subs_model_dir)

        for dependency in dependency_files:
            self._perform_struct_subs(dependency, _subs_model_dir)

        return _out_file
