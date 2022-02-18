#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Efficiency calculations
=======================

Efficiency calculations for power input/output

Functions
---------

calc_thermal_to_elec_eff - calculates efficiency of power_generated/thermal_power_in

"""
import os

import numpy as np
import scipy.io as sio

import power_balance.calc as pbm_calc
import power_balance.exceptions as pbm_exc


def calc_thermal_to_elec_eff(
    thermal_in_profile: str,
    sim_time: np.ndarray,
    total_generated: np.ndarray,
    plasma_scenario: dict,
) -> pbm_calc.Efficiency:
    """Calculate the thermal to electric efficiency

    Uses the thermal out profile and total generated power array to calculate
    the thermal to electric efficiency.

    Parameters
    ----------
    thermal_in_profile : str
        path of MAT file containing profile of thermal output energy from the tokamak
    total_generated : numpy.ndarray
        total power generated

    Returns
    -------
    float
        thermal to electric efficiency value
    """
    if not os.path.exists(thermal_in_profile):
        raise pbm_exc.InvalidInputError(
            f"Cannot load thermal power profile from '{thermal_in_profile}', "
            "file not found"
        )

    _time = sio.loadmat(thermal_in_profile)["data"][:, 0]
    _profile_data = sio.loadmat(thermal_in_profile)["data"][:, 1]
    flat_top_start = np.asarray(
        _time == plasma_scenario["plasma_flat_top_start"]
    ).nonzero()[0][0]
    flat_top_end = np.asarray(
        _time == plasma_scenario["plasma_flat_top_end"]
    ).nonzero()[0][0]
    _avg_prof: float = np.average(_profile_data[flat_top_start:flat_top_end])

    flat_top_start = np.asarray(
        sim_time == plasma_scenario["plasma_flat_top_start"]
    ).nonzero()[0][0]
    flat_top_end = np.asarray(
        sim_time == plasma_scenario["plasma_flat_top_end"]
    ).nonzero()[0][0]
    _avg_gen: float = np.average(total_generated[flat_top_start:flat_top_end])

    _desc = "Ratio of electrical energy output to input thermal energy from Tokamak."

    _eff = pbm_calc.Efficiency(
        name="thermal2elec",
        numerator_name="generated electrical power (W)",
        denominator_name="thermal power in (W)",
        description=_desc,
    )
    _eff.calculate(_avg_gen, _avg_prof)

    return _eff


def calc_heating_to_elec_eff(
    heating_profile: str,
    sim_time: np.ndarray,
    elec_in: np.ndarray,
    plasma_scenario: dict,
) -> pbm_calc.Efficiency:
    """Calculate the thermal to electric efficiency

    Uses the heating in profile and HCD electrical power array to calculate
    the heating to electric efficiency.

    Parameters
    ----------
    heating_profile : str
        path of MAT file containing profile of heating power input to the plasma
    elec_in : numpy.ndarray
        electrical power consumed

    Returns
    -------
    float
        thermal to electric efficiency value
    """
    if not os.path.exists(heating_profile):
        raise pbm_exc.InvalidInputError(
            f"Cannot load plasma heating power profile from '{heating_profile}', "
            "file not found"
        )

    _time = sio.loadmat(heating_profile)["data"][:, 0]
    _profile_data = sio.loadmat(heating_profile)["data"][:, 1]
    flat_top_start = np.asarray(
        _time == plasma_scenario["plasma_flat_top_start"]
    ).nonzero()[0][0]
    flat_top_end = np.asarray(
        _time == plasma_scenario["plasma_flat_top_end"]
    ).nonzero()[0][0]
    _avg_prof: float = np.average(_profile_data[flat_top_start:flat_top_end])

    flat_top_start = np.asarray(
        sim_time == plasma_scenario["plasma_flat_top_start"]
    ).nonzero()[0][0]
    flat_top_end = np.asarray(
        sim_time == plasma_scenario["plasma_flat_top_end"]
    ).nonzero()[0][0]
    _avg_gen: float = np.average(elec_in[flat_top_start:flat_top_end])

    _desc = "Ratio of plasma heating to electrical power input."

    _eff = pbm_calc.Efficiency(
        name="elec2heating",
        numerator_name="heating power (W)",
        denominator_name="electrical power (W)",
        description=_desc,
    )
    _eff.calculate(_avg_prof, _avg_gen)

    return _eff
