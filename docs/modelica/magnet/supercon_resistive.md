# Magnets.Superconductor.SuperconResistive

Resistive model of a superconductor's I-V relationship, employing a macroscopic power law.

## Information

The model simulates the I-V relationship of a superconductor based on a macroscopic power law (instead of critical current density and electric field, critical current and voltage are used).
At about 1.2x Ic and higher this I-V macroscopic characteristic becomes dominant and the hysteresis may be neglected; otherwise the hysteresis is dominant and instead this I-V characteristic may be neglected.

Inputs are the critical current, power exponent and normal state resistance. The critical current criterion is set to 1e-4 V/m whch should not normally be changed. Change the length to achieve the desired voltage.

## Revisions

- by OpenModelica (class OnePort)
- 2020 by Alexander Petrov (credits due to J Rhyner who developed the Power Law model)
initially implemented