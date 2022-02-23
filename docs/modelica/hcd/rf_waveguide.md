#Tokamak.HCDSystemPkg.RF.WaveGuide

##Information
Model of Waveguide Network 

##Model Description and Method
The Waveguide network transmits RF power from the Gyrotron to the plasma. Due to the tight space in tokamaks, RF power is usually transmitted over a long distance up to 100 meters at low losses. However, there are sources of power loss in the Waveguide which are:

- Coupling losses in and out of waveguide (both = 1.9%)
- Reflections at chemical vapour deposition windows (CVD loss) (0.3%)
- Launcher losses (1.0%)
- Mitre bend losses (calculated as 3.46%)
- Attenuation introduced by the mode converters (calculated as 1.39e-6%)

The values were the default values for a 7 mitre bend, 100m length, 45mm diameter at 110GHz waveguide (WG45) [1, 2]. The efficiency of the Waveguide network is obtained from the difference of all the losses from that of an ideal waveguide network. 

The RF power into the Waveguide network is calculated by multiplying the efficiency and the RF heating power delivered to the plasma by the Waveguide. 

References

[1] S. Stewart, "Modelling of Radio Frequency Heating and Current Drive Systems for Nuclear Fusion," 2020.

[2] S. Alberti, T. P. Goodman and et al., "An ITER relevant evacuated waveguide transmission system for the JET-EP ECRH project," Nuclear Fusion, vol. 43, pp. 1-14, 2003. 

