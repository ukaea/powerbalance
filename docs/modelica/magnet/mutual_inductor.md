# Magnets.Superconductor.MutualInductor

Implementation of two basic inductors together with a mutual inductance between them.

## Information

The model of mutual inductance here is taken in the simplest form in terms of circuit theory:

$V1 = L_1\frac{di_1}{dt} + M\frac{di_2}{dt}$

$V2 = L_2\frac{di_2}{dt} + M\frac{di_1}{dt}$

The upper inductor is taken as '1' and the lower inductor is taken as '2'.

Customization is fairly easy to include more than 2 inductors depending on modeling needs.

## Revisions

- 2021 by Alexander Petrov (credit due to the creators of the TwoPort and Transformer classes), initially implemented