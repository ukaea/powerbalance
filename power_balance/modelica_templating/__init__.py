#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                Power Balance Models Model Modification

Modifies the modelica sources for more easy API based object creation
"""

__date__ = "2021-12-01"

import typing

import jinja2

import power_balance.exceptions as pbm_exc
from power_balance.models import MODEL_FILES


def load_model_as_template(model_file: str) -> jinja2.Template:
    """Loads the specified model into a Jinja template

    Modelica models containing Jinja statements are loaded into a Jinja template
    which can then be filled.

    Parameters
    ----------
    model_file : str
        name of the model file to load (not path) without suffix, e.g. Magnets

    Returns
    -------
    jinja2.Template
        a Jinja template which can be rendered with values
    """
    _model_contents: typing.Optional[str] = None

    for file_name in MODEL_FILES:
        if model_file in file_name:
            _model_contents = open(file_name).read()

    if not _model_contents:
        raise pbm_exc.InvalidInputError(
            f"Failed to find match for model file '{model_file}'"
        )

    # Remove special Jinja comments in model code
    _model_contents = _model_contents.replace("//<jinja>", "")
    _model_contents = _model_contents.replace("//</jinja>", "")
    _model_contents = _model_contents.replace("/*<jinja>", "")
    _model_contents = _model_contents.replace("</jinja>*/", "")

    return jinja2.Template(_model_contents)
