#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                    Utilities for PowerBalance API

Contains assorted utility functions used within the Power Balance API
"""

__date__ = "2021-06-08"

from typing import Any, Dict, Optional


def convert_to_value(value_str: Any) -> Any:
    _value_types = [int, float, complex, bool]

    if type(value_str) in _value_types:
        return value_str

    if not isinstance(value_str, str):
        try:
            value_str.keys()
            return {k: convert_to_value(v) for k, v in value_str.items()}
        except AttributeError:
            pass
        try:
            iter(value_str)
            return type(value_str)([convert_to_value(i) for i in value_str])
        except TypeError:
            pass

    if isinstance(value_str, str) and "." in value_str:
        try:
            return float(value_str)
        except ValueError:
            pass

    try:
        return int(value_str)
    except ValueError:
        pass

    if isinstance(value_str, str) and value_str.lower() in ["true", "false"]:
        return bool(value_str)

    return value_str


def flatten_dictionary(
    input_dict: Dict[str, Any],
    output_dict: Optional[Dict[str, Any]] = None,
    parent_key: Optional[str] = None,
    separator: str = ".",
) -> Dict[str, Any]:
    """Convert a dictionary of dictionaries into a single level dictionary
    with keys in the form `A{separator}B`.

    Parameters
    ----------
    input_dict : MutableMapping[str, Any]
        input dictionary object to flatten
    separator : str, optional
        character to use for key address, by default "."

    Other arguments are for internal use.

    Returns
    -------
    Dict[str, Any]
        flattened single level dictionary representation of input dictionary
        with levels represented by the given separator
    """
    if output_dict is None:
        output_dict = {}

    for label, value in input_dict.items():
        new_label = f"{parent_key}{separator}{label}" if parent_key else label
        if isinstance(value, dict):
            flatten_dictionary(
                input_dict=value, output_dict=output_dict, parent_key=new_label
            )
            continue

        output_dict[new_label] = value

    return output_dict


def expand_dictionary(
    input_dict: Dict[str, Any],
    output_dict: Optional[Dict[str, Any]] = None,
    separator: str = ".",
) -> Dict[str, Any]:
    """Convert a single level dictionary with keys containing a separator into
    a nested dictionary.

    Parameters
    ----------
    input_dict: dict
        dictionary to expand

    separator: str
        character which defines dictionary levels in key

    Other arguments are for internal use.

    Returns
    -------
    Dict[str, Any]
        expanded dictionary with nested levels

    """
    if output_dict is None:
        output_dict = {}

    for label, value in input_dict.items():
        if separator not in label:
            output_dict[label] = value
            continue
        key, _components = label.split(separator, 1)
        if key not in output_dict:
            output_dict[key] = {}
        expand_dictionary({_components: value}, output_dict[key])

    return output_dict
