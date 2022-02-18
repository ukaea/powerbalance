#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Model output plotting
=====================

Plotting of model output variables.

Contents
========

Classes
-------

    OutputPlotBuilder - constructs and assembles plots of model output variables

"""

__date__ = "2021-06-10"

import itertools
from typing import List, Dict, Any, MutableMapping, Tuple

import numpy as np
from bokeh.embed import components
from bokeh.layouts import gridplot
from bokeh.models.ranges import DataRange1d
from bokeh.plotting import figure

import power_balance.plotting.common as pbm_pc


def _output_plot_title(model_name: str, var_name: str) -> str:
    """Create title string from model name and variable name.

    Parameters
    ----------
    model_name : str
        name of parent model
    var_name : str
        name of variable

    Returns
    -------
    str
        title for subsequent plot
    """
    _title = var_name

    if _title.lower() == "netpowergeneration":
        _title = "Net Power Balance"
    elif _title.lower() == "netpowerconsumption":
        _title = "Total Parasitic Load"
    elif _title.lower() == "powergenerated":
        _title = "Generated Power"

    _title = _title.replace("_", " ")
    _title = _title.replace("power", " power")
    _title = _title.title()

    _title = "{}: {} {}".format(
        model_name.replace("_", " "),
        _title,
        ""
        if "Net Power Balance" in _title
        or "Generated Power" in _title
        or "Total Parasitic Load" in _title
        else "Consumption",
    ).title()

    return _title


class OutputPlotBuilder:
    """Constructs plots from a set of model run outputs"""

    def __init__(
        self,
        configuration: MutableMapping[str, Any],
        output_data: Dict,
        npoint_threshold: int = 100,
    ) -> None:
        """Create plots of PBM output data

        Parameters
        ----------
        output_data : Dict
            dictionary containing output results
        configuration: Dict
            configuration settings dictionary
        npoint_threshold : int, optional
            maximum number of datapoints to be displayed, by default 100
        """
        self._data = output_data
        self._threshold = npoint_threshold
        self._configuration = configuration
        self._cuts: Dict[str, List[Dict]] = {}
        self._has_sweep = False
        self._plots, self._scripts = self._make_plots()

    def get_scripts(self) -> List[str]:
        """Retrieve Bokeh plot scripts"""
        return self._scripts

    def get_plots(self) -> Dict[str, Any]:
        """Retrieve plot dictionary"""
        return self._plots

    def get_cuts(self) -> Dict[str, Any]:
        """Retrieve dictionary of sweep cuts"""
        return self._cuts

    def has_sweep(self) -> bool:
        """Output has parameter sweep"""
        return self._has_sweep

    def _make_plots(self) -> Tuple[Dict[str, Any], List[str]]:
        _scripts: List[str] = []
        _plot_out: Dict[str, Any] = {}

        if "sweep" in self._configuration:
            self._has_sweep = True
            _sweep_plots = self._sweep_mode_plots()
            for model in _sweep_plots:
                _plot_out[model] = {}
                for c_id in _sweep_plots[model]:
                    _components = components(
                        gridplot(
                            list(_sweep_plots[model][c_id].values()),
                            ncols=2,
                            width=666,
                            height=400,
                            merge_tools=False,
                        )
                    )
                    _plot_out[model][c_id] = _components[1]
                    _scripts.append(_components[0])
        else:
            self._has_sweep = False
            _plots = self._no_sweep_plots()
            for model in self._data:
                _components = components(
                    gridplot(
                        list(_plots[model].values()),
                        ncols=2,
                        width=666,
                        height=400,
                        merge_tools=False,
                    )
                )
                _plot_out[model] = _components[1]
                _scripts.append(_components[0])

        return _plot_out, _scripts

    def _no_sweep_plots(self) -> Dict[str, Dict[str, figure]]:
        """Generate plots for non-sweep case.

        Returns
        -------
        Dict[str, Dict[str, bokeh.plotting.figure]]
            dictionary of plots for every power variable from every model
        """
        _x_label = "Time/s"
        _y_label = "Power/W"

        _plot_dict: Dict[str, Dict[str, figure]] = {}

        # Margin above/below lowest/highest as percentage
        _margin_percentage = 10

        for model_name, dataframe in self._data.items():
            # Get list of power variables to plot

            _plot_dict[model_name] = {}

            _gen_params = [i for i in dataframe.columns if "generated" in i.lower()]

            _out_params = [
                i for i in dataframe.columns if i not in _gen_params and i != "time"
            ]

            # Generated first then output
            _power_vars = _gen_params + _out_params

            # Remove extra duplicates containing '.'
            _power_vars = [i for i in _power_vars if "." not in i]

            x_range = None
            y_limits: List[float] = []

            for i, var in enumerate(_power_vars):
                _min = np.min(dataframe[var])
                _min = _min - abs(_min) * (_margin_percentage / 100.0)
                _max = np.max(dataframe[var])
                _max = _max + abs(_max) * (_margin_percentage / 100.0)
                if i == 0:
                    y_limits = [_min, _max]
                if _min < y_limits[0]:
                    y_limits[0] = _min
                if _max > y_limits[1]:
                    y_limits[1] = _max

            y_range_plot = DataRange1d(start=y_limits[0], end=y_limits[1])

            for var in _power_vars:
                # Tidy up the titles a bit more
                if _power_vars[0] not in _plot_dict:
                    _plot = figure(
                        title=_output_plot_title(model_name, var),
                        x_axis_type="linear",
                        x_axis_label=_x_label,
                        y_axis_label=_y_label,
                        y_range=y_range_plot,
                    )
                    x_range = _plot.x_range
                else:
                    _plot = figure(
                        title=_output_plot_title(model_name, var),
                        x_axis_type="linear",
                        x_axis_label=_x_label,
                        y_axis_label=_y_label,
                        x_range=x_range,
                        y_range=y_range_plot,
                    )

                pbm_pc.add_plot_objects(
                    _plot, dataframe["time"], dataframe[var], "time", var
                )

                _plot_dict[model_name][var] = _plot

        return _plot_dict

    def _gen_sweep_plots(self) -> Dict[str, Any]:
        """Generate plots for sweep mode 'set'.

        Returns
        -------
        Dict[str, Any]
            dictionary containing figures
        """

        _x_label = "Time/s"
        _y_label = "Power/W"

        _plots_dict: Dict[str, Any] = {}

        # Margin above/below lowest/highest as percentage
        _margin_percentage = 10

        for model in self._cuts:
            _plots_dict[model] = {}

            for c_id, cut in enumerate(self._cuts[model]):
                _plots_dict[model][c_id] = {}
                _dataframe = self._data[model]
                for param, value in cut.items():
                    _dataframe = _dataframe[_dataframe[param] == value]

                _gen_params = [
                    i for i in self._data[model].keys() if "generated" in i.lower()
                ]

                _out_params = [
                    i
                    for i in self._data[model].keys()
                    if i not in _gen_params and i != "time"
                ]

                # Generated first then output
                _param_list = _gen_params + _out_params

                # Remove extra duplicates containing '.'
                _param_list = [i for i in _param_list if "." not in i]

                # shared x axis
                x_shared = None

                y_limits: List[float] = []

                for i, var in enumerate(_param_list):
                    _min = np.min(_dataframe[var])
                    _min = _min - abs(_min) * (_margin_percentage / 100.0)
                    _max = np.max(_dataframe[var])
                    _max = _max + abs(_max) * (_margin_percentage / 100.0)
                    if i == 0:
                        y_limits = [_min, _max]
                    if _min < y_limits[0]:
                        y_limits[0] = _min
                    if _max > y_limits[1]:
                        y_limits[1] = _max

                y_range_plot = DataRange1d(start=y_limits[0], end=y_limits[1])

                for i, parameter in enumerate(_param_list):
                    if i == 0:
                        _plot = figure(
                            title=_output_plot_title(model, parameter),
                            x_axis_type="linear",
                            x_axis_label=_x_label,
                            y_axis_label=_y_label,
                            y_range=y_range_plot,
                        )
                        x_shared = _plot.x_range
                    else:
                        _plot = figure(
                            title=_output_plot_title(model, parameter),
                            x_axis_type="linear",
                            x_axis_label=_x_label,
                            y_axis_label=_y_label,
                            x_range=x_shared,
                            y_range=y_range_plot,
                        )

                    pbm_pc.add_plot_objects(
                        _plot,
                        _dataframe["time"],
                        _dataframe[parameter],
                        "time",
                        parameter,
                    )

                    _plots_dict[model][c_id][parameter] = _plot

        return _plots_dict

    def _sweep_mode_plots(self) -> Dict[str, Any]:
        _sweep_setup = {}
        for model_name, dataframe in self._data.items():
            # Get the sweep parameter values for this model
            # by comparing those stated in the config with
            # those present in the models output dataframe
            _sweep_vars = [
                i
                for i in self._configuration["sweep"]
                if i.lower() in dataframe.columns
            ]

            _first = list(self._configuration["sweep"].values())[0]

            _sweep_setup[model_name] = {
                k.lower(): self._configuration["sweep"][k] for k in _sweep_vars
            }

            _length = len(_first)

            if self._configuration["sweep_mode"] == "set":
                self._cuts[model_name] = [
                    {
                        param: value[i]
                        for param, value in _sweep_setup[model_name].items()
                    }
                    for i in range(_length)
                ]
            else:
                _combos = itertools.product(*_sweep_setup[model_name].values())

                self._cuts[model_name] = [
                    dict(zip(_sweep_setup[model_name].keys(), i)) for i in _combos
                ]
        return self._gen_sweep_plots()
