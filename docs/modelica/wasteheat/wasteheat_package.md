# WasteHeat.mo

## Information
Package containing the waste heat Management system object (WasteHeatSystem) and model for the power load of waste heat management of Magnets, H&CD, Cryo and WaterDetrit (WasteHeatPower).

## Model Description and Method
The purpose of this model is to extract the waste heat from the air. It does this by taking in waste power from other models and performing a cooling with dehumidification calculation.

The settable user input values for this model are given, alongside their default values:

- Waste power from other models (1000 W)
- Height of room 
- Length of room 
- Width of room 
- Efficiency of Waste Heat system (0.8)
- simulation stop time (60 s)

## Assumptions

- Cooling with Dehumidification process
- Steady flow process
- mass flow rate of air constant
- Air behaves and an ideal gas
- Kinetic energy and Potential energy negligible
- Heat transfer through floor is negligible
- If the waste power is under 5000 W, the dehumidification calculation is disregarded. This is due to several reasons.
	- The temperature difference is calculated using the waste power, and at low powers this can be very small.
	- The mass flow rate of the moisture in the air is calculated as a fraction of the mass flow rate of the air, and at these low powers it would dominate the calculation and give a negative overall power.