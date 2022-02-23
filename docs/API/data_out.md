# Analysing Outputs

## Output File Structure
After running Power Balance Models (PBM) a new directory should be created either in the current working directory, or the manually specified location. This directory will have a name in the format `pbm_results_<time-stamp>` and contain a set of subdirectories with files pertaining to the run itself (presence of the `html` and directory may depend on whether the plot browser is set to open after the run):

```
pbm_results_2021_06_18_12_59_22/
├── configs
│   └── configuration.toml
├── data
│   └── session_data.h5
├── parameters
│   ├── simulation_options.toml
│   └── tokamak_interdependencies.toml
├── plots
│   ├── Tokamak_Interdependencies_air_gas_power.jpg
│   ├── Tokamak_Interdependencies_blanketdetritpower.jpg
│   ├── Tokamak_Interdependencies_coolantdetritpower.jpg
│   ├── Tokamak_Interdependencies_cryogenicpower.jpg
│   ├── Tokamak_Interdependencies_hcdsystem.jpg
│   ├── Tokamak_Interdependencies_magnetpower.jpg
│   ├── Tokamak_Interdependencies_netpowerconsumption.jpg
│   ├── Tokamak_Interdependencies_netpowergeneration.jpg
│   ├── Tokamak_Interdependencies_powergenerated.jpg
│   ├── Tokamak_Interdependencies_total_turbopump_power.jpg
│   ├── Tokamak_Interdependencies_wasteheatpower.jpg
│   └── Tokamak_Interdependencies_water_detrit_power.jpg
└── profiles
    ├── NBI_Heat.mat
    ├── RF_Heat.mat
    ├── ThermalPowerOut.mat
    ├── currentCS.mat
    ├── currentPF1.mat
    ├── currentPF2.mat
    ├── currentPF3.mat
    ├── currentPF4.mat
    ├── currentPF5.mat
    ├── currentPF6.mat
    └── currentTF.mat
```

| **Directory** | **Description**                                                                           |
| ------------- | ----------------------------------------------------------------------------------------- |
| `configs`     | Contains a saved copy of the API session configuration file used during the run.          |
| `data`        | Contains a single file containing all data frames from all models run during the session. |
| `html`        | Contains the generated HTML file for viewing power data plots within the browser.         |
| `parameters`  | Contains all parameter start value configuration files and the simulation options file.   |
| `plots`       | Contains JPG versions of the plots generated during a run.                                |
| `profiles`    | Contains copies of the `.mat` profiles used as inputs for the model run.                  |