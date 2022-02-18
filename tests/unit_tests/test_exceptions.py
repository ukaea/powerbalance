import pytest

import power_balance.exceptions as pde


def _general_exception_test(exception):
    _msg = "demo message"
    try:
        raise exception(_msg)
    except exception as e:
        assert e.args[0] == _msg


@pytest.mark.exceptions
def test_unid_param_error():
    _general_exception_test(pde.UnidentifiedParameterError)


@pytest.mark.exceptions
def test_translation_error():
    _general_exception_test(pde.TranslationError)


@pytest.mark.exceptions
def test_inv_input_error():
    _general_exception_test(pde.InvalidInputError)


@pytest.mark.exceptions
def test_mod_param_error():
    _param_name = "parameter_name"
    try:
        raise pde.ModelicaParameterError(_param_name)
    except pde.ModelicaParameterError as e:
        assert _param_name in e.args[0]
        assert e.param_name == _param_name


@pytest.mark.exceptions
def test_intern_error():
    _general_exception_test(pde.InternalError)
