# CoolantDetrit.WaterCoolant

## Description and Method

It is impractial for all of the water in the loop to be continuously detriated (from a power perspective) hence only a side stream shall be detritated. But what is the portion of the sidestream to be treated? 

Seperated into the following models with these major equations:

- Tritium breeding rate
	- tritium Breeding Rate (mol/s) = Trit reactor input per 1GW thermal (mol/s) * Thermal Power * burn rate (%) * Tritium breeding ratio
- Permeation calculation
	- Permeation Rate (mol/s) = Permeability * (Area (m<sup>2</sup>) / Length (m)) * (sqrt(Blanket side partial pressure (Pa) - sqrt(coolant side partial pressure (Pa))
- Water split stream calculation
	- Split steam (kg/s) = permeation rate (mol/s) / (Assumed trit removal efficiency (%) * max trit concentration permissible (mol/kg))
- Electrolysis Energy
	- Electrolysis Power (kW) = tritiated water feed * (5/2) (kg/s) * electrolysis power
- Water heating calculation
	- Heating Power (kW) = Flowrate (kg/s) * (reflux ratio * heat capacity (kJ / kg.°C) * (Target T (°C) - Ambient T (°C)) + latent heat of vapourisation * vapour fraction)
- Gas Compression
	- Compressor energy (kW) = compressor work (kJ/kg) * hydrogen flowrate (kg/s)
- Total contingency factor
	- Electrolysis Power + Water Heating + Compressor work

## Assumptions

- Water Split stream calculation - Assumed tritium removal effciency of 95%