#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Input profile plotting
======================

Plotting of model input profiles read as MATLAB files.

Contents
========

Classes
-------

    ProfilePlotBuilder - constructs and assembles plots of input profiles

"""

__date__ = "2021-06-10"

import glob
import os
from typing import Any, Dict, Tuple

import numpy as np
import scipy.io as sio
from bokeh.embed import components
from bokeh.layouts import gridplot
from bokeh.plotting import figure

from power_balance.plotting.common import add_plot_objects


def get_profiles_data(profile_dir: str) -> Dict[str, np.ndarray]:
    """Retrieve profiles for plotting

    Returns
    -------
    Dict[str, Any]
        dictionary of profile data
    """
    _profiles = glob.glob(os.path.join(profile_dir, "*.mat"))

    return {os.path.splitext(prof)[0]: sio.loadmat(prof)["data"] for prof in _profiles}


class ProfilePlotBuilder:
    """Builds page content for displaying the plots of input profiles"""

    def __init__(self, profiles_dir: str):
        """Initialise the profile plot builder

        Parameters
        ----------
        profiles_dir : str
            directory location of profiles
        """
        self._data = get_profiles_data(profiles_dir)
        self._plots, self._scripts = self._arrange_plots()

    def get_scripts(self) -> Any:
        """Retrieve plot script objects

        Returns
        -------
        Any
            plot script objects
        """
        return self._scripts

    def get_plots(self) -> str:
        """Retrieve plot string objects

        Returns
        -------
        str
            plot object strings
        """
        return self._plots

    def _create_plots(self) -> Dict[str, figure]:
        """Generate plots for non-sweep case.

        Returns
        -------
        Dict[str, Dict[str, bokeh.plotting.figure]]
            dictionary of plots for every power variable from every model
        """
        _x_label = "Time/s"

        _plot_dict: Dict[str, figure] = {}

        for profile in self._data:
            _title = os.path.basename(profile).replace("_", " ")
            _title = _title[0].upper() + _title[1:]

            if "current" in _title.lower():
                _y_label = "current"
            elif "heat" in _title.lower():
                _y_label = "heat"
            else:
                _y_label = "power"
            _units = "A" if _y_label == "current" else "W"

            _plot = figure(
                title=_title,
                x_axis_type="linear",
                x_axis_label=_x_label,
                y_axis_label=f"{_y_label}/{_units}",
            )

            add_plot_objects(
                _plot,
                self._data[profile][:, 0],
                self._data[profile][:, 1],
                "time",
                _title,
            )

            _plot_dict[profile] = _plot

        return _plot_dict

    def _arrange_plots(self) -> Tuple[str, Any]:
        # skip this refactoring as it conflicts with mypy
        # sourcery skip: inline-immediately-returned-variable
        _plots = self._create_plots()
        _components: Tuple[str, Any] = components(
            gridplot(
                list(_plots.values()),  # type: ignore
                ncols=2,
                width=666,
                height=400,
                merge_tools=True,
            )
        )
        return _components
