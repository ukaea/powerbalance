# -*- coding: utf-8 -*-
"""
                    Power Balance Models model extraction

Contains a parser for extracting model information from a set of Modelica files
which can then be used during setup of PBM.

Contents
========

Classes
-------

    ModelParser - handles the parsing of Modelica files for model listings

Functions
---------

    get_local_models - retrieve all models from a specified directory

"""

__date__ = "2021-06-10"
import glob
import os.path
import logging
import pathlib
import re
import typing

import power_balance.models as pbm_mod
import power_balance.parameters as pbm_param
import power_balance.exceptions as pbm_exc
import pydelica
import pydelica.exception


class ModelParser:
    _re_pkg_line = re.compile(
        r"\s*package\s([0-9a-z_]+)(\s\".+\")*$",
        re.IGNORECASE
    )
    _re_mod_line = re.compile(
        r"^\s*model\s([0-9a-z_]+)\s*.*$",
        re.IGNORECASE
    )
    _re_end_line = re.compile(
        r"^\s*end\s([0-9a-z_]+);",
        re.IGNORECASE
    )
    _logger = logging.getLogger("PowerBalance.ModelParser")
    def __init__(
        self,
        profile_dir: typing.Optional[str] = None,
        model_dir: typing.Optional[str] = None) -> None:
        self._models: typing.Dict[str, pbm_mod.Model] = {}
        self._model_files: typing.List[str] = []
        self._model_names: typing.Optional[typing.List[str]] = None
        self._names_only = not model_dir
        self._current_model_cache: typing.Dict[str, typing.Any] = {
            "package_name_addr": [],
            "package_name": "",
            "location": "",
            "model_name": None,
            "submodels": {},
            "compiled": False,
            "binary_folder": "",
            "dependent_models": [],
            "dependent_files": []
        }

        self._model_src_dir = model_dir
        self._profile_src_dir = profile_dir

        if model_dir:
            self._model_files = glob.glob(os.path.join(model_dir, "*.mo"))

    def _save_model(self) -> None:
        if not self._current_model_cache["model_name"]:
            return
        self._models[self._current_model_cache["model_name"]] = pbm_mod.Model(
            self._current_model_cache["model_name"],
            self._current_model_cache["location"] or None,
            self._current_model_cache["package_name"] or None,
            self._current_model_cache["submodels"] or None,
            self._current_model_cache["binary_folder"] or None,
            self._current_model_cache["compiled"]
        )

    def _get_submodel(self, line: str, submodel_search: typing.List[str]) -> None:
        _result = submodel_search[0].strip()
        _submodel_name = re.findall(
            f'^\\s*{_result}\\s([a-z0-9]+)\\s*', line, re.IGNORECASE
        )
        if not _submodel_name:
            return
        self._current_model_cache["submodels"][_submodel_name[0]] = _result

    def _get_model(self, model_search: typing.List[str], label: str) -> None:
        _current_model = model_search[0].strip()
        if not self._current_model_cache["package_name_addr"]:
            self._current_model_cache["package_name"] = label
        else:
            self._current_model_cache["package_name"] = ".".join(
                self._current_model_cache["package_name_addr"]
            ).strip()
        self._current_model_cache["model_name"] = _current_model.strip()

    def _assemble(self, input_file: str, end_search: typing.List[str]) -> None:
        # If the term 'end <package-name>;' is present this means the scope
        # for that package has ended so remove the last term in the
        # package address
        if end_search[0] in self._current_model_cache["package_name_addr"]:
            self._current_model_cache["package_name_addr"].remove(end_search[0])
            return

        if end_search[0] not in self._current_model_cache["model_name"]:
            return

        if self._names_only or not self._session:
            self._save_model()
            return
        
        _name = self._current_model_cache["model_name"]

        # Only compile the model if either no model list is given
        # or the model name is present within the given list
        if self._model_names and _name not in self._model_names:
            return

        # Only attempt a structural parameter substitution
        # if there is a valid file given and if there is
        # an entry for the model in that file
        _modelica_src_file = input_file

        if self._parameter_set and self._parameter_set.get_file_location(
            "structural_params_file"
        ):
            _modelica_src_file = self._parameter_set.set_struct_parameters(
                input_file, self._current_model_cache["dependent_files"]
            ) or input_file

        if not self._model_src_dir:
            self._model_src_dir = os.path.dirname(_modelica_src_file)

        self._current_model_cache["package_name"] = ".".join(self._current_model_cache["package_name_addr"])
        _name = f"{self._current_model_cache['package_name']}.{self._current_model_cache['model_name']}"

        self._session.build_model(
            modelica_source_file=_modelica_src_file,
            model_addr=_name,
            extra_models=self._current_model_cache["dependent_models"],
            c_source_dir=os.path.join(
                self._model_src_dir, "Resources", "Include"
            ),
            update_input_paths_to=self._profile_src_dir,
        )

        try:
            _bin_loc = self._session.get_binary_location(_name)
            self._current_model_cache["binary_folder"] = os.path.dirname(_bin_loc)
            self._current_model_cache["compiled"] = True
            self._logger.info("Retrieved binary at '%s'", _bin_loc)

        except pydelica.exception.BinaryNotFoundError:
            self._logger.warning(f"No binary found for model {_name}")
        
        self._save_model()
                 

    def _get_dependencies(self, input_file: str) -> typing.Tuple[typing.List[str], typing.List[str]]:
        # Creating a list of dependent models that exist
        # in '/models' directory (excluding the specified core model)
        _dependent_models = [
            file_name
            for file_name in os.listdir(os.path.dirname(input_file))
            if ".mo" in file_name
            and file_name != os.path.basename(input_file)
        ]

        _dependency_files = [
            os.path.join(os.path.dirname(input_file), dependency)
            for dependency in _dependent_models
        ]

        return _dependent_models, _dependency_files

    def parse(self,
        model_names: typing.Optional[typing.List[str]] = None,
        parameter_set: pbm_param.PBMParameterSet = None,
        session: typing.Optional[pydelica.Session] = None) -> None:
        if not self._model_files:
            raise AssertionError(
                "Expected list of model files to be initialised"
            )
        for file in self._model_files:
            self.parse_file(file, model_names, parameter_set, session)

    @property
    def models(self) -> typing.Dict[str, pbm_mod.Model]:
        return self._models

    def parse_file(
        self,
        file_name: str,
        model_names: typing.Optional[typing.List[str]] = None,
        parameter_set: pbm_param.PBMParameterSet = None,
        session: typing.Optional[pydelica.Session] = None) -> None:
        """Parse a single Modelica model file for valid models

        Parameters
        ----------
        file_name : str
            Modelica file containing model definitions
        model_names : typing.List[str], optional
            Specify models to build
        parameter_set : power_balance.parameters.PBMParameterSet, optional
            Parameter set object to append to
        session : pydelica.Session, optional
            session to use for compilation
        """
        if not os.path.exists(file_name):
            raise FileNotFoundError(f"Failed to retrieve file: '{file_name}'")
    
        if pathlib.Path(file_name).suffix != ".mo":
            raise ValueError(
                "Input file must be of type OpenModelica "
                f"('.mo') file, file='{file_name}'"
            )

        self._names_only = not session or not model_names or not parameter_set
        
        if not self._model_src_dir:
            self._model_src_dir = os.path.dirname(file_name)
        
        self._current_model_cache["location"] = file_name
        self._session = session
        self._model_names = model_names
        self._parameter_set = parameter_set

        _file_name_no_suffix = pathlib.Path(file_name).stem

        _file_lines = [i.strip() for i in open(file_name).readlines() if i.strip()]
        
        (self._current_model_cache["dependent_models"],
        self._current_model_cache["dependent_files"]) = self._get_dependencies(file_name)

        for line in _file_lines:
            _find_package = self._re_pkg_line.findall(line)
            _find_model = self._re_mod_line.findall(line)
            _find_end = self._re_end_line.findall(line)
            _find_submodel = [i.name for i in self._models.values() if i.name in line]

            if _find_package:
                self._current_model_cache["package_name_addr"] += [_find_package[0][0]]
            elif _find_submodel:
                self._get_submodel(line, _find_submodel)
            elif _find_model:
                self._get_model(_find_model, _file_name_no_suffix)
            elif _find_end:
                self._assemble(file_name, _find_end)
            self._save_model()

