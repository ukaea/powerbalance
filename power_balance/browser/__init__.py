#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
PBM Output Browser
==================

Creation of webpage display of PBM simulation outputs from a session directory.

Contents
========

Classes
-------

    PBMBrowser - assembles outputs into HTML for browser based display

"""

__date__ = "2021-06-10"

import glob
import logging
import os
import webbrowser
import typing

import numpy as np
import pandas as pd
import scipy.io as sio
import toml
from bokeh.resources import CDN

import power_balance
import power_balance.browser.html_templates as pbm_html
import power_balance.calc as pbm_calc
import power_balance.calc.efficiencies as pbm_effs
import power_balance.exceptions as pbm_exc
import power_balance.plotting.profile_plotting as pbm_plt_prof
import power_balance.plotting.result_plotting as pbm_plt_res


class PBMBrowser:
    """Class for creation of native browser window for plot display"""

    def __init__(self, session_dir: str) -> None:
        """Power Balance Models browser instance.

        Parameters
        ----------
        session_dir : str
            directory containing session output data
        """
        self._logger = logging.getLogger("PowerBalance.PBMBrowser")
        self._session_dir = session_dir
        self._plugins = self._unpack_displays()
        self._plot_html = os.path.join(session_dir, "html", "viewer.html")
        self._setup: typing.Dict = {}
        self._cuts: typing.Dict[str, typing.List[typing.Dict]] = {}
        self._data = self._get_data()

    def _unpack_displays(self) -> typing.Dict[str, str]:
        _display_files = glob.glob(
            os.path.join(self._session_dir, "plugin_displays", "plugin_*")
        )
        return {
            os.path.splitext(os.path.basename(i))[0]
            .replace("plugin_", "")
            .replace("_", " "): open(i)
            .read()
            for i in _display_files
        }

    def _get_data(self) -> typing.Dict[str, pd.DataFrame]:
        """Retrieve all data from the session directory."""
        self._configuration = toml.load(
            os.path.join(self._session_dir, "configs", "configuration.toml")
        )

        _toml_files = glob.glob(os.path.join(self._session_dir, "parameters", "*.toml"))

        _toml_dicts: typing.Dict[str, typing.MutableMapping] = {
            os.path.basename(os.path.splitext(f)[0]): toml.load(f) for f in _toml_files
        }

        _dict_labels = _toml_dicts.keys()

        _setup_keys = [
            "startTime",
            "stopTime",
            "solver",
            "stepSize",
            "tolerance",
        ]

        for param_dict in _dict_labels:
            if any(i in _toml_dicts[param_dict] for i in _setup_keys):
                self._setup = dict(_toml_dicts[param_dict])
                del _toml_dicts[param_dict]
                break

        self._parameters = _toml_dicts

        _dataframe_keys = self._configuration["models"]
        _dataframe_keys = [i.lower().replace(".", "_") for i in _dataframe_keys]

        _h5_file = glob.glob(os.path.join(self._session_dir, "data", "*.h5"))[0]

        return {i: pd.read_hdf(_h5_file, key=i) for i in _dataframe_keys}

    def _create_efficiencies(
        self, plasma_scenario: dict
    ) -> typing.Dict[str, typing.Dict[str, pbm_calc.Efficiency]]:
        """Create a dictionary of efficiencies for displaying

        Constructs a set of powerbalance.calc.Efficiency objects within a
        dictionary depending on available models.

        Returns
        -------
        typing.Dict[str, powerbalance.calc.Efficiency]
            dictionary of Efficiencies
        """
        _efficiencies: typing.Dict[str, typing.Dict[str, pbm_calc.Efficiency]] = {}

        _root_model: str = "Tokamak.Interdependencies"

        if "tokamak_interdependencies" in self._data:
            _efficiencies[_root_model] = {
                "Thermal to Electric": pbm_effs.calc_thermal_to_elec_eff(
                    os.path.join(self._session_dir, "profiles", "ThermalPowerOut.mat"),
                    self._data["tokamak_interdependencies"]["time"],
                    self._data["tokamak_interdependencies"]["powergenerated"],
                    plasma_scenario,
                )
            }

            rf_profile = os.path.join(self._session_dir, "profiles", "RF_Heat.mat")
            nbi_profile = os.path.join(self._session_dir, "profiles", "NBI_Heat.mat")

            if (
                os.path.exists(rf_profile)
                and max(sio.loadmat(rf_profile)["data"][:, 1]) != 0.0
            ):
                _efficiencies[_root_model][
                    "RF to Electric"
                ] = pbm_effs.calc_heating_to_elec_eff(
                    os.path.join(self._session_dir, "profiles", "RF_Heat.mat"),
                    self._data["tokamak_interdependencies"]["time"],
                    self._data["tokamak_interdependencies"]["hcdsystem"],
                    plasma_scenario,
                )
            if (
                os.path.exists(nbi_profile)
                and max(sio.loadmat(nbi_profile)["data"][:, 1]) != 0.0
            ):
                _efficiencies[_root_model][
                    "NBI to Electric"
                ] = pbm_effs.calc_heating_to_elec_eff(
                    os.path.join(self._session_dir, "profiles", "NBI_Heat.mat"),
                    self._data["tokamak_interdependencies"]["time"],
                    self._data["tokamak_interdependencies"]["hcdsystem"],
                    plasma_scenario,
                )

        return _efficiencies

    def _create_steady_state(self, plasma_scenario: dict) -> typing.Dict[str, float]:
        """Create a dictionary of steady-state values for displaying

        This function collects the results datasets for each model and, based on the flat-top of the plasma,
        generates a "steady-state" value for each dataset,

        Returns
        -------
        typing.Dict[str, float]
            dictionary of steady-state values
        """
        averages = {}

        if "tokamak_interdependencies" in self._data:
            flat_top_start = np.asarray(
                self._data["tokamak_interdependencies"]["time"]
                == plasma_scenario["plasma_flat_top_start"]
            ).nonzero()[0][0]
            flat_top_end = np.asarray(
                self._data["tokamak_interdependencies"]["time"]
                == plasma_scenario["plasma_flat_top_end"]
            ).nonzero()[0][0]

            thermal_in_profile = os.path.join(
                self._session_dir, "profiles", "ThermalPowerOut.mat"
            )
            if not os.path.exists(thermal_in_profile):
                raise pbm_exc.InvalidInputError(
                    f"Cannot load thermal power profile from '{thermal_in_profile}', "
                    "file not found"
                )

            var_dict = {
                "Average Magnet Systems Electricity Consumption (MW)": "magnetpower",
                "Average Heating and Current Drive Electricity Consumption (MW)": "hcdsystem",
                "Average Cryogenic System Electricity Consumption (MW)": "cryogenicpower",
                "Average Waste Heat Electricity Consumption (MW)": "wasteheatpower",
                "Average Coolant Detritiation Electricity Consumption (MW)": "coolantdetritpower",
                "Average Blanket Detritiation Electricity Consumption (MW)": "blanketdetritpower",
                "Average Air-Gas Detritiation Electricity Consumption (MW)": "air_gas_power",
                "Average Water Detritiation Electricity Consumption (MW)": "water_detrit_power",
                "Average Vacuum Pump Electricity Consumption (MW)": "total_vacuumpump_power",
                "Average Total Electrical Power Consumption (MW)": "netpowerconsumption",
                "Average Electrical Power Generation (MW)": "powergenerated",
                "Average Net Electrical Power Output (MW)": "netpowergeneration",
            }

            for var, value in var_dict.items():
                try:
                    averages[var] = (
                        np.average(
                            self._data["tokamak_interdependencies"][var_dict[var]][
                                int(flat_top_start * 1.1) : int(
                                    flat_top_end - flat_top_start * 0.1
                                )
                            ]
                        )
                        / 1e6
                    )
                except KeyError:
                    self._logger.warning(
                        "\nModel output key not found: '%s'."
                        "It corresponds to data set named '%s'; this is most likely because a model has been removed.",
                        var,
                        value,
                    )

            thermal_time = sio.loadmat(thermal_in_profile)["data"][:, 0]
            thermal_data = sio.loadmat(thermal_in_profile)["data"][:, 1]
            flat_top_start_thermal = np.asarray(
                thermal_time == plasma_scenario["plasma_flat_top_start"]
            ).nonzero()[0][0]
            flat_top_end_thermal = np.asarray(
                thermal_time == plasma_scenario["plasma_flat_top_end"]
            ).nonzero()[0][0]
            averages["Average Plasma Thermal Power Generation (MW)"] = (
                np.average(thermal_data[flat_top_start_thermal:flat_top_end_thermal])
                / 1e6
            )

        return averages

    def _build_parameters_table(self) -> str:
        """Create table of parameters.

        Returns
        -------
        str
            HTML table string
        """
        return pbm_html.render_parameter_table(self._parameters)

    def build(self, plasma_scenario: dict) -> None:
        """Build the main webpage for plot display."""
        _ts_component = self._session_dir.replace("pbm_results", "")
        _id = _ts_component.replace("_", "")
        _ts_component_ls = _ts_component.split("_")[1:]
        _time_stamp = ":".join(
            [_ts_component_ls[3], _ts_component_ls[4], _ts_component_ls[5]]
        )
        _time_stamp += " " + "/".join(
            [_ts_component_ls[2], _ts_component_ls[1], _ts_component_ls[0]]
        )

        _profile_plot_build = pbm_plt_prof.ProfilePlotBuilder(
            os.path.join(self._session_dir, "profiles")
        )

        _output_plot_build = pbm_plt_res.OutputPlotBuilder(
            self._configuration, self._data
        )

        _page_str = pbm_html.browser_display_page.render(
            version=power_balance.__version__,
            time_stamp=_time_stamp,
            bokeh_headers=CDN.render(),
            out=_output_plot_build,
            outvar_plots=pbm_html.plot_scroller.render(out=_output_plot_build),
            profile=_profile_plot_build,
            ts_id=_id,
            config=pbm_html.config_table.render(
                configuration=self._configuration, setup=self._setup
            ),
            plugin_tabs=self._plugins,
            params=self._build_parameters_table(),
            eff_tab_content=pbm_html.steady_state_tab.render(
                effs_dict=self._create_efficiencies(plasma_scenario),
                steady_state_dict=self._create_steady_state(plasma_scenario),
            ),
        )

        if not os.path.exists(os.path.join(self._session_dir, "html")):
            os.mkdir(os.path.join(self._session_dir, "html"))

        with open(self._plot_html, "w") as plot_html_f:
            plot_html_f.write(_page_str)

    def launch(self) -> None:
        """Open the plot page in the native web browser.

        Raises
        ------
        FileNotFoundError
            if the plot page has not been generated
        """
        if not self._plot_html:
            raise FileNotFoundError(
                f"HTML file '{self._plot_html}' for plots has not been "
                "generated yet, cannot open in browser."
            )
        webbrowser.open(os.path.abspath(self._plot_html))
