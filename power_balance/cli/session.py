#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                    Power Balance Models Session

This script launches the full Power Balance Models system running the
models specified within the given configuration file using any parameters
specified in the given parameter directory, or model defaults.

"""

import logging
import os
from typing import Optional

import power_balance.core as pbm_core
import power_balance.plugins as pbm_plugins


def pbm_main(
    config: str,
    verbose: bool = False,
    no_browser: bool = False,
    outputdir: str = os.getcwd(),
    param_dir: str = "Default",
    model_dir: str = "Default",
    profiles_dir: str = "Default",
    from_session: Optional[str] = "",
    **kwargs,
) -> None:
    """Runs a Power Balance Models session

    Parameters
    ----------
    config : str
        address/path of configuration file
    verbose : bool, optional
        increase verbosity of output, by default False
    no_browser : bool, optional
        do not open browser on completion, by default False
    outputdir : str, optional
        output data directory, by default current directory
    param_dir : str, optional
        location of model parameter files, defaults to internal parameters
    model_dir : str, optional
        location of models, defaults to internal model directory
    profiles_dir : str, optional
        location of profiles, defaults to internal profile directory
    from_session : str, optional
        start a new run from the output of a previous run, by default None

    Raises
    ------
    FileNotFoundError
        if any of the expected inputs are not found
    """
    debug = logging.DEBUG if verbose else logging.INFO

    _args = locals().copy()
    _args.update(kwargs)

    pbm_plugins.prepare_from_plugins(_args)

    logging.getLogger("PowerBalance").setLevel(debug)

    if _args["from_session"]:
        _check_session_directories(_args)

    with pbm_core.PowerBalance(
        config=_args["config"],
        no_browser=_args["no_browser"],
        parameter_directory=_args["param_dir"],
        profiles_directory=_args["profiles_dir"],
        modelica_file_dir=_args["model_dir"],
        print_intro=True,
    ) as pbm_instance:
        pbm_instance.run_simulation(_args["outputdir"])

        if not no_browser:
            pbm_instance.launch_browser()


def _check_session_directories(_args):
    if not os.path.exists(_args["from_session"]):
        raise FileNotFoundError(
            "Cannot run Power Balance from '{}'," " directory not found.".format(
                _args["from_session"]
            )
        )
    if not os.path.exists(os.path.join(_args["from_session"], "parameters")):
        raise FileNotFoundError(
            "Expected directory 'parameters' in session directory"
            " '{}', but directory not found.".format(_args["from_session"])
        )
    if not os.path.exists(os.path.join(_args["from_session"], "configs")):
        raise FileNotFoundError(
            "Expected directory 'configs' in session directory"
            " '{}', but directory not found.".format(_args["from_session"])
        )
    if not os.path.exists(os.path.join(_args["from_session"], "profiles")):
        raise FileNotFoundError(
            "Expected directory 'profiles' in session directory"
            " '{}', but directory not found.".format(_args["from_session"])
        )
    _args["profiles_dir"] = os.path.join(_args["from_session"], "profiles")
    _args["config"] = os.path.join(
        _args["from_session"], "configs", "configuration.toml"
    )
    _args["param_dir"] = os.path.join(_args["from_session"], "parameters")
