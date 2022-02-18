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


class ModelConfig:
    title = "PowerBalanceModelInputs"
    extra = "forbid"
    validate_all = True
    use_enum_values = True
    anystr_strip_whitespace = True
