# CryogenicPlant.CryogenicPower

## Information
Model of the power loads of the cryogenic plant.

## Model Description and Method

This model calulates the electrical power load of a Tokamak Cryogenic Plant by summing the power required for the following cryogenic loads:

- Hydrogen Freezing
- Cryodistillation
- Magnet Radiative
- Magnet Dissipative
- Cryopumping

These cryogenic loads are modelled at a high level by taking their operating temperatures and calculating an individual carnot efficiency. This carnot efficiency is applied to the load's cooling power to find the ideal electrical power consumption. The practical power consumption is then found by applying an individual figure of merit to the ideal consumption. 

For the each of the cryogenic loads, the required cooling power is either assumed steady state, or in some cases, calculated using a more deatiled model. This is further explained below:

- Hydrogen Freezing - Assumed Steady-State 3.5g/s (copied from pellet Injection flow rate for JT60SA www.jt60sa.org/pdfs/cdr/10-3.5_Cryogenic_System.pdf)
- Cryodistillation - Modelled using net-flow-rates between columns and gas constants applied to Steady State Flow Equation
- Magnet Radiative - Modelled using 4th order polyfit to neutronic simulation data, with known parameters; PF heatload and neutronic shielding thickness 
- Magnet Dissipative - Assumed Steady State 3MW
- Cryopumping - Assumed Seady State 100kW

## Assumptions

General:

- Each model uses a different cold temperature this assumes the ability to provide He2 at different pressures and the cost of this flexibility is not explicitly considered
- The system efficiency is taken as a block FOM(Figure of Merit) efficiency, but where this number comes from is not considered
- The transportation, pumping, and storage losses are not considered
- The use of byproducts such as enriched Hydrogen or waste heat is not considered
- Some product areas have static cooling power values as phase 2 modelling has not been attempted
- Room temperature is assumed to be 298K across the models
 
Magnet Cooling:

- 2 coolants are assumed to be used at potentially different temperatures
- Radiative/Neutronic heat is assumed to be 100 percent dissipated in the outer coolant sink
- Dissipative/Resistive heat is assumed to be 100 percent dissipated in the inner coolant sink
- The equation for neutronic heat loads on the Central Solonoid coil is a 4th order polynomial fit to data from Tokamak (1GW-DI1) neutronics analysis over the range 10-60cm
- The static value for the PF coils is similarly taken from  Tokamak (1GW-DI1) neutronics analysis
- TF coil cooling for radiative heat is not considered
- Resistive heat values are to be taken from the Magnet System Power consumption models

Cryodistillation:

- ITER-like configuration considered [] hence the naming conventions for the various columns
- Ambient power used to reboil Liquid Hydrogen
- Heat Exchangers Loss-less
- Specific Heat of Gaseous Hydrogen, Specifc Heat of Liquid Hydrogen are assumed to be for Parahydrogen at 1 atm and 20.27 K
- Latent Heat of Evaporation is assumed to be for Parahydrogen at 1 atm and 20.27 K
- Temperature of Evaporation is assumed to be for Parahydrogen at 1 atm
- Pressure assumed constant for input cooling and super cooling of reflux
- Most default values are taken from ITER paper
- Values unknown for the mass flow rates of the Feedback stream from Column 3 to Column 1 and the output stream from Column 3,
- Decay heat of Tritium not considered
- Pressure drops in columns are not considered 
- Hence pumping requirements not considered 
- Comprehensive model diagram