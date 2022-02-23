# Global Configuration File
The global config file contains options which are related to the API session as opposed to Modelica configurations. This configuration is [validated](validation.md) before the session is started. The contents of the default configuration file are:

```toml
models = [ "Tokamak.Interdependencies" ]               	# Default model
parameters_directory  = "Default"                   	# Use built in
simulation_options_file = "simulation_options.toml" 	# Opts TOML file
plasma_scenario_file = "plasma_scenario.toml"       	# Opts TOML file
structural_params_file = "structural_parameters.toml"	# Opts TOML file
profiles_directory = "Default"                      	# Use built in
modelica_file_directory = "Default"                 	# Use built in
```

Options with the value `"Default"` must still be specified, this option specifying to instead use the internal configurations. The default values can be viewed after a run within the output folder.

|**Option**|**Type**|**Description**|**Required**|**Comments**|
|---|---|---|---|---|
|`models`|`List[str]`|List of models to run|:heavy_check_mark:|Make sure these are models and not model components.|
|`parameters_directory`|`str`|Directory containing parameter files|:heavy_check_mark:|Defaults to internal parameter directory|
|`simulation_options_file`|`str`|Identifier for the simulation options file in the parameters directory|:heavy_check_mark:|This is the relative filename not a path|
|`profiles_directory`|`str`|Directory containing the `.mat` profiles|:heavy_check_mark:|Defaults to internal profile directory, is generated if it does not yet exist|
|`modelica_file_directory`|`str`|Directory containing modelica model files|:heavy_check_mark:|Defaults to internal model directory|
|`sweep_mode`|`str`|Type of sweep to perform (if sweep specified)||See [below](#creating-a-parameter-sweep)|
|`structural_params_file`|`str`|Identifier for the structural parameters file in the parameters directory||Overrides the default structured parameters with the values provided (see [here](parameters.md#structural-parameters))|
|`plugins`|Specify which plugins to run and the order in which to run them. By default all installed are used.|

## Plugin Specification
The key `plugins` is not included by default. All plugins will be run in the order given by `os.listdir`. You can specify which plugins to use and in what order by adding this key along with a list:

```toml
plugins = ['My Plugin']
```
this name should match that of the plugin itself, but is case insensitive.

A full list of available plugins is given by running:

```bash
powerbalance plugins
```

!!! important "Order is Important!"
    Plugins can change the input arguments for Power Balance as such the order in which they are executed is important. Given plugins `A`, `B` and `C` which all setup arguments: `A -> B -> C` would not be equivalent to a run order of `B -> C -> A` etc. Therefore usage of `plugins` is recommended where a run will use more than one plugin.

## Creating a parameter sweep
To perform a parameter sweep you will need to add an additional `sweep` section to your configuration file and specify the values to run with.

```toml
[sweep]
Tokamak.Interdependencies.MagnetPower.MagnetPF4.RFeeder = [1E-8, 1E-7, 5E-8]
```

!!! warning "Parameter addresses"
    Parameters must be specified by their complete address within the Modelica model.

There are two sweep modes:

- `set`: run in sequence (i.e. for run `i` use the `i`th element of all sweep parameter lists).
- `combination`: run all possible combinations of all sweep parameters.