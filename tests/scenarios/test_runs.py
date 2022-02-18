import glob
import os
import pathlib
import shutil
import tempfile

import pytest
import toml

from power_balance.cli.session import pbm_main

INTERNAL_PARAMS = os.path.join(
    pathlib.Path(__file__).parents[2], "power_balance", "parameters"
)

TEST_CONFIG = os.path.join(pathlib.Path(__file__).parents[1], "test_config.toml")

TEST_CONFIG_SWEEP = os.path.join(pathlib.Path(__file__).parents[1], "sweep_config.toml")

TEST_NEW_MAGS_PARAMS = os.path.join(
    pathlib.Path(__file__).parents[1], "test_new_magnets_parameters.toml"
)


@pytest.mark.scenarios
def test_run_vanilla_normal():
    with tempfile.TemporaryDirectory() as temp_dir:
        pbm_main(
            config=TEST_CONFIG,
            verbose=True,
            no_browser=False,
            outputdir=temp_dir,
        )


@pytest.mark.scenarios
def test_run_vanilla_sweep():
    with tempfile.TemporaryDirectory() as temp_dir:
        pbm_main(
            config=TEST_CONFIG_SWEEP,
            verbose=True,
            no_browser=True,
            outputdir=temp_dir,
        )


@pytest.mark.scenarios
def test_additional_magnets_run():
    with tempfile.TemporaryDirectory() as temp_dir:
        shutil.copytree(INTERNAL_PARAMS, os.path.join(temp_dir, "params"))
        shutil.copy(
            TEST_NEW_MAGS_PARAMS,
            os.path.join(temp_dir, "params", "tokamak_interdependencies.toml"),
        )
        pbm_main(
            config=TEST_CONFIG,
            verbose=True,
            no_browser=True,
            outputdir=temp_dir,
            param_dir=os.path.join(temp_dir, "params"),
        )
        _out_param = glob.glob(
            os.path.join(
                temp_dir,
                "pbm_results_*",
                "parameters",
                "tokamak_interdependencies.toml",
            )
        )[0]
        assert toml.load(open(_out_param))["magnetpower"]["magnetpf7"]["vdrop"] == 1.45
