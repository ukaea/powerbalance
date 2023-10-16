#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Common plotting methods
=======================

Collection of methods used during the creation of Bokeh plots

Contents
========

Functions
---------

    make_hover_tool - creates bokeh.HoverTool instance
    add_plot_objects - create bokeh data sources and hover tool for given figure
    plot_to_image - plot data to image file via MatplotLib

"""

__date__ = "2021-06-10"

from typing import Iterable

import bokeh.models
import bokeh.plotting
import matplotlib.pyplot as plt
import numpy as np


def make_hover_tool(
    x_label: str, y_label: str, dec_places: int = 4
) -> bokeh.models.HoverTool:
    """Create a HoverTool instance for a variable plot.

    This allows the interface user to hover over data points and see info.

    Parameters
    ----------
    x_label : str
        name of independent variable
    y_label : str
        name of dependent variable
    dec_places : int, optional
        number of decimal places before the exponent, default is 4

    Returns
    -------
    HoverTool
        instance of hover tool to be added to Bokeh plot
    """
    _format_str = "{%." + str(dec_places) + "e}"
    return bokeh.models.HoverTool(
        tooltips=[("Value", f"(@{x_label}{_format_str}, @{y_label}{_format_str})")],
        formatters={f"@{y_label}": "printf", f"@{x_label}": "printf"},
    )


def add_plot_objects(
    figure: bokeh.plotting.figure,
    x_array: np.ndarray,
    y_array: np.ndarray,
    x_label: str,
    y_label: str,
    point_threshold: int = 100,
) -> None:
    """Create a Bokeh plot source

    Parameters
    ----------
    x_array: numpy.ndarray
        independent variable array
    y_array: numpy.ndarray
        dependent variable array
    x_label: str
        label for independent data array
    y_label: str
        label for dependent data array
    point_threshold : int, optional
        threshold on number of data points to display, default is 100
    """
    x_data = x_array
    y_data = y_array

    if len(x_data) > point_threshold:
        _frequency = int(np.ceil(len(x_array) / point_threshold))
        x_data = x_data[1::_frequency]
        y_data = y_data[1::_frequency]

    _source = bokeh.plotting.ColumnDataSource({x_label: x_data, y_label: y_data})

    figure.scatter(x=x_label, y=y_label, source=_source)

    figure.line(x=x_label, y=y_label, source=_source, line_width=2)

    _hover_tool = make_hover_tool(x_label, y_label)
    figure.add_tools(_hover_tool)


def plot_to_image(
    x_array: Iterable,
    y_array: Iterable,
    x_label: str,
    y_label: str,
    file_name: str,
    dpi: int = 900,
    filetype: str = "jpeg",
) -> None:
    """Plots graph of power against time and saves to the given
    file address.

    Parameters
    ----------
    x_array : np.array
        x axis array
    y_array : np.array
        y array
    x_label : str
        independent variable label
    y_label : str
        dependent variable label
    file_name : str
        output file name (should match `filetype`)
    dpi : int, optional
        image resolution, by default 900
    filetype : str, optional
        file format, by default "jpeg"
    """
    plt.figure()
    plt.plot(x_array, y_array) # type: ignore
    plt.grid()
    plt.xlabel(x_label)
    plt.ylabel(y_label)

    plt.savefig(file_name, format=filetype, dpi=dpi)
    plt.close()
