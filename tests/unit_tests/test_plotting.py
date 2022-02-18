import os
import pathlib
import tempfile

import pytest

from power_balance.plotting import launch_viewer


@pytest.mark.plotting
def test_launch_viewer_success():
    with tempfile.TemporaryDirectory() as temp_dir:
        _html_dir = os.path.join(temp_dir, "html")
        os.makedirs(_html_dir)
        pathlib.Path(os.path.join(_html_dir, "viewer.html")).touch()
        launch_viewer(temp_dir)


@pytest.mark.plotting
def test_launch_viewer_failure():
    with pytest.raises(FileNotFoundError) as exc:
        launch_viewer("not_a_directory")
    _expect = "Cannot open viewer for directory 'not_a_directory', folder does not contain valid results"
    assert exc.value.args[0] == _expect
