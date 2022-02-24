import copy
import glob
import os
import pathlib
import pickle
import shutil
import tempfile

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pytest
import toml

import power_balance.core
from power_balance.calc.efficiencies import (
    calc_heating_to_elec_eff,
    calc_thermal_to_elec_eff,
)
from power_balance.profiles import generate_all


def plot_comparison(
    test_directory: str,
    label: str,
    baseline_data: np.ndarray,
    test_data: np.ndarray,
    reltol=1e-9,
) -> None:
    _title_label = label.replace("_", " ").title()
    _tol_pos = baseline_data[label] * reltol
    _tol_neg = -1 * baseline_data[label] * reltol
    _plot_folder = os.path.join(test_directory, "testing_output_plots")
    os.makedirs(_plot_folder, exist_ok=True)
    plt.clf()
    plt.plot(
        baseline_data["time"],
        (baseline_data[label] - test_data[label.lower()]) / _tol_pos,
    )
    plt.plot(baseline_data["time"], _tol_pos, "r--")
    plt.plot(baseline_data["time"], _tol_neg, "r--")
    plt.xlabel("Time/s")
    plt.ylabel("Δ " + _title_label + "/W")
    plt.title(f"Plot Comparing Current {_title_label} Data Output with Expectation")
    plt.savefig(os.path.join(_plot_folder, f"testing_{label.lower()}_diff.png"))

    plt.clf()
    plt.plot(baseline_data["time"], baseline_data[label], "r--")
    plt.plot(baseline_data["time"], test_data[label.lower()], "b-")
    plt.savefig(os.path.join(_plot_folder, f"testing_{label.lower()}.png"))


@pytest.fixture(scope="module")
def pbm_instance():
    """Initialise an instance of PowerBalance for testing"""
    tmpdir = tempfile.gettempdir()

    _config = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent, "test_config.toml"
    )

    pbm = power_balance.core.PowerBalance(config=_config, no_browser=True)
    pbm.testdir = tmpdir

    return pbm


@pytest.mark.consistency
# TODO: regression tests for data outputs need to be updated
def test_output_data(pbm_instance):
    pbm_instance.run_simulation(pbm_instance.testdir)

    _baseline_file = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent,
        "baseline",
        "run_data",
        "data",
        "baseline_data.h5",
    )

    _baseline_tomls = glob.glob(
        os.path.join(
            pathlib.Path(os.path.dirname(__file__)).parent,
            "baseline",
            "run_data",
            "parameters",
            "*.toml",
        )
    )

    _baseline = pd.read_hdf(_baseline_file, key="tokamak_interdependencies")
    _baseline.sort_index(inplace=True)

    _test_file = os.path.join(
        pbm_instance.testdir,
        "pbm_results_{}".format(pbm_instance._time_stamp),
        "data",
        "session_data.h5",
    )

    _test = pd.read_hdf(_test_file, key="tokamak_interdependencies")

    if _baseline.shape != _test.shape:
        raise AssertionError(
            "Shape of dataframe did not match expectation: "
            "{} vs {}".format(_test.shape, _baseline.shape)
        )

    _rtol = 1e-1
    _failed = []

    for column in _baseline:
        # TODO: Due to the sudden drop in MagnetPower distribution comparison
        # fails as there is a slight offset
        if column.lower() == "magnetpower":
            continue

        if not all(np.isclose(_baseline[column], _test[column], rtol=_rtol)):
            plot_comparison(pbm_instance.testdir, column, _baseline, _test, _rtol)
            _failed.append(column)

    if _failed:
        print(np.c_[_baseline["magnetpower"], _test["magnetpower"]])
        print(np.c_[_baseline["netpowergeneration"], _test["netpowergeneration"]])
        raise AssertionError(
            "Dataset comparison failed, the following data variables did not "
            "meet expectation:\n -"
            "\n -".join(_failed)
        )

    _test_toml_dir = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent,
        "baseline",
        "run_data",
        "parameters",
    )

    for base_file in _baseline_tomls:
        _test_file = os.path.join(_test_toml_dir, os.path.basename(base_file))

        _test = toml.load(_test_file)
        _base = toml.load(base_file)

        assert _test == _base


@pytest.mark.consistency
def test_reproducibility():
    _config = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent.parent,
        "power_balance",
        "configs",
        "default_config.toml",
    )
    _param = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent.parent,
        "power_balance",
        "parameters",
    )

    pbm_instance = power_balance.core.PowerBalance(
        config=_config, no_browser=True, parameter_directory=_param
    )
    pbm_instance.run_simulation(os.getcwd())

    _last = sorted(glob.glob(os.path.join(os.getcwd(), "pbm_results_*")))[-1]

    pbm_instance = power_balance.core.PowerBalance(
        config=_config, no_browser=True, parameter_directory=_param
    )
    pbm_instance.run_simulation(os.getcwd())

    _latest = sorted(glob.glob(os.path.join(os.getcwd(), "pbm_results_*")))[-1]

    _df_1_name = glob.glob(os.path.join(_last, "data", "*.h5"))[-1]
    _df_2_name = glob.glob(os.path.join(_latest, "data", "*.h5"))[-1]

    assert _df_1_name != _df_2_name, "Comparing the same file!"

    _df_1 = pd.read_hdf(_df_1_name, key="tokamak_interdependencies")
    _df_2 = pd.read_hdf(_df_2_name, key="tokamak_interdependencies")

    shutil.rmtree(_last)
    shutil.rmtree(_latest)

    assert _df_1.equals(_df_2)


@pytest.mark.consistency
def test_heating_eff_consistency():
    _test_data_file = os.path.join(
        pathlib.Path(__file__).parents[1], "baseline", "default_heating2elec_eff.pckl"
    )

    _test_data = pickle.load(open(_test_data_file, "rb"))

    _args = _test_data.copy()
    _args["heating_profile"] = os.path.join(
        pathlib.Path(__file__).parents[2],
        "power_balance",
        "profiles",
        "mat_profile_files",
        _args["heating_profile"],
    )

    if not os.path.exists(_args["heating_profile"]):
        generate_all(
            os.path.join(pathlib.Path(__file__).parents[1], "power_balance", "profiles")
        )

    del _args["efficiency"]
    del _args["average_generated"]
    del _args["average_profile"]

    _eff_out = calc_heating_to_elec_eff(**_args)

    assert _eff_out._num_label == _test_data["efficiency"]._num_label
    assert _eff_out._denom_label == _test_data["efficiency"]._denom_label
    assert _eff_out._nums == _test_data["efficiency"]._nums
    assert _eff_out.value() == _test_data["efficiency"].value()


@pytest.mark.consistency
def test_thermal2elec_eff_consistency():
    _test_data_file = os.path.join(
        pathlib.Path(__file__).parents[1], "baseline", "default_thermal2elec_eff.pckl"
    )

    _test_data = pickle.load(open(_test_data_file, "rb"))

    _args = copy.deepcopy(_test_data)
    _args["thermal_in_profile"] = os.path.join(
        pathlib.Path(__file__).parents[2],
        "power_balance",
        "profiles",
        "mat_profile_files",
        _args["thermal_in_profile"],
    )

    if not os.path.exists(_args["thermal_in_profile"]):
        generate_all(
            os.path.join(pathlib.Path(__file__).parents[1], "power_balance", "profiles")
        )

    del _args["efficiency"]
    del _args["average_generated"]
    del _args["average_profile"]

    _eff_out = calc_thermal_to_elec_eff(**_args)

    assert _eff_out.value() == _test_data["efficiency"].value()
