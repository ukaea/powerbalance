# Parameter Values

## Model Parameters
Initial mutable Modelica model parameter values are specified in TOML files with a file existing for each model executed. These files are placed together in a parameter directory. The naming convention of these files should follow that of: the model name in lower case where `.` is replaced with `_`. For example for the model `Tokamak.Interdependencies` the relevant parameter file is named `tokamak_interdependencies.toml`. In TOML files hierarchy is specified via headers `[...]`. 

!!! info "Example"
    The parameter `Tokamak.Interdependencies.hcdsystem.NINI1.__beamEnergy` would be found in the file `tokamak_interdependencies.toml` and be modified as:

    ```toml
    [hcdsystem.NINI1]
    beamEnergy = 1
    ```

!!! warning "Editable values"
    Only parameters with the prefix `__` can be modified within PBM as such this prefix is omitted from the parameter TOML file specification. If a non-modifiable parameter is specified in a parameter configuration file it will be ignored.

In the case of the default parameters the internal file `parameters/tokamak_interdependencies.toml` contains:

```toml
PrimaryCoolantType = "CO2_NC"  # Can be CO2_C, CO2_NC, He_C, He_NC, H2O, FLiBe, LiPb
SecondaryCoolantType = "H2O"   # Can be CO2, H2O
RatioType = "1.5"              # Can be 1.5, 2, 2.5
SystemPressure = "90"          # Can be 50, 90, 200
VacuumType = true              # True or false
ThermalPower = 1000            # Default value 1 GW
# ========================== HCD SYSTEM ================================ #
[hcdsystem]
RFEfficiency = 0.4
HeatToAir = 0.20

[hcdsystem.negativeIonNeutralInjector]
beamEnergy = 1
efficiencyNeutralization = 0.58
NBIThermalPowerMaxMW = 109

# ======================= CRYOGENIC POWER ============================== #
[cryogenicpower]
HeatToAir = 0.20
cryoFlow_HydrogenFreezing = 3.5
cryoTemp_TF = 20
cryoTemp_PF = 4
PFcrMW = 0.0007

[cryogenicpower.CD]
FBCol_2 = 0.0003902222222222223
FBCol_3 = 0.0001944444444444444
InputFlowRateCol_1 = 0.0002737777777777778
InputFlowRateCol_2 = 0.0002755555555555556
OutputStreamRateCol_1 = 8.638888888888889e-05
OutputStreamRateCol_2 = 0.0001803333333333333
OutputStreamRateCol_3 = 5.555555555555556e-05
OutputStreamRateCol_4 = 0.0001411944444444444

# ====================== WASTE HEAT POWER ============================== #
[wasteheatpower.wasteHeatCryo]
Height = 3.0
Length = 120.0
SystemEfficiency = 0.8
Width = 45.0

[wasteheatpower.wasteHeatHCD]
Height = 70.0
Length = 120.0
SystemEfficiency = 0.8
Width = 100.0

[wasteheatpower.WasteHeatMagnets]
Height = 3.0
Length = 150.0
SystemEfficiency = 0.8
Width = 30.0

# ========================== MAGNET POWER ============================== #
[magnetpower.magnetPF1]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetPF2]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetPF3]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetPF4]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetPF5]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetPF6]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02

[magnetpower.magnetTF]
numCoils = 12
Vdrop = 1.45
Rfeeder = 1.9e-7
nTurn = 5.0
maxCurrent = 60e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
magEnergy = 2.139e9
Rtot = 4.253e-7
Roleg = 1.948e-8

# ========================== POWER GENERATION ============================== #
[powergenerated]
powergenOutletTemp = 500
```

!!! tip "Examining TOML Files"
    TOML files can be loaded into Python as a dictionary using the `toml` module:
    ```python
    import toml
    import os

    # If parameters located at ./parameters/parameters.toml
    params_path = os.path.join(os.getcwd(), 'parameters', 'parameters.toml')

    # Load the TOML file into a dictionary
    params_dict = toml.load(open(params_path))

    # Retrieve parameter 'model.component.var' from dictionary
    print(params_dict['model']['component']['var'])
    ```

## Model Expansion
The "Magnets" component of Power Balance can be expanded to include additional PF magnets within the model. By default the model is run with the defined 6 PF magnet configuration, in order to define additional magnets extra statements can be added to the parameters file, e.g. including:

```toml
[magnetpower.magnetPF7]
numCoils = 1
Vdrop = 1.45
Rfeeder = 3.7e-9
nTurn = 200.0
maxCurrent = 50e3
coilLength = 40
Feeder_Qk = 0.198
Feeder_m = 0.069
L = 0.02
combiTimeTable = 2
```
will create one additional magnet. The optional parameter `combiTimeTable` is not a Modelica parameter in this case, but rather an additional variable used to select which existing `combiTimeTable` instance to use for creating the magnet instance. In this case we are using PF2 as the template.

Note also you can provide as many or as little parameters as you like to add a new magnet definition, the minimum being one (we recommend setting at least `combiTimeTable` in this case). As the number of magnets is deduced from the maximum PF stated within the parameters file to have for example 20 magnets, you need only explicitly define the 20th (i.e. `magnetpower.magnetPF20`).


## Structural Parameters
Structural parameters for the Modelica models are not mutable and can only be changed by altering the code itself. As such changes to these are handled independent of the main model parameters.

In order to make alterations you need to provide the `structural_params_file` key within your configuration file. By default the file `power_balance/parameters/structural_parameters.toml` is read. If no key is provided then the substitutions are not made and the original unmodified model code is used.

The default substitution file contains the following:
```toml
# ========================== MAGNETS =================================== #
[Magnets]
isMagnetTFSuperconCoil = false
isMagnetTFSuperconFeeder = false

isMagnetPF1SuperconCoil = false
isMagnetPF1SuperconFeeder = false

isMagnetPF2SuperconCoil = false
isMagnetPF2SuperconFeeder = false

isMagnetPF3SuperconCoil = false
isMagnetPF3SuperconFeeder = false

isMagnetPF4SuperconCoil = false
isMagnetPF4SuperconFeeder = false

isMagnetPF5SuperconCoil = false
isMagnetPF5SuperconFeeder = false

isMagnetPF6SuperconCoil = false
isMagnetPF6SuperconFeeder = false

[CryogenicPlant]
FOM4K = 30 # Figure of merit for the cryoplant at 4 K
FOM20K = 30 # Figure of merit for the cryoplant at 20 K
FOM80K = 30 # Figure of merit for the cryoplant at 80 K

# ========================== Tokamak ====================================== #
[Tokamak]
PrimaryCoolantType = "CO2_NC" # Can be CO2_C, CO2_NC, He_C, He_NC, H2O, FLiBe, LiPb
SecondaryCoolantType = "H2O" # Can be CO2, H2O
RatioType = "1.5" # Can be 1.5, 2, 2.5
SystemPressure = "90" # Can be 50, 90, 200

# ========================== PowerGenCaseByCase========================== #
[PowerGenEquations]
powergenOutletTemp = 500 # temperature related to the exchange of heat between the tokamak and the power generation system (Celsius)
```

!!! warning "Structural Parameter Substitution"
    Such substitutions can cause code compilation failures if not performed correctly, therefore caution should be taken when using configurations different to the defaults.
