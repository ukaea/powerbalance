#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                Power Balance Models PFMagnet Templating

Creates template entries for multiple PF Magnets in Magnets model using parameter sets
"""

__date__ = "2021-12-02"

import logging
import typing

import power_balance.exceptions as pbm_exc
import power_balance.modelica_templating as pbm_mo
import power_balance.modelica_templating.structures as pbm_mo_struct
import power_balance.parameters as pbm_params

logger = logging.getLogger("PowerBalance.PFMagnetExtension")


def get_pfmagnet_ids_from_params(parameter_set: pbm_params.PBMParameterSet) -> typing.List[int]:
    """Extracts the IDs of PF magnets within the current parameter set

    Parameters
    ----------
    parameter_set : PBMParameterSet
        parameter set containing PF magnet parameters

    Returns
    -------
    typing.List[int]
        list of IDs for PF magnet parameters in the parameter set
    """
    _pf_magnet_params = parameter_set.search("magnetPF")
    if not _pf_magnet_params:
        raise pbm_exc.InvalidInputError(
            "Cannot obtain number of PF magnets from parameter list, "
            "no PF magnet parameters found."
        )

    return [int(i.split("magnetpf")[1].split(".")[0]) for i in _pf_magnet_params]


def generate_pfmagnets(parameter_set: pbm_params.PBMParameterSet) -> str:
    """Generate a new script for the Magnets model using templating

    In cases where the number of PF magnets specified exceeds the default
    6, this function generates a new Modelica script appending these additional
    magnets to the model.

    Parameters
    ----------
    parameter_set : PBMParameterSet
        parameter set to read PF magnet specifications from

    Returns
    -------
    str
        rendered magnet model Modelica script

    Raises
    ------
    pbm_exc.InvalidInputError
        if there was a failure retrieving the PF magnet parameters
    """
    _ncoils = max(get_pfmagnet_ids_from_params(parameter_set))

    # Retrieve the parameter prefix, this saves having to hard code the name
    # of the model where the PF magnets originate
    _param_prefix_srch = parameter_set.search("magnetpf1")

    if not _param_prefix_srch:
        raise pbm_exc.InternalError("Failed to retrieve prefix to magnetPF parameters")

    _param_prefix = _param_prefix_srch[0].split("magnetpf1")[0]

    # Retrieve the combitable spec if given by the user
    _combi_table_selections: typing.List[typing.Tuple[int, int]] = []
    for i in range(7, _ncoils + 1):
        _ctt_param = parameter_set.search(f"{_param_prefix}magnetpf{i}.combitimetable")
        _selection = 1 if not _ctt_param else parameter_set[_ctt_param[0]]
        # Store in the parameter set
        parameter_set.add_non_modelica_parameter(
            f"{_param_prefix}magnetpf{i}.combitimetable", _selection
        )

        logger.debug(
            "Using CombiTimeTablePF%s for additional PF magnet %s", _selection, i
        )
        _combi_table_selections.append((i, _selection))

    # Only add extra magnets for values above the default 6
    _magnet_models = [
        pbm_mo_struct.PFMagModel(*ctt) for ctt in _combi_table_selections
    ]

    logger.debug(_magnet_models)

    _model_template = pbm_mo.load_model_as_template("Magnets")

    return _model_template.render(pf_magnets=_magnet_models)
