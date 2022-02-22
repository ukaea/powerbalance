#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                Power Balance Models model objects

Creates an importable Python dictionary giving the addresses of the
models contained within the power_balance/models directory.
"""

__date__ = "2021-06-08"

import collections
import glob
import logging
import os
import pathlib
import re
from typing import Dict, List

import pydelica

import power_balance.exceptions
import power_balance.parameters

_model_logger = logging.getLogger("PowerBalance.Models")

Model = collections.namedtuple(
    "Model",
    [
        "name",
        "location",
        "package",
        "submodels",
        "binary_folder",
        "compiled",
    ],
)
Model.__doc__ = """\
named tuple object containing properties for a given model

Attributes
----------
name: str
    model name
location: str
    file address of model source
package: str
    package in source containing model
submodels: Dict[str, List[str]]
    dictionary of submodel type instances (if any) which form part of this
    model sorted by submodel type name
binary_folder:  str
    location of compiled binary (may be temporary)
"""

MODEL_DIR = os.path.dirname(__file__)
MODEL_FILES = glob.glob(os.path.join(MODEL_DIR, "*.mo"))


def extract_models_from_file(
    input_file: str,
    profile_dir: str,
    original_model_dir: str,
    parameter_set: power_balance.parameters.PBMParameterSet = None,
    session: pydelica.Session = None,
    model_name_list: List[str] = None,
    names_only: bool = False,
    quiet: bool = False,
) -> Dict[str, Model]:
    """Extracts all models from a Modelica '.mo' file

    Parameters
    ----------
    input_file : str
        name of OpenModelica input file with suffix '.mo'
    profile_dir: str
        location of input files
    original_model_dir: str
        directory containing models to parse
    parameter_set: power_balance.parameters.PBMParameterSet
        PowerBalance Models session parameter set
    session : pydelica.Session, optional
        PyDelica session instance
    model_name_list : List[str], optional
        specify which models of all of those within the file
        should be compiled and imported, by default all
    names_only : bool, optional
        do not compile the models just return a list of names, by default False
    quiet : bool, optional
        suppress printouts, by default False

    Returns
    -------
    Dict[str, Model]
        a dictionary of tuples each containing:
        -   name
        -   package name
        -   submodels        submodels for this model
        -   compiled        (for later storage of compiled object)

    Raises
    ------
    FileNotFoundError
        if the given input file does not exist
    ValueError
        if the input file is not a Modelica file
    """
    if not os.path.exists(input_file):
        raise FileNotFoundError(f"Failed to retrieve file: '{input_file}'")

    if pathlib.Path(input_file).suffix != ".mo":
        raise ValueError(
            "Input file must be of type OpenModelica "
            f"('.mo') file, file='{input_file}'"
        )

    _file_name_no_suffix = os.path.basename(input_file).split(".mo")[0]
    _file_lines = open(input_file).readlines()

    # For validation only the names of the models are required, they should not
    # be compiled else this will result in errors
    _models: Dict[str, Model] = {}

    _package_line = re.compile(r"^\s*package\s([0-9a-z_]+)", re.IGNORECASE)
    _model_line = re.compile(r"^\s*model\s([0-9a-z_]+)", re.IGNORECASE)
    _end_line = re.compile(r"^\s*end\s([0-9a-z_]+);", re.IGNORECASE)

    _current_package: List[str] = []
    _current_submodels: Dict[str, List[str]] = {}
    _current_model: str = ""
    _name: str = ""
    _package_name: str = ""

    if not quiet:
        _model_logger.info(
            "%s: Extracting Models from input Modelica file.", _file_name_no_suffix
        )

    for line in _file_lines:
        if not line.strip():
            continue
        _find_package = _package_line.findall(line)
        _find_model = _model_line.findall(line)
        _find_end = _end_line.findall(line)
        _existing_models = []
        for model in _models.values():
            if model.package:
                _existing_models.append(f"{model.package}.{model.name}")
            else:
                _existing_models.append(model.name)
        _find_submodel = [
            i.strip() for i in _existing_models
            if re.findall(f"^\\s*{i}", line, re.IGNORECASE)
        ]
        if _find_package:
            _current_package += [_find_package[0]]
        elif _find_submodel:
            _var_name = re.findall(
                f"^\\s*{_find_submodel[0]}\\s([a-z0-9]+)\\s*",
                line,
                re.IGNORECASE
            )
            _current_submodels[_find_submodel[0].strip()] = _var_name[0].strip()
        elif _find_model:
            _current_model = _find_model[0].strip()
            if _current_package:
                _package_name = ".".join(_current_package).strip()
                _name = "{}.{}".format(_package_name, _current_model.strip())
            else:
                _name = _current_model.strip()
        elif _find_end:
            # If the term 'end <package-name>;' is present this means the scope
            # for that package has ended so remove the last term in the
            # package address
            if _find_end[0] in _current_model:
                if names_only:
                    _models[_name] = Model(
                        name=_name,
                        package=_package_name,
                        location=input_file,
                        submodels=_current_submodels,
                        binary_folder=None,
                        compiled=None,
                    )
                else:
                    if not session:
                        raise AssertionError(
                            "No PyDelica Session instance provided for model"
                            " compilation and initialisation"
                        )

                    compiled = False

                    # Creating a list of dependent models that exist
                    # in '/models' directory (excluding the specified core model)
                    dependent_models = [
                        file_name
                        for file_name in os.listdir(os.path.dirname(input_file))
                        if ".mo" in file_name
                        and file_name != os.path.basename(input_file)
                    ]

                    # Only compile the model if either no model list is given
                    # or the model name is present within the given list
                    if not model_name_list or _name in model_name_list:

                        _dependency_files = [
                            os.path.join(os.path.dirname(input_file), dependency)
                            for dependency in dependent_models
                        ]

                        _modelica_source_file = input_file
                        # Only attempt a structural parameter substitution
                        # if there is a valid file given and if there is
                        # an entry for the model in that file
                        if parameter_set and parameter_set.get_file_location(
                            "structural_params_file"
                        ):
                            if _new_file := parameter_set.set_struct_parameters(
                                _modelica_source_file, _dependency_files
                            ):
                                _modelica_source_file = _new_file

                        session.build_model(
                            modelica_source_file=_modelica_source_file,
                            model_addr=_name,
                            extra_models=dependent_models,
                            c_source_dir=os.path.join(
                                original_model_dir, "Resources", "Include"
                            ),
                            update_input_paths_to=profile_dir,
                        )

                    try:
                        _bin_loc = session.get_binary_location(_name)
                        _bin_loc = os.path.dirname(_bin_loc)
                        _model_logger.debug(
                            "%s: Binary created at: %s", _name, _bin_loc
                        )
                        compiled = True

                    except pydelica.exception.BinaryNotFoundError:
                        _bin_loc = None

                    _models[_name] = Model(
                        name=_name,
                        package=_package_name,
                        location=input_file,
                        submodels=_current_submodels,
                        binary_folder=_bin_loc,
                        compiled=compiled,
                    )

                _current_submodels = {}

    return _models


def get_local_models(
    model_file_dir: str,
    parameter_set: power_balance.parameters.PBMParameterSet = None,
    session: pydelica.Session = None,
    profile_dir: str = "",
    model_name_list: List[str] = None,
    names_only: bool = False,
    quiet: bool = False,
) -> Dict[str, Model]:
    """Retrieve list of models from this directory to create an importable
    Python dictionary object. Models are stored as namedtuples

    Parameters
    ----------
    model_file_dir : str
        directory containing Modelica model files
    parameter_set: power_balance.parameters.PBMParameterSet, optional
        PowerBalance Models session parameter set
    session : pydelica.Session, optional
        PyDelica Modelica session
    profile_dir: str, optional
        profile inputs directory
    model_name_list : List[str], optional
        specify which models of all of those within the file
        should be compiled and imported, by default all
    names_only : bool, optional
        do not compile the models just return a list of names, by default False
    quiet : bool, optional
        suppress printouts, by default False

    Returns
    -------
    Dict[str, Model]
        a dictionary of tuples each containing:
        -   name
        -   package name
        -   submodels        submodels for this model
        -   compiled        (for later storage of compiled object)
    """
    _models = glob.glob(os.path.join(model_file_dir, "*.mo"))
    _models = ["{0}".format(item.replace("\\", "\\\\")) for item in _models]
    _out_dict: Dict[str, Model] = {}

    if not quiet:
        _model_logger.info("Retrieving internal module Modelica models,")

    for model_file in _models:
        _out_dict.update(
            extract_models_from_file(
                parameter_set=parameter_set,
                session=session,
                profile_dir=profile_dir,
                input_file=model_file,
                model_name_list=model_name_list,
                names_only=names_only,
                quiet=quiet,
                original_model_dir=model_file_dir,
            )
        )

    if not _out_dict:
        raise power_balance.exceptions.InternalError(
            "Failed to identify internal module Modelica models"
        )

    return _out_dict
