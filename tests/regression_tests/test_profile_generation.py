import glob
import os
import pathlib

import numpy as np
import pytest

import power_balance.profiles as pbm_profiles


@pytest.fixture(scope="module")
def baseline_data():
    _data = {}
    _baseline_dir = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent, "baseline"
    )
    _np_arrays = glob.glob(os.path.join(_baseline_dir, "*.npy"))

    for array_file in _np_arrays:
        _name = os.path.basename(array_file)
        _name = _name.split(".npy")[0].replace("_default", "")
        _data[_name] = np.load(open(array_file, "rb"))

    return _data


def print_failed_values(arr_1: np.ndarray, arr_2: np.ndarray) -> None:
    _n_failed = 0
    for n, (i, j) in enumerate(zip(arr_1, arr_2)):
        if not np.array_equal(i, j):
            print("[{}] {} != {}".format(n, i, j))
            _n_failed += 1
    print("Total mismatched indices: {}".format(_n_failed))


@pytest.mark.profile_gen
def test_gen_nbiheat_profile(baseline_data):
    _baseline = baseline_data["nbiheat_profile"]
    _test = pbm_profiles.gen_nbiheat_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_rfheat_profile(baseline_data):
    _baseline = baseline_data["rfheat_profile"]
    _test = pbm_profiles.gen_nbiheat_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_tfcoil_current_profile(baseline_data):
    _baseline = baseline_data["tfcoil_current_profile"]
    _test = pbm_profiles.gen_tfcoil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_cscoil_current_profile(baseline_data):
    _baseline = baseline_data["cscoil_current_profile"]
    _test = pbm_profiles.gen_cscoil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf1coil_current_profile(baseline_data):
    _baseline = baseline_data["pf1coil_current_profile"]
    _test = pbm_profiles.gen_pf1coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf2coil_current_profile(baseline_data):
    _baseline = baseline_data["pf2coil_current_profile"]
    _test = pbm_profiles.gen_pf2coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf3coil_current_profile(baseline_data):
    _baseline = baseline_data["pf3coil_current_profile"]
    _test = pbm_profiles.gen_pf3coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf4coil_current_profile(baseline_data):
    _baseline = baseline_data["pf4coil_current_profile"]
    _test = pbm_profiles.gen_pf4coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf5coil_current_profile(baseline_data):
    _baseline = baseline_data["pf5coil_current_profile"]
    _test = pbm_profiles.gen_pf5coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e


@pytest.mark.profile_gen
def test_gen_pf6coil_current_profile(baseline_data):
    _baseline = baseline_data["pf6coil_current_profile"]
    _test = pbm_profiles.gen_pf6coil_current_profile(output_directory=None)
    try:
        assert np.array_equal(_test, _baseline)
    except AssertionError as e:
        print_failed_values(_test, _baseline)
        raise e
