#!/usr/bin/env python3
""" 
Update Regression Test Baseline Files
"""
import glob
import os.path
import pathlib
import shutil
import tempfile
import power_balance.core as pbm_core
import pickle

import numpy as np
import power_balance.calc.efficiencies as pbm_eff
import power_balance.profiles as pbm_prof

BASELINE_DIR = os.path.dirname(__file__)
PROFILES_DIR = os.path.join(
    pathlib.Path(__file__).parents[2], "power_balance", "profiles", "mat_profile_files"
)


def update_pckl_baseline():
    pickle_files = (
        os.path.join(BASELINE_DIR, "default_heating2elec_eff.pckl"),
        os.path.join(BASELINE_DIR, "default_thermal2elec_eff.pckl"),
    )
    eff_funcs = ("calc_heating_to_elec_eff", "calc_thermal_to_elec_eff")
    keys = ("heating_profile", "thermal_in_profile")
    for pckl_f, func, key in zip(pickle_files, eff_funcs, keys):
        _data = pickle.load(open(pckl_f, "rb"))
        _tmp = _data.copy()
        _tmp[key] = os.path.join(PROFILES_DIR, _tmp[key])
        del _tmp["efficiency"]
        del _tmp["average_generated"]
        del _tmp["average_profile"]
        _data["efficiency"] = getattr(pbm_eff, func)(**_tmp)
        pickle.dump(_data, open(pckl_f, "wb"))


def update_profiles():
    _np_arrays = glob.glob(os.path.join(BASELINE_DIR, "*.npy"))
    for array_file in _np_arrays:
        _name = os.path.basename(array_file)
        _name = _name.split(".npy")[0].replace("_default", "")
        _new_arr = getattr(pbm_prof, f"gen_{_name}")()
        np.save(array_file, _new_arr)


def update_run_data():
    _run_data_dir = os.path.join(BASELINE_DIR, 'run_data')
    pbm = pbm_core.PowerBalance(no_browser=True)
    with tempfile.TemporaryDirectory() as tempd:
        pbm.run_simulation(tempd)
        out_dir = glob.glob(os.path.join(tempd, "pbm_results_*"))[0]
        for dir in os.listdir(out_dir):
            if dir not in ("data", "parameters"):
                shutil.rmtree(os.path.join(out_dir, dir))
        shutil.rmtree(_run_data_dir)
        shutil.copytree(out_dir, _run_data_dir)


if __name__ in "__main__":
    update_pckl_baseline()
    update_profiles()
    update_run_data()
