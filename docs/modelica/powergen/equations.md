# PowerGenEquations.mo

## Information
This model calculates the efficiency of power conversion (plasma heat - electrical power) in the system. It's inputs are the primary coolant, secondary coolant, compression ratio, operating pressure and thermal power, and it's output is the electrical power generated.

## Modelling Methodology 
The Power Generation modelling has been based on the excel power generation model created as part of internal UKAEA work.
 
30 different relevant scenarios were identified according to the following criteria:

- Different primary coolants 
- Different secondary coolants 
- Different compression ratios or operating pressures (depending on secondary coolant chosen). 
 
Each scenario was evaluated to develop an equation relating reactor operating temperature (ie primary fluid reactor outlet temperatures) to total loop efficiency. Total loop efficiency considers the power consumption from 1st, 2nd and 3rd loops (excluding tritium related equipment and any power consumption within the boundaries of reactor).  