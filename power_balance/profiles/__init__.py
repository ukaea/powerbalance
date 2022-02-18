"""
Input profile generation
========================

Methods for generation of profiles for variable quantities such as current
in the TF Coil and plasma heat energy.

Contents
========

Functions
---------

    gen_thermalpowerout_profile - generates thermal power output values
    gen_nbiheat_profile - generates neutral beam injection heat values
    gen_rfheat_current_profile - generates radio frequency heat values
    gen_tfcoil_current_profile - generates toroidal field coil current values
    gen_cscoil_current_profile - generates central solenoid coil current values
    gen_pf1coil_current_profile - generates first poloidal field coil current values
    gen_pf2coil_current_profile - generates second poloidal field coil current values
    gen_pf3coil_current_profile - generates third poloidal field coil current values
    gen_pf4coil_current_profile - generates fourth poloidal field coil current values
    gen_pf5coil_current_profile - generates fifth poloidal field coil current values
    gen_pf6coil_current_profile - generates sixth poloidal field coil current values
    generate_all - generates all profiles
    read_profile_to_df - reads a '.mat' file profile to a data frame

"""

__date__ = "2021-06-08"

import os
import typing

import numpy as np
import pandas as pd
import scipy.io as sio

# Place generated profiles within mat_profile_files folder
# in the same location as this script
DEFAULT_PROFILES_DIR = os.path.join(os.path.dirname(__file__), "mat_profile_files")

if not os.path.exists(DEFAULT_PROFILES_DIR):
    os.mkdir(DEFAULT_PROFILES_DIR)

_time_array_default = np.linspace(0, 60, 601)
_time_range_default = (10, 20, 40, 50)


