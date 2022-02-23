# TurboMolecularPump.mo

## Summary

Turbopumps will be used directly to achieve the low pressures required in the torus vacuum vessel. Many turbopumps in parallel are required to achieve the low pressure at the required flow rates. The turbopumps are backed by multiple booster stages and roughing (screw) pumps. The main power considerations are the electrical load required to run the various pumping stages in series.

The model takes the thermal power as an input, and outputs the electrical power required to run the pumps.

## Main Equations

- Required flowrate (m<sup>3</sup> / sec) = molar flow per GW (mol / s.GW) * thermal power (GW) * 8.314 (m^3.Pa / K.mol) * T (°K) / (Pressure (mbar) * 100 (Pa / mbar))

- Turbo power (kW) = SinglePump power (W) * 0.001 * Required flowrate / single pump flowrate