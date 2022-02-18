#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                Power Balance Models Python Structures

Python models for use when filling modelica model files containing templates.
"""

__date__ = "2021-12-02"

from collections import namedtuple

PFMagModel = namedtuple("PFMagModel", ["ID", "profile_id"])
