#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Power Balance Models
====================

A framework developed for assessment of net power production by
different Tokamak fusion reactor designs. Simulations are created via models
constructed using Modelica for power generation and consumption systems.
"""

import os.path
import pathlib

import pkg_resources
import toml

__author__ = "UKAEA"
__copyright__ = "UKAEA 2022, Power Balance Models"
__credits__ = [
    "Alexander Petrov",
    "Samuel Stewart",
    "Kristian Zarebski",
    "Nicholas Brewer",
    "Marius Cannon",
    "Christie Finlay",
    "Sophie Gribben",
    "Katherine Rochford",
]
__maintainer__ = "Alexander Petrov"
__contact__ = "alexander.petrov@ukaea.uk"
__status__ = "Release"

try:
    __version__ = pkg_resources.get_distribution("power_balance").version
except pkg_resources.DistributionNotFound:
    _metadata = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parents[1], "pyproject.toml"
    )
    if os.path.exists(_metadata):
        __version__ = toml.load(_metadata)["tool"]["poetry"]["version"]
    else:
        __version__ = "Undefined"
