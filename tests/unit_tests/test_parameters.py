import os
import pathlib
import tempfile
from typing import MutableMapping

import deepdiff
import pytest
import toml

from power_balance.parameters import PBMParameterSet

TEST_DIR = pathlib.Path(os.path.dirname(__file__)).parent


@pytest.mark.parameters
def test_read_write_consistency(parameter_obj_norm: PBMParameterSet):
    _tempdir = tempfile.mkdtemp()
    parameter_obj_norm.save_to_directory(_tempdir)

    for filename in parameter_obj_norm._model_param_files:
        _out_file = os.path.join(_tempdir, os.path.basename(filename))
        print("FILE: ", filename, _out_file)
        _other = toml.load(_out_file)
        _lower_case = open(filename).read().lower()
        _orig = toml.loads(_lower_case)

        _diff = deepdiff.DeepDiff(
            _orig, _other, ignore_order=True, ignore_string_case=True
        )

        assert not _diff

    for filename in parameter_obj_norm._input_files:
        if os.path.splitext(filename)[1] != ".toml":
            continue
        _other = os.path.join(_tempdir, os.path.basename(filename))
        _orig = parameter_obj_norm.get_file_location(filename)
        assert toml.load(_orig) == toml.load(_other)


@pytest.fixture(scope="module")
def struct_param_dict():
    return {
        "StructParamTestModel": {
            "struct_bool": False,
            "struct_str": "deuterium",
            "struct_int": 1,
            "struct_float": 1.5,
        }
    }


@pytest.mark.parameters
def test_load_struct_parameter_file(
    parameter_obj_struct: PBMParameterSet, struct_param_dict: MutableMapping
):
    assert parameter_obj_struct.load_structural_parameters() == struct_param_dict


@pytest.mark.parameters
def test_set_struct_parameters(parameter_obj_struct: PBMParameterSet):

    file_path = os.path.join(TEST_DIR, "StructParamTestModel.mo")
    file_path_pre_mod = os.path.join(TEST_DIR, "StructParamTestModelModified.mo")

    _new_file = parameter_obj_struct.set_struct_parameters(file_path)
    # Reads in a Modelica model and saves the lines into a list
    with open(_new_file) as file:
        all_lines_mod = file.readlines()

    # Reads in a Modelica model and saves the lines into a list
    with open(file_path_pre_mod) as pre_mod_file:
        all_lines_pre_mod = pre_mod_file.readlines()

    assert all_lines_mod == all_lines_pre_mod
