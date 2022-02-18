import pytest

from power_balance.modelica_templating.pfmagnets import generate_pfmagnets
from power_balance.parameters import PBMParameterSet


@pytest.mark.modelica_templating
def test_read_from_parameters(parameter_obj_norm: PBMParameterSet):
    parameter_obj_norm.set_parameter(
        "tokamak.interdependencies.magnetpower.magnetpf7.maxCurrent", 50e3
    )
    _new_magnet_script = generate_pfmagnets(parameter_obj_norm)
    assert "magnetpf7" in _new_magnet_script.lower()

    # Remove mention of jinja from header before testing no templating remaining
    assert all(
        i not in _new_magnet_script.replace('"<jinja>"', "")
        for i in ["<jinja>", "</jinja>"]
    )