def gen_thermalpowerout_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_power: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Creates an array of thermal power output values for the given time array

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_power : float, optional
        maximum power in Watts, default is 1000 MW
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to. If set to None,
        data is not saved, by default uses the module internal
        profile directory.

    Returns
    -------
    np.ndarray
        transposed numpy array of time and plasma heat values
    """
    time_array = _time_array_default

    if stop_time and time_step:
        time_array = np.linspace(0, stop_time, int(stop_time / time_step) + 1)

    time_range = time_range or _time_range_default

    if not max_power:
        max_power = 1000e6
    else:
        max_power *= 1e6

    _stage_1 = time_array[time_array < time_range[1]]

    _stage_2 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_3 = time_array[time_array >= time_range[2]]

    # sets power to one before pulse
    _stage_1 = np.full(len(_stage_1), 1)
    # holds current at flattop value
    _stage_2 = np.full(len(_stage_2), max_power)

    # sets power to one after pulse
    _stage_3 = np.full(len(_stage_3), 1)

    _q_plasma = np.concatenate((_stage_1, _stage_2, _stage_3))

    data = np.transpose([time_array, _q_plasma])

    if output_directory:
        output_file = os.path.join(
            output_directory, "ThermalPowerOut{}.mat".format(label)
        )
        sio.savemat(output_file, {"data": data})

    return data


def gen_nbiheat_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_power: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Creates an array of neutral beam injection heat values for the
    given time array

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_power : float, optional
        maximum power in Watts, default is 60 MW
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to. If set to None,
        data is not saved, by default uses the module internal
        profile directory.

    Returns
    -------
    np.ndarray
        transposed numpy array of time and plasma heat values
    """
    time_array = _time_array_default

    if stop_time and time_step:
        time_array = np.linspace(0, stop_time, int(stop_time / time_step) + 1)

    time_range = time_range or _time_range_default

    if not isinstance(max_power, (float, int)):
        max_power = 60e6
    else:
        max_power *= 1e6

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # sets power to zero before pulse
    _stage_1 = np.full(len(_stage_1), 0)

    # ramps up during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2_1 = _stage_2[(_stage_2 < 1 / 3 * (0.9 * _stage_2[-1]))]
    _stage_2_2 = _stage_2[
        (_stage_2 >= 1 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_3 = _stage_2[
        (_stage_2 >= 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 1.2 * 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_4 = _stage_2[
        (_stage_2 >= 1.2 * 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 1.4 * 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_5 = _stage_2[
        (_stage_2 >= 1.4 * 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < (0.9 * _stage_2[-1]))
    ]
    _stage_2_6 = _stage_2[(_stage_2 >= (0.9 * _stage_2[-1]))]

    _stage_2_1 = np.full(len(_stage_2_1), 0.3 * max_power)
    _stage_2_2 = np.full(len(_stage_2_2), 0.75 * max_power)
    _stage_2_3 = np.full(len(_stage_2_3), 1.2 * max_power)
    _stage_2_4 = np.full(len(_stage_2_4), 1.35 * max_power)
    _stage_2_5 = np.full(len(_stage_2_5), 1.4 * max_power)
    _stage_2_6 = np.full(len(_stage_2_6), 1.5 * max_power)

    _stage_2 = np.concatenate(
        (_stage_2_1, _stage_2_2, _stage_2_3, _stage_2_4, _stage_2_5, _stage_2_6)
    )

    # holds current at flattop value
    _stage_3 -= time_range[1]
    _stage_3_1 = _stage_3[(_stage_3 <= 0.05 * (time_range[1] - time_range[0]))]
    _stage_3_2 = _stage_3[
        (
            (_stage_3 > 0.05 * (time_range[1] - time_range[0]))
            & (_stage_3 <= 0.1 * (time_range[1] - time_range[0]))
        )
    ]
    _stage_3_3 = _stage_3[
        (
            (_stage_3 > 0.1 * (time_range[1] - time_range[0]))
            & (_stage_3 <= 0.15 * (time_range[1] - time_range[0]))
        )
    ]
    _stage_3_4 = _stage_3[
        (
            (_stage_3 > 0.15 * (time_range[1] - time_range[0]))
            & (_stage_3 < 0.95 * (time_range[2] - time_range[1]))
        )
    ]
    _stage_3_5 = _stage_3[
        (
            (_stage_3 >= 0.95 * (time_range[2] - time_range[1]))
            & (_stage_3 < 0.975 * (time_range[2] - time_range[1]))
        )
    ]
    _stage_3_6 = _stage_3[(_stage_3 >= 0.975 * (time_range[2] - time_range[1]))]

    _stage_3_1 = np.full(len(_stage_3_1), 1.5 * max_power)
    _stage_3_2 = np.full(len(_stage_3_2), 1.3 * max_power)
    _stage_3_3 = np.full(len(_stage_3_3), 1.2 * max_power)
    _stage_3_4 = np.full(len(_stage_3_4), max_power)
    _stage_3_5 = np.full(len(_stage_3_5), 1.3 * max_power)
    _stage_3_6 = np.full(len(_stage_3_6), 1.5 * max_power)

    _stage_3 = np.concatenate(
        (_stage_3_1, _stage_3_2, _stage_3_3, _stage_3_4, _stage_3_5, _stage_3_6)
    )

    # ramps down during plasma ramp-down
    _stage_4 -= time_range[2]

    _stage_4_1 = _stage_4[(_stage_4 < (0.2 * _stage_4[-1]))]

    _stage_4_2 = _stage_4[
        (_stage_4 >= (0.2 * _stage_4[-1])) & (_stage_4 < 2 / 3 * (0.9 * _stage_4[-1]))
    ]
    _stage_4_3 = _stage_4[
        (_stage_4 >= 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < 1.4 * 2 / 3 * (0.9 * _stage_4[-1]))
    ]

    _stage_4_4 = _stage_4[
        (_stage_4 >= 1.4 * 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < 1.5 * 2 / 3 * (0.9 * _stage_4[-1]))
    ]

    _stage_4_5 = _stage_4[
        (_stage_4 >= 1.5 * 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < (0.9 * _stage_4[-1]))
    ]

    _stage_4_6 = _stage_4[(_stage_4 >= (0.9 * _stage_4[-1]))]

    _stage_4_1 = np.full(len(_stage_4_1), 1.5 * max_power)
    _stage_4_2 = np.full(len(_stage_4_2), 1.3 * max_power)
    _stage_4_3 = np.full(len(_stage_4_3), 0.9 * max_power)
    _stage_4_4 = np.full(len(_stage_4_4), 0.7 * max_power)
    _stage_4_5 = np.full(len(_stage_4_5), 0.5 * max_power)
    _stage_4_6 = np.full(len(_stage_4_6), 0.2 * max_power)

    _stage_4 = np.concatenate(
        (_stage_4_1, _stage_4_2, _stage_4_3, _stage_4_4, _stage_4_5, _stage_4_6)
    )

    # sets power to zero after pulse
    _stage_5 = np.full(len(_stage_5), 0)

    _q_plasma = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _q_plasma])

    if output_directory:
        output_file = os.path.join(output_directory, "NBI_Heat{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_rfheat_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_power: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Creates an array of radio frequency heat values for the given time array

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_power : float, optional
        maximum power in Watts, default is 60 MW
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to. If set to None,
        data is not saved, by default uses the module internal
        profile directory.

    Returns
    -------
    np.ndarray
        transposed numpy array of time and plasma heat values
    """
    time_array = _time_array_default

    if stop_time and time_step:
        time_array = np.linspace(0, stop_time, int(stop_time / time_step) + 1)

    time_range = time_range or _time_range_default

    if not isinstance(max_power, (float, int)):
        max_power = 60e6
    else:
        max_power *= 1e6

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # sets power to zero before pulse
    _stage_1 = np.full(len(_stage_1), 0)

    # ramps up during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2_1 = _stage_2[(_stage_2 < 1 / 3 * (0.9 * _stage_2[-1]))]
    _stage_2_2 = _stage_2[
        (_stage_2 >= 1 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_3 = _stage_2[
        (_stage_2 >= 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 1.2 * 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_4 = _stage_2[
        (_stage_2 >= 1.2 * 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < 1.4 * 2 / 3 * (0.9 * _stage_2[-1]))
    ]
    _stage_2_5 = _stage_2[
        (_stage_2 >= 1.4 * 2 / 3 * (0.9 * _stage_2[-1]))
        & (_stage_2 < (0.9 * _stage_2[-1]))
    ]
    _stage_2_6 = _stage_2[(_stage_2 >= (0.9 * _stage_2[-1]))]

    _stage_2_1 = np.full(len(_stage_2_1), 0.3 * max_power)
    _stage_2_2 = np.full(len(_stage_2_2), 0.75 * max_power)
    _stage_2_3 = np.full(len(_stage_2_3), 1.2 * max_power)
    _stage_2_4 = np.full(len(_stage_2_4), 1.35 * max_power)
    _stage_2_5 = np.full(len(_stage_2_5), 1.4 * max_power)
    _stage_2_6 = np.full(len(_stage_2_6), 1.5 * max_power)

    _stage_2 = np.concatenate(
        (_stage_2_1, _stage_2_2, _stage_2_3, _stage_2_4, _stage_2_5, _stage_2_6)
    )

    # holds current at flattop value
    _stage_3 -= time_range[1]
    _stage_3_1 = _stage_3[(_stage_3 <= 0.05 * (time_range[1] - time_range[0]))]
    _stage_3_2 = _stage_3[
        (
            (_stage_3 > 0.05 * (time_range[1] - time_range[0]))
            & (_stage_3 <= 0.1 * (time_range[1] - time_range[0]))
        )
    ]
    _stage_3_3 = _stage_3[
        (
            (_stage_3 > 0.1 * (time_range[1] - time_range[0]))
            & (_stage_3 <= 0.15 * (time_range[1] - time_range[0]))
        )
    ]
    _stage_3_4 = _stage_3[
        (
            (_stage_3 > 0.15 * (time_range[1] - time_range[0]))
            & (_stage_3 < 0.95 * (time_range[2] - time_range[1]))
        )
    ]
    _stage_3_5 = _stage_3[
        (
            (_stage_3 >= 0.95 * (time_range[2] - time_range[1]))
            & (_stage_3 < 0.975 * (time_range[2] - time_range[1]))
        )
    ]
    _stage_3_6 = _stage_3[(_stage_3 >= 0.975 * (time_range[2] - time_range[1]))]

    _stage_3_1 = np.full(len(_stage_3_1), 1.5 * max_power)
    _stage_3_2 = np.full(len(_stage_3_2), 1.3 * max_power)
    _stage_3_3 = np.full(len(_stage_3_3), 1.2 * max_power)
    _stage_3_4 = np.full(len(_stage_3_4), max_power)
    _stage_3_5 = np.full(len(_stage_3_5), 1.3 * max_power)
    _stage_3_6 = np.full(len(_stage_3_6), 1.5 * max_power)

    _stage_3 = np.concatenate(
        (_stage_3_1, _stage_3_2, _stage_3_3, _stage_3_4, _stage_3_5, _stage_3_6)
    )

    # ramps down during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4_1 = _stage_4[(_stage_4 < (0.2 * _stage_4[-1]))]
    _stage_4_2 = _stage_4[
        (_stage_4 >= (0.2 * _stage_4[-1])) & (_stage_4 < 2 / 3 * (0.9 * _stage_4[-1]))
    ]
    _stage_4_3 = _stage_4[
        (_stage_4 >= 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < 1.4 * 2 / 3 * (0.9 * _stage_4[-1]))
    ]
    _stage_4_4 = _stage_4[
        (_stage_4 >= 1.4 * 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < 1.5 * 2 / 3 * (0.9 * _stage_4[-1]))
    ]
    _stage_4_5 = _stage_4[
        (_stage_4 >= 1.5 * 2 / 3 * (0.9 * _stage_4[-1]))
        & (_stage_4 < (0.9 * _stage_4[-1]))
    ]
    _stage_4_6 = _stage_4[(_stage_4 >= (0.9 * _stage_4[-1]))]

    _stage_4_1 = np.full(len(_stage_4_1), 1.5 * max_power)
    _stage_4_2 = np.full(len(_stage_4_2), 1.3 * max_power)
    _stage_4_3 = np.full(len(_stage_4_3), 0.9 * max_power)
    _stage_4_4 = np.full(len(_stage_4_4), 0.7 * max_power)
    _stage_4_5 = np.full(len(_stage_4_5), 0.5 * max_power)
    _stage_4_6 = np.full(len(_stage_4_6), 0.2 * max_power)

    _stage_4 = np.concatenate(
        (_stage_4_1, _stage_4_2, _stage_4_3, _stage_4_4, _stage_4_5, _stage_4_6)
    )

    # sets power to zero after pulse
    _stage_5 = np.full(len(_stage_5), 0)

    _q_plasma = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _q_plasma])

    if output_directory:
        output_file = os.path.join(output_directory, "RF_Heat{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_tfcoil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns a Toroidal Field coil current value to each time step within
    the given time array

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 60 kA
    label : str, optional
        extra indentifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and tfcoil current values
    """
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 60e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[3])]

    _stage_3 = time_array[time_array >= time_range[3]]

    # ramps up current to the peak during premagnetization
    _stage_1 *= max_current / time_range[0]

    # holds current at flattop value
    _stage_2 -= time_range[0]
    _stage_2 = np.full(len(_stage_2), max_current)

    # ramps current down from peak during end of magnetization
    _stage_3 -= time_range[3]
    _stage_3 *= -max_current / time_range[0]
    _stage_3 += max_current

    # note that the TF coil profile accepts a tuple with 4 values but only uses two of them

    _current = np.concatenate((_stage_1, _stage_2, _stage_3))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentTF{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_cscoil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns a Central Solenoid coil current value for each step in the
    given time array the result is saved by default for usage in the modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 50 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and cscoil current values
    """
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    peak_fraction = 0.8
    if not max_current:
        max_current = 50e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[time_array >= time_range[2]]

    # ramps current to peak during premagnetization
    _stage_1 *= max_current / time_range[0]

    # ramps current to near-negative-peak during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= -(max_current + peak_fraction * max_current) / (
        time_range[1] - time_range[0]
    )
    _stage_2 += max_current

    # creeps current to negative peak during plasma flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= -(1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 -= peak_fraction * max_current

    # ramps current to zero during plasma ramp-down through end of magnetization
    _stage_4 -= time_range[2]
    _stage_4 *= max_current / _stage_4[-1]
    _stage_4 -= max_current

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentCS{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf1coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the first Poloidal Field for each step in
    the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 10 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf1coil current values
    """
    peak_fraction = 0.9
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 10e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # ramps up to near-peak during premagnetization
    _stage_1 *= peak_fraction * max_current / time_range[0]

    # ramps to actual peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= (1 - peak_fraction) * max_current / (time_range[1] - time_range[0])
    _stage_2 += peak_fraction * max_current

    # ramps current down during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= -(1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 += max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -peak_fraction * max_current / (time_range[3] - time_range[2])
    _stage_4 += peak_fraction * max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF1{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf2coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the second Poloidal Field (PF) for each step
    in the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 5 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf2coil current values
    """
    peak_fraction = 0.1
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 5e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # ramps up to peak during premagnetization
    _stage_1 *= max_current / time_range[0]

    # ramps down to near-peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= -peak_fraction * max_current / (time_range[1] - time_range[0])
    _stage_2 += max_current

    # ramps current down during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= -peak_fraction * max_current / (time_range[2] - time_range[1])
    _stage_3 += (1 - peak_fraction) * max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -(1 - 2 * peak_fraction) * max_current / (time_range[3] - time_range[2])
    _stage_4 += (1 - 2 * peak_fraction) * max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF2{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf3coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the third Poloidal Field (PF) for each step in
    the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 2 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf3coil current values
    """
    peak_fraction = 0.9
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 2e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # zero current during premagnetization
    _stage_1 *= 0

    # ramps to near-peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= peak_fraction * max_current / (time_range[1] - time_range[0])

    # ramps current to actual peak during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= (1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 += peak_fraction * max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -max_current / (time_range[3] - time_range[2])
    _stage_4 += max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF3{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf4coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the fourth Poloidal Field (PF) for each step
    in the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 5 kA
    label: str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf4coil current values
    """
    peak_fraction = 0.8
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 5e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # zero current during premagnetization
    _stage_1 *= 0

    # ramps to peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= max_current / (time_range[1] - time_range[0])

    # ramps current down to near-peak during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= -(1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 += max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -peak_fraction * max_current / (time_range[3] - time_range[2])
    _stage_4 += peak_fraction * max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF4{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf5coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the fifth Poloidal Field (PF) for each step in
    the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 3 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf5coil current values
    """
    peak_fraction = 0.9
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 3e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # zero current during premagnetization
    _stage_1 *= 0

    # ramps to peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= max_current / (time_range[1] - time_range[0])

    # ramps current down to near-peak during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= -(1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 += max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -peak_fraction * max_current / (time_range[3] - time_range[2])
    _stage_4 += peak_fraction * max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF5{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def gen_pf6coil_current_profile(
    stop_time: int = None,
    time_step: float = None,
    time_range: typing.Tuple[float, ...] = None,
    max_current: float = None,
    label: str = "",
    output_directory: str = DEFAULT_PROFILES_DIR,
) -> np.ndarray:
    """Assigns current value for the sixth Poloidal Field (PF) for each step in
    the given time array the result is saved by default for usage in the
    modelica models.

    Parameters
    ----------
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    max_current : float, optional
        maximum current in Amperes, default is 5 kA
    label : str, optional
        extra identifier for this profile
    output_directory : str, optional
        name of directory to save the dataset to.
        If set to None, data is not saved, by default uses the module internal
        profile directory

    Returns
    -------
    np.ndarray
        transposed numpy array of time and pf6coil current values
    """
    peak_fraction = 0.9
    time_array = (
        np.linspace(0, stop_time, (int(stop_time / time_step) + 1))
        if stop_time and time_step
        else _time_array_default
    )
    time_range = time_range or _time_range_default
    if not max_current:
        max_current = 5e3

    _stage_1 = time_array[time_array < time_range[0]]

    _stage_2 = time_array[(time_array >= time_range[0]) & (time_array < time_range[1])]

    _stage_3 = time_array[(time_array >= time_range[1]) & (time_array < time_range[2])]

    _stage_4 = time_array[(time_array >= time_range[2]) & (time_array < time_range[3])]

    _stage_5 = time_array[time_array >= time_range[3]]

    # zero current during premagnetization
    _stage_1 *= -(peak_fraction / 2) * max_current / time_range[0]

    # ramps to near-peak current during plasma ramp-up
    _stage_2 -= time_range[0]
    _stage_2 *= peak_fraction * 3 / 2 * max_current / (time_range[1] - time_range[0])
    _stage_2 -= max_current * peak_fraction / 2

    # ramps current up to peak during flat-top
    _stage_3 -= time_range[1]
    _stage_3 *= (1 - peak_fraction) * max_current / (time_range[2] - time_range[1])
    _stage_3 += peak_fraction * max_current

    # ramps current down to zero during plasma ramp-down
    _stage_4 -= time_range[2]
    _stage_4 *= -max_current / (time_range[3] - time_range[2])
    _stage_4 += max_current

    # hold current at zero for end of simulation
    _stage_5 -= time_range[3]
    _stage_5 *= 0

    _current = np.concatenate((_stage_1, _stage_2, _stage_3, _stage_4, _stage_5))

    data = np.transpose([time_array, _current])

    if output_directory:
        output_file = os.path.join(output_directory, "currentPF6{}.mat".format(label))
        sio.savemat(output_file, {"data": data})

    return data


def generate_all(
    output_directory: str,
    time_range: typing.Tuple[float, ...] = None,
    stop_time: int = None,
    time_step: int = None,
    max_values: typing.Optional[typing.Dict] = None,
) -> None:
    """Generate all the current profiles in the given directory using
    _time_array_default and _time_range_default, and also using the
    max currents and powers specified in the input to the Power Balance

    Parameters
    ----------
    output_directory : str
        location to save the profile '.mat' files
    time_range : tuple, optional
        the tuple containing information about the plasma scenario.
        typically (ramp-up start, flat-top start, flat-top end, ramp-down end)
    stop_time : int, optional
        the time in seconds at which the profile stops,
        typically the end of the simulation
    time_step : float, optional
        the difference in seconds between each individual step,
        typically matching the time step of the simulation
    max_values : dict, optional
        a dictionary containing information about the maximum currents and powers
        for each profile in the format {'system name': value}
    """
    _dir = os.path.join(output_directory)

    if not max_values:
        max_values = {}

    gen_pf1coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf1", None),
    )

    gen_pf2coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf2", None),
    )

    gen_pf3coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf3", None),
    )

    gen_pf4coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf4", None),
    )

    gen_pf5coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf5", None),
    )

    gen_pf6coil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("pf6", None),
    )

    gen_tfcoil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("tf", None),
    )

    gen_cscoil_current_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_current=max_values.get("cs", None),
    )

    gen_rfheat_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_power=max_values.get("rf", None),
    )

    gen_nbiheat_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_power=max_values.get("nbi", None),
    )

    gen_thermalpowerout_profile(
        output_directory=_dir,
        time_range=time_range,
        stop_time=stop_time,
        time_step=time_step,
        max_power=max_values.get("thermal", None),
    )


def read_profile_to_df(filename: str) -> pd.DataFrame:
    """Open a '.mat' profile file and write contents to a Pandas
    dataframe for easy access

    Parameters
    ----------
    filename : str
        address of the '.mat' file

    Returns
    -------
    pd.DataFrame
        dataframe containing time series data for the given profile

    Raises
    ------
    FileNotFoundError
        if specified input file does not exist
    """
    if not os.path.exists(filename):
        raise FileNotFoundError(
            "Could not load profile from '{}' no such file"
            "or directory".format(filename)
        )

    _contents_array = sio.loadmat(filename)["data"]

    return pd.DataFrame(_contents_array, columns=["time", "value"])
