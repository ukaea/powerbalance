# Interactive Session
For inspection of outputs, and dynamically setting up and running of simulations it is recommended that the API be launched within an `ipython` session. This allows the user to create an instance of `PowerBalance` and modify/inspect parameters on the fly.

## Installing iPython
`ipython` can be installed using `pip`:

```bash
pip install ipython
```

## Example

```ipython
In [1]: from power_balance.core import PowerBalance

In [2]:  p = PowerBalance()
Initialising session, please wait...

In [3]: p.run_simulation('output_dir')
stdout            | info    | ... loading "data" from "/home/user/PowerBalanceModels/power_balance/profiles/mat_profile_files/ThermalPowerOut.mat"
stdout            | info    | ... loading "data" from "/home/user/PowerBalanceModels/power_balance/profiles/mat_profile_files/currentCS.mat"
...

In [4]: p.get_parameters()
Out[4]: 
{'Tokamak.Interdependencies.air_gas_power.compFeedGas.compressorWork': 485.8823529411765,
 'Tokamak.Interdependencies.air_gas_power.compRegenGas.absorbentRequired': 381.9861818181818,
 'Tokamak.Interdependencies.air_gas_power.compRegenGas.compressorWork': 227.0588235294117,
 ...

In [5]: p.set_parameter_value('tokamak.interdependencies.magnetpower.magnetpf1.numcoils', 10)
Out[5]: 10

In [6]: p.modifiable_parameters()
Out[6]: 
['tokamak.interdependencies.primarycoolanttype',
 'tokamak.interdependencies.secondarycoolanttype',
 'tokamak.interdependencies.ratiotype',
 'tokamak.interdependencies.systempressure',
 ...
```

!!! warning "Parameter setting"
    All parameters including those that are protected are listed via `PowerBalance.get_parameters()` for
    the purposes of inspection. Only modifiable parameters can be updated, these are listed by running `PowerBalance.modifiable_parameters()`.







