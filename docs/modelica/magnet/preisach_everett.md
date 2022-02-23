# Magnets.Superconductor.Hysteresis.PreisachEverett

Superconductor I-Phi(V) hysteresis based on the Preisach model and Everett function data

## Information

An I-V model of superconducting hysteresis using the Preisach hysteresis model with an Everett function.

The details surrounding the Presiach model implementation in Modelica (for ferromagnetism) can be found in the OpenModelica documentation for Preisach-Everett hysteresis. The majority of this code is an adapted version of GenericHystPreisachEverett that makes it possible to work in an electric circuit using current as an input and magnetic flux as output. The derivative of the magnetic flux is the voltage.

The Everett function is specified as a set of parameters through the HTS_EverettParameter data record. Different parameters may be set by either modifying the record file or setting a different file path for the 'mat' parameter on input.

NOTE: Take care with solver tolerance and time steps when attempting to model very small fluxes - a tolerance of 1e-10 or 1e-12 offers better results.

More information about Preisach and its use for superconductor hysteresis modelling can be found here:

M. Sjostrom, B. Dutoit, and J. Duron, 'Equivalent circuit model for superconductors', IEEE Transactions on Applied Superconductivity, vol. 13, no. 2, pp. 1890–1893, Jun. 2003, doi: 10.1109/TASC.2003.812941.
M. Sjostrom, 'Hysteresis modelling of high temperature superconductors', Infoscience, 2001. http://infoscience.epfl.ch/record/32848 (accessed Jan. 29, 2021).

## Revisions

- by OpenModelica (the authors of GenericHystPreisachEverett, and all the classes this model extends as well as the authors of OnePort, and Ferenc Preisach, without all of whom this superconducting variant of the Presiach-Everett model would not have been possible)
- Jan 2021 by Alexander Petrov. Modified the model for use in an electrical system.