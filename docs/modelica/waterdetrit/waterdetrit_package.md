# WaterDetritiation.mo

## Information
The input is the thermal power and the output is the electrical power required.

## Description and Method

There are three types of power load involved. The Thermal Power, the Electrical Power and the Negligeable Power Load. The development of this system is to control the tritium content in the diverging streams to minimize the power usage. This is completed by thermal power being pumped in to the Liquid Phase Catalytic Exchange or LPCE in this diagram. The electrical power loads include the electrical power for electrolysis and the potential electrical load on the compression of gases around the permeator. There are more models to predict the time this process takes but the overall goal will separate the clean water and the tritiated water into separate streams.

There are 4 models included in this water detritiation package:

- Electrolysis Energy
	- Electrolysis Power (kW) = Flowrate (kg/s) * Electrolysis power consumption (kJ / kgH20)
- Water Heating
	- Heating Power (kW) = Flowrate (kg/s) * (reflux ratio * heat capacity (kJ/kg.°C ) * (Target T (°C) - Ambient T (°C)) + latent heat of vaporisation * vapour fraction)
- Gas Compression
	- Compressor energy (kW) = compressor work (kJ/kg) * hydrogen flowrate (kg/s)
- Total Contingency
	- Electrolysis Power + Water heating + compressor work

## Assumptions

- Thermal Power exiting the reactor - 1GW
