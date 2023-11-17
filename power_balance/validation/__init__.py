#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Validation
==========

Validation of PBM inputs

Contents
========

Submodules
----------
    
    config - validation of API configuration files
    modelica_simulation_options - validation of modelica simulation option files

"""
import pydantic

MODEL_CONFIG = pydantic.ConfigDict(
    title="PowerBalanceModelInputs",
    extra="forbid",
    validate_default=True,
    use_enum_values=True,
    str_strip_whitespace=True,
)
