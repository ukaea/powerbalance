# CoolantDetrit.GasCoolants

## Information

Similarly to the water detrit strategy - only some of the gas coolant will be detritiated (although other strategies may be possible). The detitiation of the full gas coolant stream is impractical due potentially high energy costs but is also mainly to due large absorbent beds which would be difficult to regenerate and recover tritium from. 
       
The largest power consumer is from the resulting pressure drop loss across the two detrit process steps - oxidation and water knock out. The additional pressure drop in turn will result in additonal compression power. Typical airgas detrit technology using oxidation and post dryers will be used. The associated heat typically used for oxidiser reactors can be ignored as the stream will already be hot, however the post dryer energy requirements will need to be considered for the split stream. 

Separated into the following models with these major equations for the Gases Coolant:
- Tritium breeding rate
	- tritium Breeding Rate (mol/s) = Trit reactor input per 1GW thermal (mol/s) * Thermal Power * burn rate (%) * Tritium breeding ratio
- Permeation calculation
	- Permeation Rate (mol/s) = Permeability * (Area (m<sup>2</sup>) / Length (m)) * (sqrt(Blanket side partial pressure (Pa) - sqrt(coolant side partial pressure (Pa))
- Water split stream calculation
	- Split steam (kg/s) = permeation rate (mol/s) / (Assumed trit removal efficiency (%) * max trit concentration permissible (mol/kg))
- Gas Compression
	- Compressor energy (kW) = compressor work (kJ/kg) * hydrogen flowrate (kg/s)
- Regen Heating
	- Using the highest bed volume, either capacity limited or contact time limited
		- Capacity limited - Bed volume = Water flowrate (g/s) * 3600 / 1000 * turnaround time (hours) / saturation capacity (%) / Density (kg/m<sup>3</sup>)
		- Contact time limited - Bed volume = Min contact time * gas flow (NM3/hour) / 3600 * T(Gas)(°K) / 273 * 1(bara) / pgas (bara))
	- Constant Heating of ceramic energy (kW) = Mass of ceramic in one vessel (kg) * mol sieve heat capacity (kJ/kg.°C) * (final air regen temperature - Ambient air regen temperature) / (Turnaround time (hr)) * 3600)
	- Water evolving energy (kW) = Water rate (kg/hour) * Water latent heat of vaporisation (kJ/kg) * 1 / 3600
	- Total regen heating rate = constant heating of ceramic + water evolving rate
- Compression of Regen gas
	- Using the highest bed volume, either capacity limited or contact time limited
		- Capacity limited 
		- Contact time limited - Bed volume = Min contact time * gas flow (NM3/hour) / 3600 * T(Gas)(°K) / 273 * 1(bara) / pgas (bara))
	- Constant Heating of ceramic energy (kW) = Mass of ceramic in one vessel (kg) * mol sieve heat capacity (kJ/kg.°C) * (final air regen temperature - Ambient air regen temperature) / (Turnaround time (hr)) * 3600)
	- Water evolving energy (kW) = Water rate (kg/hour) * Water latent heat of vaporisation (kJ/kg) * 1 / 3600
	- Total regen heating rate = constant heating of ceramic + water evolving rate
	- Compressor energy (kW) = compressor work (kJ/kg) * airflow rate (kg/s)
- Electrolysis Energy
	- Electrolysis Power (kW) =Amount of H2 required (mol/s) * Electrolysis power consumption (kJ/molH2)
- Total contingency factor
	- Gas compression calc (added 20 bar) + regen heating + regen compression + hydrogen from water electrolysis

## Assumptions

- Regen Heating - Upstream knock out pot operating temperature - 40 degrees C. Worst case assumption
- Regen Heating -  Pressure of coolant from KOP - 90 bara. Worst case assumption