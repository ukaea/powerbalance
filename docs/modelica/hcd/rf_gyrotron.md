#Tokamak.HCDSystemPkg.RF.Gyrotron

##Information
Model of an RF Gyrotron

##Model Description and Method
This model is based on the design of a 170GHz 1.5MW Grotron by Kalaria & Kartikeyan [1, 2]. 

The Gyrotron model is broken down into three sub-models, namely 

- Magntron Injection Gun (MIG) model
- Beam model
- RF coil model. 

The electrical power delivered to the Gyrotron is the product of its efficiency and the RF power delivered to the plasma via the Waveguide. The efficiency of the Gyrotron is estimated as the product of the efficiencies of the sub-models (that make up the Gyrotron) based on their design parameters or configuration. The default values used to calculate the efficiency of the sub-models were taken from the design described in [2].

References

[1] S. Stewart, "Modelling of Radio Frequency Heating and Current Drive Systems for Nuclear Fusion," 2020.

[2] P. C. Kalaria, M. V. Kartikeyan and M. Thumm, "Design of 170GHz, 1.5-MW Conventional Cavity Gyrotron for Plasma Heating," IEEE Transactions on Plasma Science, pp. 1522-1528, 2014. 
