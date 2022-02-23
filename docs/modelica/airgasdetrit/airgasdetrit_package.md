# AirGasDetrit.mo

## Information
The input is the thermal power, and the output is the electrical power required.

## Description and Method

The Air gas detrit package includes the Recombination and post dryer sections.

There are 5 models included in the airgas detritiation package:

- Low and High Temperature Heating
	- Heating load (kW) = Flowrate (kg/s) * Average heat capacity (kJ/kg.°C ) * (Required second stage temperature (°C) - Ambient temperature (°C))
- Compression of feed gas
	- Compressor energy (kW) = compressor work (kJ/kg) * hydrogen flowrate (kg/s)
- Regen heating
	- Constant Heating of ceramic energy (kW) = Mass of ceramic in one vessel (kg) * mol sieve heat capacity (kJ/kg.°C) * (final air regen temperature - ambient air regen temperature) * turnaround time (hour) / 3600
- Compression of regen gas
	- Compressor energy (kW) = compressor work (kJ/kg) * air flowrate (kg/s)
- Total Contingency factor
	- Electrolysis Power + Water heating + compressor work

## Assumptions

- Thermal Power exiting the reactor - 1 GW
- Worst case assumptions
	- Regen heating - Upstream knock out pot operating temperature - 40°C 
	- Regen heating - Pressure of air from KOP - 3 bara
	- Comp regen gas - 'Mol sieve bed 1 turnaround operational time (from regen to saturation during operation) - 1 hr. This assumption is based off operational experience