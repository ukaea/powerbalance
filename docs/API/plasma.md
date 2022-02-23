# Plasma Scenario

The Power Balance Model may take in a plasma scenario. This scenario is used for the generation of input profiles, such as the plasma heating and magnet currents. The values of each stage must be in ascending order and smaller than the end of the simulation at `stopTime`.

|**Name**|**Description**|**Default value (s)**|
|---|---|---|
|`plasma_ramp_up_start`|The end of the premagnetization stage, and when the plasma current begins to be ramped up|10|
|`plasma_flat_top_start`|The plasma current is at its highest, and flat-top operation begins|20|
|`plasma_flat_top_end`|Flat-top ends, and the plasma current starts to be ramped down|40|
|`plasma_ramp_up_end`|The plasma current is now 0 A, end of plasma. Demagnetizaiton begins|50|

