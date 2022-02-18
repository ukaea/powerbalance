import os
import pathlib
import tempfile

import pytest

from power_balance.cli.session import pbm_main


@pytest.fixture
def test_config():
    _test_dir = pathlib.Path(os.path.dirname(__file__)).parent
    return os.path.join(_test_dir, "test_config.toml")


@pytest.mark.cli
def test_raise_on_bad_pre_session(test_config):
    """Check that session is terminated if bad pre-session specified

    Test checks that exceptions are thrown if bad arguments given for a
    session launched from a previous session.
    """
    with pytest.raises(FileNotFoundError) as pytest_wrapped_e:
        pbm_main(test_config, from_session="dummy")
    _temp_dir = tempfile.mkdtemp()
    assert pytest_wrapped_e.type == FileNotFoundError
    with pytest.raises(FileNotFoundError) as pytest_wrapped_e:
        pbm_main(test_config, from_session=_temp_dir)
    assert pytest_wrapped_e.type == FileNotFoundError
    os.mkdir(os.path.join(_temp_dir, "parameters"))
    with pytest.raises(FileNotFoundError) as pytest_wrapped_e:
        pbm_main(test_config, from_session=_temp_dir)
    assert pytest_wrapped_e.type == FileNotFoundError
    os.mkdir(os.path.join(_temp_dir, "configs"))
    with pytest.raises(FileNotFoundError) as pytest_wrapped_e:
        pbm_main(test_config, from_session=_temp_dir)
    assert pytest_wrapped_e.type == FileNotFoundError
    os.mkdir(os.path.join(_temp_dir, "profiles"))
    with pytest.raises(FileNotFoundError) as pytest_wrapped_e:
        pbm_main(test_config, from_session=_temp_dir)
    assert pytest_wrapped_e.type == FileNotFoundError
