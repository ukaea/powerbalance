# CryogenicPlant.TurboPumpCryogenics

## Information
A model to simulate a cryopump operation

## Cryo-pump calculations

Using the ITER cryopumps which can run the operation at a minimum pressure of 2.5x10-3 mbar (..\..\pumps\Maintenance\PBS31 - Vacuum Vessel and Neutral Beam Pumping Systems (May'20 Draft).docx)

## Assumptions

- ITER combines ScHe, He at 80 K and 120 K He to operate the pumping and the regeneration cycles
- The cryo pump(s) operate at 20 K to pump out the SPR vaccum vessel
- The cryo pump(s) are regernated at 120 K. No electrical power consumption for cooling down to 120 K has been added
- The flow rate is 99% of the injected D2 and T2, the other flows are neglected. D2 = 0.02049 mol/s and T2 = 0.02049.