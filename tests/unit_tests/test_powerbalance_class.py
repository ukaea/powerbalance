#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Power Balance Class Unit Tests
==============================

Unit tests for testing the functionality of the PowerBalance class
these tests are a based on the original unittest tests by S. Gribben
updated for the code restructure and now using pytest.

"""

__date__ = "2021-02-24"

import glob
import logging
import os
import pathlib
import re
import tempfile

import pytest
from pydelica import logger as pde_logging

from power_balance.core import PowerBalance


@pytest.fixture(scope="module")
def pbm_instance(generate_profiles):
    """Initialise an instance of PowerBalance for testing"""
    _config = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent, "test_config.toml"
    )

    logging.getLogger("PowerBalance").setLevel(logging.INFO)
    pbm = PowerBalance(
        parameter_directory="Default",
        profiles_directory=generate_profiles,
        modelica_file_dir="Default",
        config=_config,
        no_browser=True,
    )

    pbm.pydelica_session._log_level = pde_logging.OMLogLevel.NORMAL

    return pbm


@pytest.fixture(scope="module")
def pbm_run(pbm_instance: PowerBalance):
    with tempfile.TemporaryDirectory() as tempd:
        pbm_instance.testdir = tempd

        # Just use the first model in the list
        _example = pbm_instance.configuration["models"][0]

        pbm_instance.model_example = _example

        pbm_instance.run_simulation(pbm_instance.testdir)

        yield pbm_instance


@pytest.mark.pbm_class
def test_parameter_set(pbm_run: PowerBalance):
    """Test that parameters are actually updated in Modelica"""
    _param_name = "Tokamak.Interdependencies.magnetpower.magnetTF.Vdrop"
    _TEST_VAL = 2

    _out_name = _param_name.split(".")[2:]
    _out_name[-1] = f"__{_out_name[-1]}"
    _out_name = ".".join(_out_name)

    _xml_file = glob.glob(
        os.path.join(
            os.path.dirname(pbm_run.pydelica_session._binaries[pbm_run.model_example]),
            "*_init.xml",
        )
    )[0]

    pbm_run.set_parameter_value(_param_name, _TEST_VAL)
    pbm_run.set_model_parameters(pbm_run.model_example)

    # Need to manually write the parameters as this usually only happens when
    # the PyDelica method 'simulate' is called
    pbm_run.pydelica_session._model_parameters[pbm_run.model_example].write_params()

    with open(_xml_file) as xml_f:
        _lines = xml_f.readlines()

    _test_line = [
        _lines[i + 1]
        for i, _ in enumerate(_lines)
        if all(k in _lines[i] for k in ["Vdrop", "magnetTF"])
    ][0]

    _out_val = re.findall(r"start=\"([0-9e\.\-]+)\"\s", _test_line, re.IGNORECASE)[0]

    assert float(_out_val) == _TEST_VAL


@pytest.mark.pbm_class
def test_configuration(pbm_run: PowerBalance):
    """Test configuration of the class from config files"""
    _model = pbm_run.model_example

    _configuration = pbm_run._parameter_set.get_simulation_options()

    pbm_run.apply_model_configuration(_model)

    _model_options = pbm_run.pydelica_session.get_simulation_options(_model)

    for option, value in _configuration.items():
        if value != _model_options[option]:
            raise AssertionError(
                "Configuration failed for {}: {} != {}".format(
                    option, value, _configuration[option]
                )
            )


@pytest.mark.pbm_class
def test_get_power(pbm_instance: PowerBalance):
    """Test power calculation function"""
    # Check all but first value is non-zero
    _data = pbm_instance.power_data[pbm_instance.model_example]
    _data = _data["netpowergeneration"][1:]
    assert all(abs(_data) > 0)


@pytest.mark.pbm_class
def test_add_model(pbm_instance: PowerBalance):
    """Check that model addition functions correctly"""
    _test_file = os.path.join(
        pathlib.Path(os.path.dirname(__file__)).parent,
        "baseline",
        "TestModel.mo",
    )

    pbm_instance.add_models(_test_file)
    pbm_instance.remove_models(["Tokamak.Interdependencies"])

    assert "UnitTestModel" in pbm_instance._models_list

    _val = float(pbm_instance._parameter_set.get_parameter("unittestmodel.beta"))
    assert _val == 0.3


@pytest.mark.pbm_class
def test_param_sweep(pbm_instance: PowerBalance):
    """Assert that results change with a parameter sweep"""
    _model_data = pbm_instance.power_data["Tokamak.Interdependencies"]
    assert not any(
        _model_data[_model_data["time"] == 2]
        .drop(labels="time", axis=1)
        .diff()[1:]
        .sum()
        != 0
    )


@pytest.mark.pbm_class
def test_sweep_assembly():
    _test_sweep_dict = {
        "var_A": [10, 23, 34, 45],
        "var_B": [34, 23],
        "var_C": [54, 123, 65, 23],
    }
    pbm = PowerBalance()
    with pytest.raises(AssertionError):
        pbm._assemble_sweep_combos(_test_sweep_dict, 4)

    _test_sweep_dict.pop("var_B")

    _expected = [(10, 54), (23, 123), (34, 65), (45, 23)]

    pbm._assemble_sweep_combos(_test_sweep_dict, 4) == _expected


@pytest.mark.pbm_class
def test_browser_launch(pbm_instance: PowerBalance):
    pbm_instance.launch_browser()
