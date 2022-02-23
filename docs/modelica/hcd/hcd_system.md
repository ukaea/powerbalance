# HCDSystemPkg.HCDSystem

## Information
Model of the power consumption of a Heading and Current Drive System, taking in the thermal power supplied to the plasma and calculating the electrical power required using wall plug efficiencies.

## Model Description and Method
This model calculates the total electrical power consumption over time, for a Tokamak external Heating and Current Drive system consisting of RF and NBI systems.

## Inputs

- RF thermal power supplied to the plasma, profile over time
- NBI thermal power supplied to the plasma, profile over time
- Wall-Plug efficiency (electrical - thermal) of RF, defualt 0.4
- NBI and RF consumptions are then summed to find the total electrical consumption of the external Heating and Current Drive system.

## Assumptions

- Tokamak will use similar technology to ITERs neutral beam system:
	- Approximately 50 MW beam output power requirement. [1]
	- Negative ion injection.
	- Uses a powered ion dump.
	- 20-30% W.P Efficiency. [1]
- Tokamak will use similar technology to ITERs RF systems:
	- Approximately 40 MW RF output power (20 MW ICRH + 20 MW ECRH) requirement. [2]
	- 1 MW Gyrotrons.
	- 30-40% W.P Efficiency. [3]
- Assumes only one type of RF technology used, as only one RF efficiency parameter.
- Assuming a pulse length of 60 seconds, no continuous run.
- Assuming thermal power contained within the plasma has ramp up and steady state period.
- Assuming that Heating and Current Drive Systems (RF and NBI) are responsible for all thermal power contained within the plasma
- Assuming that RF system has a fixed Wall-Plug efficiency which describes the entire conversion from electrical power taken from the grid to thermal power in the plasma.
- For NBI, assuming Negative Ion type as efficiencies are very poor for positive ion at beam energy above 150 keV

[1] "Technology developments for a beam source of an NNBI system for DEMO," Fusion Engineering and Design, Vols. 136, Part A, no. November, pp. 340-344, 2018.

[2] P. Brans, "Ion cyclotron heating: How to pump 20 MW of power into 1 gram of plasma," 13 Jan 2020. [Online]. Available: https://www.iter.org/newsline/-/3382. [Accessed July 2020].

[3] E. W. Sarah Parry Wright, "Tokamak Additional Heating Power Supplies Literature Review," 2020.