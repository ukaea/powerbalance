#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                    Power Balance Models CLI

Command line interface for running Power Balance Models, or generating
and viewing profile files used as inputs.
"""

__date__ = "2021-06-08"

import glob
import os
import pathlib
from typing import Optional

import click

import power_balance
import power_balance.cli.session as pbm_session
import power_balance.configs as pbm_conf
import power_balance.parameters as pbm_param
import power_balance.plotting as pbm_plot
import power_balance.plugins as pbm_plugin
import power_balance.profiles as pbm_prof


@click.group()
@click.version_option(version=power_balance.__version__)
def powerbalance():
    """Power Balance Models CLI for running models,
    as well as generating and viewing profiles.
    """


@click.command()
@click.option(
    "--config",
    default=pbm_conf.config_default,
    help="TOML configuration file.",
)
@click.option("--verbose/--no-verbose", default=False, help="Run in Debug Mode")
@click.option(
    "--no-browser/--browser",
    default=False,
    help="Run without launching result browser",
    show_default=True,
)
@click.option(
    "--outputdir",
    default=os.getcwd(),
    help="Output directory, default is current directory",
)
@click.option("--param-dir", default="Default", help="Location of parameter files")
@click.option("--model-dir", default="Default", help="Modelica model file directory")
@click.option("--profiles-dir", default="Default", help="Directory containing profiles")
@click.option(
    "--from-session",
    help="Run Power Balance using an existing session output directory",
    default=None,
)
def run(*args, **kwargs):
    """Launch and run a PBM simulation session"""
    pbm_session.pbm_main(*args, **kwargs)


@click.command()
@click.option("--outdir", default=None, help="Profile output directory")
def generate_profiles(outdir: str = "") -> None:
    """Generate profiles used as model inputs"""
    if not outdir:
        outdir = os.path.join(
            pathlib.Path(os.path.dirname(__file__)).parent,
            "profiles",
            "mat_profile_files",
        )
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    pbm_prof.generate_all(outdir)


@click.command()
@click.argument("output_dir")
def new(output_dir: str) -> None:
    """Create a new project folder with modifiable a parameter set"""
    os.makedirs(output_dir)
    _params = glob.glob(
        os.path.join(pathlib.Path(__file__).parents[1], "parameters", "*.toml")
    )

    # Need to remove the "DO NOT EDIT" lines
    for param_file in _params:
        _out_file = os.path.join(output_dir, os.path.basename(param_file))
        pbm_param.remove_do_not_edit_header(param_file, _out_file)

    click.echo(f"Created new parameter set directory '{os.path.abspath(output_dir)}'")


@click.command()
@click.argument("input_mat_file")
@click.option("--head", help="display head n rows", default=None, type=int)
@click.option("--tail", help="display tail n rows", default=None, type=int)
def view_profile(
    input_mat_file: str = "", head: Optional[int] = None, tail: Optional[int] = None
) -> None:
    """View a profile within a '.mat' file"""
    _data_frame = pbm_prof.read_profile_to_df(input_mat_file)

    head = int(head) if head else 0
    tail = int(tail) if tail else 0

    print(_data_frame[:head][tail:])


@click.command("view-results")
@click.argument("output_dir")
def view_results(output_dir) -> None:
    """Launch browser window from output directory"""
    pbm_plot.launch_viewer(output_dir)


@click.group()
def plugins() -> None:
    """Commands relating to plugins"""
    pass


@plugins.command(name="list")
def plugins_list() -> None:
    """Lists all available plugins"""
    print("\nAvailable Power Balance Models plugins:\n")
    for plugin_meta in pbm_plugin.get_plugin_listing().values():
        print(f"\t{plugin_meta['name']:<20}:\tplugins/{plugin_meta['directory']:<50}")
    print("\n")


@plugins.command()
@click.argument("plugin_directory")
def install(plugin_directory: str) -> None:
    """Installs a plugin from the given directory"""
    pbm_plugin.install_plugin(plugin_directory)


@plugins.command()
@click.argument("plugin_name")
def remove(plugin_name: str) -> None:
    """Remove a plugin by name"""
    pbm_plugin.remove_plugin(plugin_name)


pbm_plugin.apply_modifications_to("run", run)
powerbalance.add_command(run)
powerbalance.add_command(new)
powerbalance.add_command(view_profile)
powerbalance.add_command(generate_profiles)
powerbalance.add_command(view_results)
powerbalance.add_command(plugins)
pbm_plugin.add_plugin_commands(powerbalance)

if __name__ in "__main__":
    powerbalance()
