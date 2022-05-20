import os
import pathlib

import pydelica
import pytest

from power_balance.environment import MODELICA_ENVIRONMENT
from power_balance.models import get_local_models

TEST_DIR = pathlib.Path(os.path.dirname(__file__)).parent


@pytest.mark.pbm_model_list
def test_model_extraction(parameter_obj_norm):
    """Test model dictonary is populated"""
    _demo_model = "Tokamak.Interdependencies"
    with pydelica.Session(pydelica.OMLogLevel.NORMAL) as _session:
        _session = pydelica.Session(pydelica.OMLogLevel.NORMAL)
        _session.use_libraries(MODELICA_ENVIRONMENT)
        _models = get_local_models(
            model_file_dir=os.path.join(
                pathlib.Path(TEST_DIR).parent, "power_balance", "models"
            ),
            parameter_set=parameter_obj_norm,
            session=_session,
            model_name_list=["Tokamak.Interdependencies"],
        )
    assert _models[_demo_model].compiled
    assert _models[_demo_model].binary_folder
    assert _models[_demo_model].location
    assert _models[_demo_model].name