def get_local_models(
    model_file_dir: typing.Optional[str] = None,
    model_name_list: typing.Optional[typing.List[str]] = None,
    parameter_set: typing.Optional[pbm_param.PBMParameterSet] = None,
    session: typing.Optional[pydelica.Session] = None,
    profile_dir: typing.Optional[str] = None) -> typing.Dict[str, pbm_mod.Model]:
    """Get available models within a specified model directory

    If optional arguments are not specified then it is assumed the user only
    wants a list of model names and not any metadata. Else models are also
    compiled and the binary locations set.

    Parameters
    ----------
    model_file_dir : str, optional
        directory to search for model files
    model_name_list : typing.Optional[typing.List[str]], optional
        only include specific models, by default None
    parameter_set : typing.Optional[pbm_param.PBMParameterSet], optional
        parameter set to append parameters to, by default None
    session : typing.Optional[pydelica.Session], optional
        pydelica session to use for compiling, by default None
    profile_dir : typing.Optional[str], optional
        directory containing profile inputs, by default None

    Returns
    -------
    typing.Dict[str, pbm_mod.Model]
        dictionary containing model metadata on local system

    Raises
    ------
    pbm_exc.InternalError
        if no models were extracted
    """
    if not model_file_dir:
        model_file_dir = pbm_mod.MODEL_DIR
    _mod_parser = ModelParser(profile_dir, model_file_dir)
    _mod_parser.parse(model_name_list, parameter_set, session)
    _out_dict = _mod_parser.models
    if not _out_dict:
        raise pbm_exc.InternalError(
            "Failed to identify internal module Modelica models"
        )

    return _out_dict
