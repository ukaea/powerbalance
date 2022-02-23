# Plugins
Power Balance Models (PBM) supports extensions or "plugins" which act as wrappers preparing parameters and arguments before execution of the core API. These plugins may add additional commands to the CLI, or create the requirement input files to initialise a run.

## Managing Plugins
Plugin are installed by running:

```
powerbalance plugins install <plugin-directory>
```

and removed using the command:

```
powerbalance plugins remove <plugin-name>
```

you can view all currently installed plugins by running:

```
powerbalance plugins list
```

which will display the plugin name (used to remove plugins), and the path of the plugin relative to the `power_balance/plugins` internal directory.


## Plugin Development
Plugins are placed in the `power_balance/plugins` folder in order to be recognised by the central API, this process is automated by the `powerbalance plugins install` command when it is run on the plugin root directory. The command will search for the metadata file, `plugin.toml`, the location of which is taken to be the root of the plugin structure, and then create a new directory using the name of the plugin, as defined within the metadata file (e.g. if the key `name` in the `plugin.toml` file is "My Project", the plugin would be installed to `power_balance/plugins/my_project`). All files within the root location and descending directories are copied during the installation.

The plugin root directory must be importable, containing a `__init__.py` file:

```
.
├── commands.py
├── plugin_functions.py
├── __init__.py
├── plugin.toml
├── my_plugin_tab_template.jinja
└── tests
```

Verify your plugin is recognised by running `powerbalance plugins` to list those available. For configuration options see the relevant section [here](configuration.md#plugin-specification).

### The `plugin.toml` File
Plugins are defined within a TOML file which is placed in the root directory for that plugin. An example file may look like the following:

```toml
name = "My Plugin"
commands = [
    "commands:convert_data"
]

pre_run_script = "plugin_setup:prepare_args"

[options.run.select_myplugin_mode]
param_decls = ["--myplugin-mode"]
help = "Run mode for My Plugin"

[options.run.verbose]
param_decls = ["--verbose/--not-verbose"]
help = "Run in higher verbosity"

[options.run.myplugin_outfile]
param_decls = ["--myplugin-out", "-b", "mpout"]
help = "Output name for my plugin"
```

|**Key**|**Description**|
|---|---|
|`name`|Name of the plugin.|
|`commands`|List of additional `click` commmands to attach to the CLI (see [below](#appending-commands))|
|`pre_run_script`|Script to run before `pbm_main`, the PBM main function call.|
|`options`| A dictionary of additional options to append to the main `powerbalance` subcommands, currently only modifications to `run` is supported.|

### Appending Commands
To append additional commands to the `powerbalance` command group you must provide the path to the commands as a list the format `module_path:command_function`.

In the example above the commands are defined in a file `power_balance/plugins/my_plugin/commands.py`:

```python
import click
import os

from .plugin_commands import demo_func

@click.command()
@click.argument("input_file")
@click.option(
    "--format",
    "-f",
    "fmt",
    default="toml",
    help="Output file format: yaml, pickle, json, toml",
)
@click.option(
    "--output-dir", "-o", default=os.getcwd(), help="Output directory"
)
def convert_data(fmt: str, output_dir: str) -> None:
    demo_func(fmt, output_dir)

```
the `plugin.toml` statement:
```toml
commands = [
    "commands:convert_data"
]
```
then pointing to this click command.

### Appending Options
Further options can be added to the `powerbalance run` command, under the `options.run` key. These are defined with the same arguments given to `click.option`, where `param_decls` defines the flags and variable name for an option:

```toml
[options.run.myplugin_outfile]
param_decls = ["--myplugin-out", "-b", "mpout"]
help = "Output name for my plugin"
```

### Modifying Parameters Before Setup
If your plugin prepares parameters for a PBM run you will want to modify the inputs given during `powerbalance run` to use those prepared instead. The key `pre_run_script` can be given the path of a function.

This function must take a dictionary as an argument, this dictionary being the arguments given by the user to the CLI and thus the `cli.session:pbm_main` function. Your function should then update/add to this dictionary, and hence modify the inputs as required.

!!! important "Argument Modification Clashes"
    Be very careful when modifying inputs, remember if running a simulation with more than one plugin each of these will modify the arguments. This may mean your plugin is not receiving the inputs you expect.


### Displaying Plugin Outputs
Plugins can themselves have displays, these are shown as additional tabs within the PBM browser. Displays are created as additional HTML content held within a Jinja template file. To get the correct expected name for your plugin template file consider loading your `plugin.toml` file into a variable to ensure the same name is used:

`plugins/my_plugin/__init__.py`

```python
import toml
import path

PLUGIN_METADATA = toml.load(
    os.path.join(os.path.dirname(__file__), "plugin.toml")
)
```

`plugins/my_plugin/results.py`

```python
...

_display_file = get_plugin_display_filename(PLUGIN_METADATA["name"])

with open(_display_file, 'w') as out_html:
    out_html.write(plugin_html_str)

...
```

If your display requires extra HTML files make sure they have a name unique to the plugin
and copy them to the correct location using the `PLUGIN_DISPLAY_DIR` variable:

```python
import shutil
from power_balance.plugins import get_plugin_display_filename, PLUGIN_DISPLAY_DIR

...

my_plugin_extra_html = "my_plugin_extras.html"
component_file = os.path.join(
    PLUGIN_DISPLAY_DIR,
    my_plugin_extra_html
)
shutil.copy(my_plugin_extra_html, component_file)

...
```