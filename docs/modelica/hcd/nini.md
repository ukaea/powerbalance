# Tokamak.HCDSystemPkg.NINI

## Information
Model of Negative Ion Neutral Injector.

This model was modified from Damian King and Elizabeth Surrey's code, used for NBI studies[1]. The original (ENBI.pro) and modified (ENBI_mcannon.pro) versions, along with input parameters and associated excel spreadsheet can be found here:
(15) [Power Balance Models (B1.6 Power Infrastructure) | Microsoft Teams](https://teams.microsoft.com/_#/files/Power%20Balance%20Models?groupId=6b1c9009-c40d-4806-82fe-803b66367929&amp;threadId=19:d3e02e9165874565876e652a66696808@thread.tacv2&amp;ctx=channel&amp;context=NBI%2520model%2520code%2520for%2520reference&amp;rootfolder=%252Fsites%252FTokamak_PowerInfrastructure_B1_6%252FShared%2520Documents%252FPower%2520Balance%2520Models%252FNBI%2520model%2520code%2520for%2520reference)

The model now calculates electrical power usage as a function of heat to plasma. The code was taken from ENBI.pro (see appendix). This is a verified code written in IDL and is written to calculate the power coupled to plasma for a given set of input parameters and a given wallplug power. The code is modified here to output wall plug power usage for a given power coupled to plasma. The model first calculates the number of injectors and beamlines (numInjectors, numBeamlines) required to output the maximum thermal power. This calculation is done using the parameters below:

__NBIThermalPowerMaxMW, maxJ, maxDeuteriumCurrent_TotalPulse
The model then adjusts beam current in order to give an output power matching the profile it is given.

[1] "Improved Parameterisation of NBI Systems Code", D. King, E. Surrey, December 2012

Appendix 1: ENBI.pro (original IDL code)

```
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
;ENBI
;
; IDL version of NBI system code ENBI (Efficiency of Neutral Beam Injector)
;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;general inputs;;;;

PRO ENBI,n,input_vary

result=read_ascii('input.txt')
all=result.field1
s=size(all, /dimensions)
all2=fltarr(s(1))
all2(*)=all(1,*)

all2(n)=input_vary

coreDivergence= all2(0)
haloDivergence= all2(1)
beam_E= all2(2)
beamlineLength= all2(3)
gridArea= all2(4)
ext_area= all2(5)
electronRatio= all2(6)
J= all2(7)
numInj_PerLine= all2(8)
numBeamlines= all2(9)

;power supply inputs
extractionVolt= all2(10)
suppressionVolt= all2(11)
filterVolt= all2(12)
filterCurrent= all2(13)
stripFraction_Laser= all2(14)
stripVolt= all2(15)
stripCollected= all2(16)
powerRF= all2(17)
efficiencyDC= all2(18)
efficiencyRF= all2(19)

;laser neutraliser

laser= fix(all2(20))

efficiencyLaser= all2(21)
neut_chan_w= all2(22)
numChannels= all2(23)
efficiencyNeutralization= all2(24)

;energy recovery

negVolt =all2(25)
negFraction =all2(26)
posVolt =all2(27)
posFraction =all2(28)
efficiencyPosConverter =all2(31)

powerIncidentals= all2(32)
stripFraction_Laser= all2(33)

;;;;;;;;;;;;;;;;;;;;;calculations;;;;;;;;;;;;;;;;;;;;;;;;;;;

DeuteriumCurrent_PerLine=ext_area*J
electronCurrent_PerLine=DeuteriumCurrent_PerLine*electronRatio

IF (laser EQ 0) THEN stripFraction=stripFraction_Laser*ext_area/0.197 ELSE stripFraction=stripFraction_Laser*ext_area/0.197
IF (laser EQ 0) THEN neg_RI_frac=0.21 ELSE neg_RI_frac=1-efficiencyNeutralization
IF (laser EQ 0) THEN pos_RI_frac=0.21 ELSE pos_RI_frac=all2(30)
IF (laser EQ 0) THEN efficiencyNeutralization=0.58 ELSE efficiencyNeutralization=all2(24)
IF (laser EQ 0) THEN powerIncidentals=6 ELSE powerIncidentals=all2(32)

currentHVPSU=DeuteriumCurrent_PerLine*(1-stripCollected*stripFraction-negFraction*neg_RI_frac*(1-stripFraction))
powerHVPSU=currentHVPSU*beam_E
suppressionCurrent=J*(gridArea-ext_area)
extractionPower=extractionVolt*electronCurrent_PerLine/(1000.0*efficiencyDC)
suppressionPower_PerLine=suppressionCurrent*suppressionVolt/(1000000.0*efficiencyDC)
filterPower_PerLine=filterVolt*filterCurrent/(1000000.0*efficiencyDC)
stripPower_PerLine=stripFraction*stripCollected*stripVolt*DeuteriumCurrent_PerLine/1000.0
tot_HVP=(powerHVPSU+extractionPower+suppressionPower_PerLine+filterPower_PerLine+stripPower_PerLine)/efficiencyDC
RFInputPower_PerLine=powerRF/(1000.0*efficiencyRF)
tot_inj_P=tot_HVP+RFInputPower_PerLine

neg_rec_P=neg_RI_frac*DeuteriumCurrent_PerLine*(1-stripFraction)*negFraction*negVolt/(1000.0*efficiencyDC)
pos_rec_P=pos_ri_frac*DeuteriumCurrent_PerLine*(1-stripFraction)*posFraction*posVolt*efficiencyPosConverter

IF (laser EQ 0) THEN BEGIN
laser_P=0
ENDIF ELSE BEGIN
laser_P=-55.39*9788*((beam_E*1000000.0)^0.5)*alog(1-efficiencyNeutralization)*neut_chan_w*numChannels/(500.0*efficiencyLaser*1000000)
ENDELSE


tot_in_P=tot_inj_P+laser_p+neg_rec_p+powerIncidentals-pos_rec_p

transmit_p=DeuteriumCurrent_PerLine*beam_E*(1-stripFraction)
di_loss_NH=(0.0122*coreDivergence^2.0)-0.0708*coreDivergence+0.1029
di_loss_H=(0.0102*coreDivergence^2.0)-0.0496*coreDivergence+0.0711

haloDivergence=fix(haloDivergence)
IF (haloDivergence EQ 0) THEN di_loss=di_loss_nh ELSE di_loss=di_loss_h
;IF (coreDivergence LT 3.1) THEN di_loss=0 ELSE di_loss=di_loss

lossReionisation_Laser=0.01*(ext_area/0.2)*(beamlineLength/23.0)*(2.0/3.0)*numInj_PerLine
lossReionisation_NoLaser=0.05*(ext_area/0.2)*(beamlineLength/23.0)*(2.0/3.0)*numInj_PerLine
IF (laser EQ 0) THEN lossReionisation=lossReionisation_NoLaser ELSE lossReionisation=lossReionisation_Laser

lossTransmission=lossReionisation+di_loss

p_to_p=DeuteriumCurrent_PerLine*beam_E*(1-stripFraction)*(1-lossTransmission)*efficiencyNeutralization*numInj_PerLine

print,'Power out = ', p_to_p
print,'Power in = ', tot_in_p

wallplug=p_to_p/tot_in_p

print,'wallplug = ', wallplug

SAVE,filename='temp.sav'
END
```