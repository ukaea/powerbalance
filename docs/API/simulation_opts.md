# Simulation Options

Simulation options are those found within Modelica itself and determine the time interval, solver choice etc. The options are written in a TOML file placed in the same directory as [parameter options](parameters.md). The name of this file should be specified within the [API configuration file](configuration.md) via the `simulation_options_file` key. This configuration is [validated](validation.md) before the session is run.

The default file `parameters/simulation_options.toml` contained within the PBM module has the contents:

```toml
startTime = 0
stopTime = 60
stepSize = 0.01
tolerance = 1e-012
solver = "dassl"
```

these options being defined as:

|**Option**|**Description**|
|---|---|
|`startTime`|Simulation data record start time in seconds|
|`stopTime`|Simulation data record stop time in seconds|
|`stepSize`|Frequency of data collection|
|`tolerance`|Tolerance of the solver|
|`solver`|Choice of [solver](#solver-types)|

!!! warning "Case sensitivity"
    These options are case sensitive, make sure to correctly specify the keys above.

#### Solver Types
Recognised solver types:

- `dassl`
- `ida`
- `cvode`
- `impeuler`
- `trapezoid`
- `imprungekutta`
- `euler`
- `heun`
- `rungekutta`
- `rungekuttaSsc`
- `irksco`
- `symSolver`
- `symSolverSsc`
- `qss`