# Validation of Inputs
Validation of inputs is performed using [pydantic](https://pydantic-docs.helpmanual.io/) and is based on model representations of the different
configuration files, these models being classes within the source code. The attributes for these classes coincide with the keys for the relevant dictionary to be tested, in the case of Power Balance Models these are dictionaries read from TOML files.

The current schemas are loose but demonstrate the process for possible tightening of constraints in future.

### API Configuration Validation
The global configuration or API configuration input is validated with the following rules:

|**Key**|**Rule**|**Required**|
|---|---|---|
|`models`|Must be of type `List[str]` and contain models defined within the specified models directory.*|:x:|
|`parameters_directory`|Must be a filename, not a path.|:heavy_check_mark:|
|`simulation_options_file`|Must be a filename, not a path..|:heavy_check_mark:|
|`plasma_scenario_file`|Must be a filename, not a path.|:heavy_check_mark:|
|`structural_params_file`|Must be a filename, not a path.|:heavy_check_mark:|
|`profiles_directory`|Must be the path to an existing directory.|
:heavy_check_mark:|
|`parameters_directory`|Must be the path to an existing directory.|
:heavy_check_mark:|
|`modelica_file_directory`|Must be the path to an existing directory.|
:heavy_check_mark:|
|`sweep`|Must be of type `Dict[str, List[T]]`. Where all items in list are the same type.|:x:|
|`sweep_mode`|Must be one of `set` or `combinations`.|:x:|


\* This rule does not apply if `add_model` is used within the API to add a model __after__ the configuration.


### Simulation Options Validation
The Modelica simulation options configuration is validated with the following rules:

|**Key**|**Rule**|**Required**|
|---|---|---|
|`stopTime`|Must be of type `int` and be above 1.|:heavy_check_mark:|
|`startTime`|Must be of type `int` and be positive.|:heavy_check_mark:|
|`stepSize`|Must be of type `int` or `float`, and be positive.|:heavy_check_mark:|
|`solver`|Must be either of type `string` and [recognised](simulation_opts.md#solver-types)|:heavy_check_mark:|
|`tolerance`|Must be of type `float` and positive.|:heavy_check_mark:|

A check is also applied to ensure that the `startTime` is before the `stopTime`, and that the `stepSize` is less than the `stopTime`.


### Plasma Scenario Validation
The plasma scenario configuration is validated with the following rules:

|**Key**|**Rule**|**Required**|
|---|---|---|
|`plasma_ramp_up_start`|Must be a positive integer.|:heavy_check_mark:|
|`plasma_flat_top_start`|Must be a positive integer.|:heavy_check_mark:|
|`plasma_flat_top_end`|Must be a positive integer.|:heavy_check_mark:|
|`plasma_ramp_down_end`|Must be a positive integer.|:heavy_check_mark:|

A check is also applied to ensure that the above are in the given order
of increasing magnitude.