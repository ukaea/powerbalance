#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Power Balance Models Exceptions
===============================

Exceptions covering various cases during a PBM run such as failure
to read parameters or validation errors.

Exceptions
----------

    UnidentifiedParameterError - a given parameter does not exist or is not recognised
    ModelicaParameterError - parameter is not recognised by OpenModelica session
    TranslationError - cases where exchange of information between PBM and Modelica failed
    InvalidInputError - the given argument is not a valid input
    ValidationError - given options/parameters do not pass validation
    InternalError - issues arising during internal setup
    PluginError - errors relating to the handling of plugins

"""

__date__ = "2021-06-08"

import json
import typing


class UnidentifiedParameterError(Exception):
    """
    Exception for cases where parameter is not recognised
    """

    def __init__(self, msg: str) -> None:
        """
        Parameters
        ----------
        msg : str
            message describing case of parameter recognition failure
        """
        Exception.__init__(self, msg)


class ModelicaParameterError(Exception):
    """
    Exception for cases where parameter is not found within the
    OpenModelica server session itself
    """

    def __init__(self, parameter_name: str) -> None:
        """
        Parameters
        ----------
        parameter_name : str
            name of parameter which failed to be identified
        """
        self.param_name = parameter_name
        _msg = f"Could not find Modelica parameter matching '{parameter_name}'"
        Exception.__init__(self, _msg)


class TranslationError(Exception):
    """
    Exception for cases where parameter exchange between API and Modelica
    server session failed
    """

    def __init__(self, msg: str) -> None:
        """
        Parameters
        ----------
        msg : str
            message describing case of parameter handling failure
        """
        Exception.__init__(self, msg)


class InvalidInputError(Exception):
    """
    Exception for cases where specified argument is not valid
    """

    def __init__(self, msg: str) -> None:
        """
        Parameters
        ----------
        msg : str
            message describing case of invalid argument
        """
        Exception.__init__(self, msg)


class ValidationError(Exception):
    """Exception for cases where validation via a Pydantic validator fails"""

    def __init__(self, info: str, label: str) -> None:
        _invalid_entries: typing.List[str] = []

        for data in json.loads(info):
            _err_loc = map(str, data["loc"])
            _err_loc_str = ":".join(_err_loc)
            _type = str(data["type"])
            _msg = str(data["msg"])
            _invalid_entries.append(f"{_err_loc_str:<50}  {_type:<20}  {_msg:<20}")

        _msg = f"User '{label}' file validation failed with:\n"
        _msg += "\n" + f'{"Location":<50}  {"Type":<20}  {"Message":<20}\n'
        _msg += "=" * 94 + "\n"
        _msg += "\n".join(_invalid_entries)
        super().__init__(_msg)


class InvalidConfigurationError(Exception):
    """Exception for invalid PowerBalance configuration"""

    def __init__(self, msg) -> None:
        Exception.__init__(self, msg)


class InternalError(Exception):
    """Exception for errors relating to internal setup, processes etc"""

    def __init__(self, msg: str) -> None:
        """
        Parameters
        ----------
        msg : str
            message describing case of internal error
        """
        Exception.__init__(self, msg)


class PluginError(Exception):
    """Exception for errors relating to plugin setup/modification"""

    def __init__(self, msg: str) -> None:
        """
        Parameters
        ----------
        msg : str
            message describing case of plugin error
        """
        Exception.__init__(self, msg)
