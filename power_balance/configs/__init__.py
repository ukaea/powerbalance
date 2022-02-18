#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Read Configuration Files
========================

Reading and handling of configuration options from specified TOML inputs.

Contents
========

Functions
---------

Reading configurations

    read_options_from_config - read configuration file and validate

"""

__date__ = "2021-06-08"

import os
import typing

import power_balance.utilities as pbm_utils
import toml

config_default = os.path.join(os.path.dirname(__file__), "default_config.toml")


def read_options_from_config(config_file: str) -> typing.MutableMapping[str, typing.Any]:
    """Read in options for this PBM instance from config file

    Parameters
    ----------
    config_file : str
        address of input configuration file

    Returns
    -------
    typing.MutableMapping[str, typing.Any]
        validated dictionary containing the configurations

    Raises
    ------
    FileNotFoundError
        If the configuration file provided does not exist
    """
    if not os.path.exists(config_file):
        raise FileNotFoundError("Configuration file '{}' not found".format(config_file))

    _configuration = toml.load(open(config_file))

    # Default sweep mode is set
    if "sweep_mode" not in _configuration:
        _configuration["sweep_mode"] = "set"

    # Read in the sweep dictionary, flattening it into a single level dict
    if "sweep" in _configuration:
        _configuration["sweep"] = pbm_utils.flatten_dictionary(_configuration["sweep"])

    # Check for presence of a structural parameters file in configuration
    if "structural_params_file" not in _configuration:
        _configuration["structural_params_file"] = None

    return _configuration
