#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
                    Power Balance Models Plugins

Adds support for external plugins, these plugins can provide extra options to
the main CLI, as well as setup arguments before they are then read by the main
core functionality.
"""

__date__ = "2022-01-20"

import glob
import importlib
import logging
import os
import pathlib
import shutil
import sys
import tempfile
import typing

import click
import toml

import power_balance.exceptions as pbm_exc
from power_balance.configs import config_default

PLUGINS_DIR = os.path.dirname(__file__)
PLUGIN_FILE = "plugin.toml"
PLUGIN_DISPLAY_DIR = os.path.join(tempfile.mkdtemp(), "plugin_displays")

logger = logging.getLogger("PowerBalance.Plugins")


def get_plugin_listing() -> typing.Dict:
    """Get list of available plugins"""
    _plugin_files: typing.List[str] = glob.glob(
        os.path.join(PLUGINS_DIR, "*", PLUGIN_FILE)
    )

    _plugins: typing.Dict = {}

    for plugin_file in _plugin_files:
        _metadata: typing.MutableMapping = toml.load(plugin_file)
        _metadata["directory"] = os.path.basename(os.path.dirname(plugin_file))
        _plugins[_metadata["name"]] = _metadata

    return _plugins


def extract_commands(plugin_metadata: typing.Dict) -> typing.List[click.Command]:
    """
    Extracts all commands from a given plugin metadata file

    Parameters
    ----------
    plugin_metadata : typing.Dict
        plugin metadata

    Returns
    -------
    typing.List[click.Command]
        list of command objects initialised from the definitions
    """
    _commands: typing.List[click.Command] = []

    if "commands" not in plugin_metadata:
        return _commands

    for plugin in plugin_metadata["commands"]:
        _script_addr, _function = plugin.split(":")
        _module = importlib.import_module(
            f".{plugin_metadata['directory']}.{_script_addr}", "power_balance.plugins"
        )
        _commands.append(getattr(_module, _function))

    return _commands


def add_plugin_commands(parent_command: click.Group) -> None:
    """
    Append CLI commands from plugin to main PBM CLI

    Power Balance Models assumes a plugin is defined by the presence of a
    plugin metadata file 'plugin.toml'

    Parameters
    ----------

    parent_command : click.Group
        the main command group to append additional subcommands to
    """
    for plugin in get_plugin_listing():
        for command in extract_commands(plugin):
            parent_command.add_command(command)


def apply_modifications_to(name: str, function: click.Command) -> None:
    """Applies modifications to the given CLI function"""

    _plugins_list = glob.glob(os.path.join(PLUGINS_DIR, "*", PLUGIN_FILE))

    for plugin in _plugins_list:
        _plugin_meta = toml.load(plugin)

        if "options" not in _plugin_meta:
            return

        if name not in _plugin_meta["options"]:
            return

        for additional_opts in _plugin_meta["options"][name].values():
            function.params.append(click.Option(**additional_opts))


def prepare_from_plugins(pbmmain_call_args: typing.Dict) -> typing.List[str]:
    """Prepare the main method of PBM updating from any plugin modifications"""
    if not os.path.exists(PLUGIN_DISPLAY_DIR):
        os.mkdir(PLUGIN_DISPLAY_DIR)

    _plugins: typing.Dict = get_plugin_listing()

    _config = pbmmain_call_args.get("config", config_default)

    if not _config or _config == "Default":
        _config = config_default

    plugin_order_list = toml.load(_config).get("plugins", None)

    if _plugins:
        pbmmain_call_args["plugins_folder"] = tempfile.mkdtemp()
        pbmmain_call_args["display_plugins_folder"] = os.path.join(
            pbmmain_call_args["plugins_folder"], "plugin_displays"
        )

    if plugin_order_list is None:
        plugin_order_list = tuple(_plugins.keys())
    else:
        plugin_order_list = tuple(plugin_order_list)

    for plugin in plugin_order_list:
        # Retrieve the matching key for the given plugin
        _plugin_key = None

        for key in _plugins:
            if key.lower() == plugin.lower():
                _plugin_key = key

        if not _plugin_key:
            print(
                f"Invalid Plugin: Plugin '{plugin}' in configuration is not recognised."
            )
            sys.exit(1)

        metadata = _plugins[_plugin_key]
        if "pre_run_script" not in metadata:
            continue

        _script_addr, _function = metadata["pre_run_script"].split(":")
        _module = importlib.import_module(
            f".{metadata['directory']}.{_script_addr}", "power_balance.plugins"
        )
        getattr(_module, _function)(pbmmain_call_args)

    return list(_plugins.keys())


def get_plugin_display_filename(plugin_name: str) -> str:
    """Returns the expected display template file for a given plugin"""
    return os.path.join(
        PLUGIN_DISPLAY_DIR, f'plugin_{plugin_name.replace(" ", "_")}.html'
    )


def install_plugin(plugin_directory: str) -> None:
    """
    Install a plugin from a plugin directory

    Parameters
    ----------
    plugin_directory : str
        directory containing required PLUGIN_FILE file
    """
    _plugin_files: typing.Generator = pathlib.Path(plugin_directory).rglob(PLUGIN_FILE)

    if not _plugin_files:
        raise pbm_exc.PluginError(
            f"Location '{plugin_directory}' is not a valid plugin directory"
        )

    _plugin_file: str = next(_plugin_files)

    try:
        _plugin_name: str = toml.load(_plugin_file)["name"]
    except KeyError:
        raise pbm_exc.PluginError(
            f"Expected key 'name' in definition for plugin '{plugin_directory}'"
        )

    _plugin_out_dir = _plugin_name.lower().strip().replace(" ", "_")

    _plugin_main_dir: str = os.path.dirname(_plugin_file)

    logger.debug("Installing plugin from '%s'", _plugin_main_dir)

    _out_loc = os.path.join(PLUGINS_DIR, _plugin_out_dir)
    shutil.copytree(_plugin_main_dir, _out_loc)
    click.echo(f"Successfully installed plugin '{_plugin_name}'.")


def remove_plugin(plugin_name: str) -> None:
    """
    Uninstall a plugin from the plugins directory

    Parameters
    ----------
    plugin_name : str
        name of plugin to remove
    """
    _plugins: typing.Dict = get_plugin_listing()

    if plugin_name not in _plugins:
        raise pbm_exc.PluginError(
            f"Cannot remove plugin '{plugin_name}', as it is not recognised",
        )

    _plugin_dir = _plugins[plugin_name]["directory"]

    logger.debug("Removing directory '%s'", _plugin_dir)
    shutil.rmtree(os.path.join(PLUGINS_DIR, _plugin_dir))
    click.echo(f"Successfully removed plugin '{plugin_name}'.")
