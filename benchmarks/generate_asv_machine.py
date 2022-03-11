#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Airspeed Velocity Machine Config File Generation
================================================

GitHub has a lot of runners meaning that results for ASV become over saturated
with data points due to each runner having a unique name. This script aims to
unify all runners of particular specifications to reduce the issue.

"""

__date__ = "2022-03-11"

import typing
import click
import os
import math
import re
import logging
import json
import sys
import subprocess

logging.basicConfig()


@click.command()
@click.argument("asv_config")
@click.option("--version", help="Specify configuration schema version", default=1)
@click.option("--existing", help="Specify existing machine file to append to", default=None)
def create_machine_config(
    asv_config: str,
    version: typing.Optional[str] = "1",
    existing: typing.Optional[str] = None) -> None:
    _machine_metadata: typing.Dict[str, typing.Dict[str, str]] = {}
    _logger = logging.getLogger("GenerateASVMachine")
    _logger.setLevel(logging.INFO)

    _intro_str = f"""
===============================================================================

                Airspeed Velocity Machine Config Generator

                            K. Zarebski, UKAEA


        Input File      : {existing}
        Config File     : {asv_config}
        Schema version  : {version}

===============================================================================
    """

    print(_intro_str)

    if existing:
        if not os.path.exists(existing):
            _logger.warning(
                f"Machine configuration file '{existing}' does not exist, "
                "it will be created"
            )
            _machine_metadata = {}
        else:
            _machine_metadata = json.load(open(existing))

    _json_machine_cmd = [
        sys.executable,
        "-m",
        "asv",
        "machine",
        "--yes",
        "--config",
        asv_config
    ]

    _expected_machine_file = os.path.join(
        os.environ["HOME"],
        ".asv-machine.json"
    )

    subprocess.check_call(_json_machine_cmd, shell=False, stdout=subprocess.PIPE)

    if not os.path.exists(_expected_machine_file):
        raise FileNotFoundError(
            f"Expected generated ASV machine file '{_expected_machine_file}', "
            "but it does not exist."
        )

    _asv_data = json.load(open(_expected_machine_file))
    _asv_machine_data = list(_asv_data.values())[0]

    _arch_local = _asv_machine_data["arch"]
    
    # Unsure what runners GitHub has so for now just track Intel ones
    if "Intel" not in _asv_machine_data["cpu"]:
        raise AssertionError(
            "Only Intel runners currently supported"
        )

    _freq = _asv_machine_data["cpu"].split("@")[1].strip()

    _type = _asv_machine_data["cpu"].split("CPU")[0].strip()
    _series = re.findall(r"\d{4}", _asv_machine_data["cpu"])[0]
    _type = _type.split(_series)[0].replace("-", "")
    _series = f"{int(math.floor(int(_series)/1000))}XXX"
    _cpu = f"{_type}-{_series} @ {_freq}"
    _n_cpu = _asv_machine_data["num_cpu"]
    _os = re.findall(r"^Linux \d+\.\d+\.\d+", _asv_machine_data["os"])[0]
    _ram = f"{int(math.floor(int(_asv_machine_data['ram'])/1E3))}k"

    _new_dat = {
        "arch": _arch_local,
        "cpu": _cpu,
        "num_cpu": _n_cpu,
        "os": _os,
        "ram": _ram
    }

    _current = {}

    if _machine_metadata:
        for values_exist in _machine_metadata.values():
            for key, values in _new_dat.items():
                if values_exist[key] != values[key]:
                    break
            _current = values_exist
            break

    if not _current:
        _new_dat["machine"] = f"gh-machine-group-{len(_machine_metadata)}"
        _machine_metadata[_new_dat["machine"]] = _new_dat
        _current = {_new_dat["machine"]: _new_dat, "version": version}
    
    with open(_expected_machine_file, "w") as out_f:
        _logger.info("Writing current machine session file '%s'", _expected_machine_file)
        json.dump(_current, out_f, indent=2)

    outfile = existing or os.path.join(os.getcwd(), "asv_gh_machines.json")
    
    with open(outfile, "w") as out_f:
        _logger.info("Writing machine listings file '%s'", outfile)
        json.dump(_machine_metadata, out_f, indent=2)
        

if __name__ in "__main__":
    create_machine_config()

