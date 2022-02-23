# BlanketDetrit.mo

## Information
Applies to both `Power_NonCarrier` and `Power_CarrierBreeder`. The input is the thermal power, and the output is electrical power required.

## Description
Removal of tritium from helium (or any inert) can be performed either via recombination and water absorption or via getter material usage.  Getter technology was used in this instance as this is more appropriate for smaller gas flows and high concentrations. The power implication of a getter or a recomb + dryer technology is not expected to be very different. Getter technology considers the concept of selectively absorbing tritium onto a getter type sorbent. These can function in a wide window from 200-700°C according to ST 707 brochures and the DEMO CPS study. 

The getter material will need to be regenerated to remove the tritium from the sorbents. This will be done be adding heat to the getter material, effectively creating a Temperature Swing Ad/Absorbent. A very small purge may be used during regen in the event the tritium content is to be diluted due to permeation concerns, however this is slightly counter intuitive as a high concentration of tritium is prefered from a purification and tritium refining perspective. 

Separated into the following models with these major equations for the molten Salt/liquid Coolant:

- Tritium breeding rate
	- tritium Breeding Rate (mol/sec) = Trit reactor input per 1GW thermal (mol/s) * Thermal Power * burn rate (%) * Tritium breeding ratio
- He Stream calc
- Loss of heat
- He gas compression
	- Compressor energy (kW) = compressor work (kJ/kg) * coolant flowrate (kg/s)
- Electrical heating cost
	- Using the highest bed volume, either capacity limited or contact time limited
		- Capacity limited - Bed volume = T flowrate (g/s) * 3600 / 1000 * turnaround time (hours) / saturation capacity (%) / Density (kg/m<sup>3</sup>)
	- Contact time limited - Bed volume = Min contact time * gas flow (NM3/hour) / 3600 * T(Gas)(°K) / 273 * 1(bara) / pgas (bara))
	- Constant Heating of ceramic energy (kW) = Mass of getter in one vessel (kg) * getter heat capacity (kJ/kg.°C) * (final air regen temperature - initial regen temperature) / (Turnaround time (hr)) * 3600)
- Pure HeGas Compression
	- Compressor energy (kW) = compressor work (kJ/kg) * coolant flowrate (kg/s)
- Total contingency factor
	- Gas compression calc (added 20 bar) + regen heating + regen compression + hydrogen from water electrolysis