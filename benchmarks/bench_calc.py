"""
ASV Benchmarks for Calculations
"""
import copy
import os.path
import pathlib
import pickle
import tempfile

import power_balance.calc.efficiencies as pbm_eff
import power_balance.profiles as pbm_prof


class EfficiencyCalcs:
    pretty_name = "Efficiency Calculations"

    def time_thermal2elec_calc(self):
        with tempfile.TemporaryDirectory() as tempd:
            _test_data_file = os.path.join(
                pathlib.Path(__file__).parents[1],
                "tests",
                "baseline",
                "default_thermal2elec_eff.pckl",
            )

            _test_data = pickle.load(open(_test_data_file, "rb"))

            _args = copy.deepcopy(_test_data)

            _args["thermal_in_profile"] = os.path.join(
                tempd,
                _args["thermal_in_profile"],
            )

            pbm_prof.generate_all(tempd)

            del _args["efficiency"]
            del _args["average_generated"]
            del _args["average_profile"]

            pbm_eff.calc_thermal_to_elec_eff(**_args)

    def time_heating_eff_calc(self):
        with tempfile.TemporaryDirectory() as tempd:
            _test_data_file = os.path.join(
                pathlib.Path(__file__).parents[1],
                "tests",
                "baseline",
                "default_heating2elec_eff.pckl",
            )

            _test_data = pickle.load(open(_test_data_file, "rb"))

            _args = _test_data.copy()

            _args["heating_profile"] = os.path.join(
                tempd,
                _args["heating_profile"],
            )

            pbm_prof.generate_all(tempd)

            del _args["efficiency"]
            del _args["average_generated"]
            del _args["average_profile"]

            pbm_eff.calc_heating_to_elec_eff(**_args)
