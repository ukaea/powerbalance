import deepdiff
import pytest

from power_balance.utilities import (convert_to_value, expand_dictionary,
                                     flatten_dictionary)


@pytest.mark.utilities
def test_expand_dict():
    _test_dict = {"A.B.C": 10, "A.B.D": 11, "A.K": 12, "C.D": 13, "C.H.N": 14}
    _expect = {"A": {"B": {"C": 10, "D": 11}, "K": 12}, "C": {"D": 13, "H": {"N": 14}}}
    assert expand_dictionary(_test_dict) == _expect


@pytest.mark.utilities
def test_flatten_dict():
    _test_dict = {
        "A": {"B": {"C": 10, "D": 11}, "K": 12},
        "C": {"D": 13, "H": {"N": 14}},
    }
    _expect = {"A.B.C": 10, "A.B.D": 11, "A.K": 12, "C.D": 13, "C.H.N": 14}
    assert flatten_dictionary(_test_dict) == _expect


@pytest.mark.utilities
def test_convert_to_value():
    assert convert_to_value(True) == True
    assert convert_to_value(False) == False
    _check_list = convert_to_value(["45", "56", "72"])
    assert isinstance(_check_list, list) and _check_list == [45, 56, 72]
    _check_tuple = convert_to_value(("34", "28", "98"))
    assert isinstance(_check_tuple, tuple) and _check_tuple == (34, 28, 98)
    _check_10i = convert_to_value("10")
    assert isinstance(_check_10i, int) and _check_10i == 10
    _check_10f = convert_to_value("10.0")
    assert isinstance(_check_10f, float) and _check_10f == 10.0
    _check_bool = convert_to_value("True")
    assert isinstance(_check_bool, bool) and _check_bool == True
    _check_dict = convert_to_value({"a": ["1", "2", "3"]})
    assert isinstance(_check_dict, dict) and not deepdiff.DeepDiff(
        _check_dict, {"a": [1, 2, 3]}
    )
    _check_dict_deep = convert_to_value(
        {"a": {"v": ["4", "5", "6"], "vi": "56.5"}, "b": "78"}
    )
    _expected = {"a": {"v": [4, 5, 6], "vi": 56.5}, "b": 78}
    assert isinstance(_check_dict_deep, dict) and not deepdiff.DeepDiff(
        _check_dict_deep, _expected
    )
