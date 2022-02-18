package BlanketDetrit "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model Power_CarrierBreeder
    //
    // Imported Variables
    import SI = Modelica.SIunits;
    parameter Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    //
    // Instantiating models
    TritiumBreedingRate tritiumBreedingRate(ThermalPower = ThermalPower);
    HeStreamCalc heStreamCalc(ThermalPower = ThermalPower);
    HeGasCompression heGasCompression(HeMassFlow = heStreamCalc.HeMassFlow);
    ExchangerHeatLoss exchangerHeatLoss(HeMassFlow = heStreamCalc.HeMassFlow);
    GetterBedRegenHeating getterBedRegenHeating(tritiumMassFlow = tritiumBreedingRate.tritiumMassFlow);
    GetterRegenGasCompression getterRegenGasCompression(tritiumMassFlow = tritiumBreedingRate.tritiumMassFlow);
    //
    // Parameters and variables
    Real sumPower(unit = "W") "Summation of all blanket power models, without contingency (W)";
    parameter Real contingencyFactor = 0.5 "Contingency factor";
    Real totalContingency(unit = "W") "Total power of blanket detrit systems, including contingency (W)";
    //
    //
  equation
    sumPower = (heGasCompression.compressorPower + getterBedRegenHeating.getterHeatPower + exchangerHeatLoss.heatLost + getterRegenGasCompression.compressorPower) * 1E3 "Sums up power usage of all blanket detrit systems (W)";
    totalContingency = (1 + contingencyFactor) * sumPower "Total power draw of blanket detrit systems (W)";
    //
    // Runtime Assertions
    assert(sumPower >= 0,"---> Assertion Error in [Power_CarrierBreeder], variable [sumPower = "+String(sumPower)+"] cannot be negative!",level = AssertionLevel.error);
    assert(sumPower <= 1e8,"---> Assertion Warning in [Power_CarrierBreeder], variable [sumPower = "+String(sumPower)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(totalContingency >= sumPower,"---> Assertion Error in [Power_CarrierBreeder], variable [totalContingency = "+String(totalContingency)+"] outside of reasonable range!",level = AssertionLevel.error);
    assert(totalContingency <= 1e8,"---> Assertion Warning in [Power_CarrierBreeder], variable [totalContingency = "+String(totalContingency)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end Power_CarrierBreeder;

  model Power_NonCarrier
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    String PrimaryCoolantType;
    //
    // Instantiating models
    TritiumBreedingRate tritiumBreedingRate(ThermalPower = ThermalPower);
    HeStreamCalc heStreamCalc(ThermalPower = ThermalPower);
    HeGasCompression heGasCompression(HeMassFlow = heStreamCalc.HeMassFlow);
    ExchangerHeatLoss exchangerHeatLoss(HeMassFlow = heStreamCalc.HeMassFlow);
    GetterBedRegenHeating getterBedRegenHeating(tritiumMassFlow = tritiumBreedingRate.tritiumMassFlow);
    GetterRegenGasCompression getterRegenGasCompression(tritiumMassFlow = tritiumBreedingRate.tritiumMassFlow);
    //
    // Parameters and variables
    SI.Power sumPower "Summation of all blanket power models, without contingency (W)";
    parameter Real contingencyFactor = 0.5 "Contingency factor";
    SI.Power totalPower_NonCarrier "Total Blanket Detrit Non Carrier Power (W)";
    SI.Power ElecPowerConsumed;
    //
  initial equation
    assert(PrimaryCoolantType == "CO2_NC" or PrimaryCoolantType == "He_NC", "---> BlanketDetrit cannot produce output because the provided PrimaryCoolantType cannot be used", level = AssertionLevel.warning);
    //
  equation
    sumPower = (heGasCompression.compressorPower + getterBedRegenHeating.getterHeatPower + exchangerHeatLoss.heatLost + getterRegenGasCompression.compressorPower) * 1E3 "Sums up power usage of all blanket detrit systems (W)";
    totalPower_NonCarrier = (1 + contingencyFactor) * sumPower;
    //
    ElecPowerConsumed = if PrimaryCoolantType == "CO2_NC" or PrimaryCoolantType == "He_NC" then totalPower_NonCarrier else 0;
    //
    //Runtime Assertions
    assert(sumPower >= 0, "---> Assertion Error in [Power_NonCarrier], variable [sumPower = "+String(sumPower)+"] cannot be negative!", level = AssertionLevel.error);
    assert(sumPower <= 1e8,"---> Assertion Warning in [Power_NonCarrier], variable [sumPower = "+String(sumPower)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(contingencyFactor >= 0 and contingencyFactor <= 1, "---> Assertion Error in [Power_NonCarrier], variable [contingencyFactor = "+String(contingencyFactor)+"] outside of acceptable range!", level = AssertionLevel.error);
    assert(contingencyFactor >= 1 and contingencyFactor <=1 ,"---> Assertion Warning in [Power_NonCarrier], variable [contingencyFactor = "+String(contingencyFactor)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(totalPower_NonCarrier >= sumPower, "---> Assertion Error in [Power_NonCarrier], variable [totalPower_NonCarrier = "+String(totalPower_NonCarrier)+"] outside of acceptable range!", level = AssertionLevel.error);
    assert(totalPower_NonCarrier <= 1e8,"---> Assertion Warning in [Power_NonCarrier], variable [totalPower_NonCarrier = "+String(totalPower_NonCarrier)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(ElecPowerConsumed >= 0, "---> Assertion Error in [Power_NonCarrier], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] cannot be negative!", level = AssertionLevel.error);
    assert(ElecPowerConsumed <= 1e8, "---> Assertion Warning in [Power_NonCarrier], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end Power_NonCarrier;

  model TritiumBreedingRate
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    //
     // Specified Paramters
    parameter Real tritiumInput(unit = "mol/(s.GWt)") = 1 "Tritium input to reactor per GW(t) (mol/(sec GW(thermal))";
    parameter Real burnRate(unit = "percent") = 1 "Burn rate (%)";
    parameter Real tritiumBreedRatio(unit = "1") = 1 "Tritium breeding ratio";
    //
    // Variables
    SI.MolarFlowRate tritiumInput_Reactor "Tritium input to reactor (mol/sec)";
    SI.MolarFlowRate tritiumBreedRate "Tritium breeding rate (mol/sec)";
    Real tritiumMassFlow(unit = "g/s") "Tritium mass flow rate (g/s)";
    //
  equation
    tritiumInput_Reactor = tritiumInput * ThermalPower / 1e3 "Tritium input to reactor (mol/sec)";
    tritiumBreedRate = tritiumInput_Reactor * burnRate * tritiumBreedRatio / 100 "Tritium breeding rate (mol/sec)";
    tritiumMassFlow = tritiumBreedRate * 6 "Assuming all tritium exists as T2 (g/s)";
    //
     //Runtime Assertions
    assert(tritiumInput_Reactor >= 0, "---> Assertion Error in [TritiumBreedingRate], variable [tritiumInput_Reactor = "+String(tritiumInput_Reactor)+"] cannot be negative!", level = AssertionLevel.error);
    assert(tritiumInput_Reactor <= 1, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumInput_Reactor = "+String(tritiumInput_Reactor)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(tritiumBreedRate >= 0, "---> Assertion Error in [TritiumBreedingRate], variable [tritiumBreedRate = "+String(tritiumBreedRate)+"] cannot be negative!", level = AssertionLevel.error);
    assert(tritiumBreedRate <= 1, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumBreedRate = "+String(tritiumBreedRate)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(tritiumMassFlow >= 0, "---> Assertion Error in [TritiumBreedingRate], variable [tritiumMassFlow = "+String(tritiumMassFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(tritiumMassFlow <= tritiumBreedRate * 6, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumMassFlow = "+String(tritiumMassFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(tritiumMassFlow <= 1, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumMassFlow = "+String(tritiumMassFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end TritiumBreedingRate;

  model HeStreamCalc
    //
    // Mathematical constants
    final constant Real e = Modelica.Math.exp(1.0);
    final constant Real pi = 2 * Modelica.Math.asin(1.0);
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real ThermalPower(unit = "MW") "Total high grade thermal power, MW";
    //
    // Specified Parameters
    parameter Real blanketVolumeChangeTime(unit = "1/h") = 5 "Blanket volume changeovers per hour";
    parameter Real voidage(unit = "1") = 0.5 "Void fraction, based on typical ceramic voidage";
    SI.Volume rxVolScaleFactor = 1000 "Based off 1 GW spherical reactor with a radius of 6 m (m3)";
    SI.Length blanketThickness = 1 "Thickness of the blanket (m)";
    //
    // Variables
    SI.Volume plasmaVol "Volume of the reactor (plasma volume) (m3)";
    SI.Length rxInnerRadius "Inner sector radius (m)";
    SI.Length rxOuterRadius "Radius of the outer reactor (including blanket) (m)";
    SI.Volume blanketVolume "Volume of the blanket (m3)";
    Real HeVolFlow(unit = "Nm3/h") "He volumetric flow rate (Nm3/hr) !!Should this be Normal or Actual??!!";
    Real HeMassFlow(unit = "kg/s") "He mass flow rate (kg/s)";
    //
  equation
    plasmaVol = rxVolScaleFactor * ThermalPower / 1e3 "Scale reactor volume from 1 GW basis (m3)";
    rxInnerRadius = (plasmaVol * 3 / (4 * pi)) ^ (1 / 3) "Determines atual reactor inner diameter based on scaled volume (m)";
    rxOuterRadius = rxInnerRadius + blanketThickness "Determines reactor radius including blanket (m)";
    blanketVolume = pi * 4 / 3 * rxOuterRadius ^ 3 - plasmaVol "Determines blanket volume (m3)";
    HeVolFlow = blanketVolume * voidage * blanketVolumeChangeTime "Volumetric flow of He required (Nm3/hr) !!Normal or Actual!!";
    HeMassFlow = HeVolFlow * 4E-3 * 101325 / (8.3145 * 298 * 3600) "Convert volume to mass flow assuming ideal gas (kg/s) !!Normal or Actual!!";
    //
    //Runtime Assertions
    assert(plasmaVol >= 0, "---> Assertion Error in [HeStreamCalc], variable [plasmaVol = "+String(plasmaVol)+"] cannot be negative!", level = AssertionLevel.error);
    assert(plasmaVol <= 5e3, "---> Assertion Warning in [HeStreamCalc], variable [plasmaVol = "+String(plasmaVol)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(rxInnerRadius >= 0, "---> Assertion Error in [HeStreamCalc], variable [rxInnerRadius = "+String(rxInnerRadius)+"] cannot be negative!", level = AssertionLevel.error);
    assert(rxInnerRadius <= 10, "---> Assertion Warning in [HeStreamCalc], variable [rxInnerRadius = "+String(rxInnerRadius)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(rxOuterRadius >= rxInnerRadius, "---> Assertion Error in [HeStreamCalc], variable [rxOuterRadius = "+String(rxOuterRadius)+"] outside of acceptable range!", level = AssertionLevel.error);
    assert(rxOuterRadius >= rxInnerRadius + 5, "---> Assertion Warning in [HeStreamCalc], variable [rxOuterRadius = "+String(rxOuterRadius)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(blanketVolume >= 0, "---> Assertion Error in [HeStreamCalc], variable [blanketVolume = "+String(blanketVolume)+"] cannot be negative!", level = AssertionLevel.error);
    assert(blanketVolume <= 4e3, "---> Assertion Warning in [HeStreamCalc], variable [blanketVolume = "+String(blanketVolume)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(HeVolFlow >= 0, "---> Assertion Error in [HeStreamCalc], variable [HeVolFlow = "+String(HeVolFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(HeVolFlow <= 1e4, "---> Assertion Warning in [HeStreamCalc], variable [HeVolFlow = "+String(HeVolFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(HeMassFlow >= 0, "---> Assertion Error in [HeStreamCalc], variable [HeMassFlow = "+String(HeMassFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(HeMassFlow <= 30, "---> Assertion Warning in [HeStreamCalc], variable [HeMassFlow = "+String(HeMassFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);

  end HeStreamCalc;

  model HeGasCompression
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real HeMassFlow(unit = "kg/s") "Helium mass flowrate (kg/s)";
    //
    // Specified Parameters
    parameter Real compPressureIn(unit = "Pa") = 5E5 "Pressure at compressor inlet (Pa)";
    parameter Real blanketPessure(unit = "Pa") = 10E5 "Pressure at compressor outlet (Pa)";
    parameter Real compTempIn(unit = "K") = 573 "Temperature at compressor inlet (K)";
    parameter Real blanketCoolantRatioCpCv(unit = "1") = 1.67 "Ratio of coolant Cp/Cv at compressor inlet conditions, assume He from CoolProps";
    parameter Real blanketCoolantMr(unit = "g/mol") = 4 "Molecular weight of blanket coolant, assuming He (g/mol)";
    parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency of 85 percent";
    //
    // Variables
    Real idealCompressorWork(unit = "kJ/mol") "Compressor work (kJ/mol)";
    Real compressorPower(unit = "kW") "Compressor energy (kW)";
    //
  equation
    idealCompressorWork = 8.3145 * compTempIn * (blanketCoolantRatioCpCv / (blanketCoolantRatioCpCv - 1)) * ((blanketPessure / compPressureIn) ^ ((blanketCoolantRatioCpCv - 1) / blanketCoolantRatioCpCv) - 1) / 1000 "Determines the ideal isentropic work of compression (kJ/mol)";
    compressorPower = HeMassFlow * idealCompressorWork * 1000 / (blanketCoolantMr * isentropicEfficiency) "Determines actual compressor power required (kW)";
    //
    // Runtime Assertions
    assert(idealCompressorWork >= 0,"---> Assertion Error in [HeGasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"]  cannot be negative!",level = AssertionLevel.error);
    assert(idealCompressorWork <= 20,"---> Assertion Warning in [HeGasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"]  outside of reasonable range!",level = AssertionLevel.warning);
    assert(compressorPower >= 0,"---> Assertion Error in [HeGasCompression], variable [compressorPower = "+String(compressorPower)+"]  cannot be negative!",level = AssertionLevel.error);
    assert(compressorPower <= 100,"---> Assertion Warning in [HeGasCompression], variable [compressorPower = "+String(compressorPower)+"]  outside of reasonable range!",level = AssertionLevel.warning);

  end HeGasCompression;

  model ExchangerHeatLoss
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real HeMassFlow(unit = "kg/s") "Helium Mass flowrate (kg/s), from HeStreamCalc";
    //
    // Specified Parameters
    parameter Real exchangerDT(unit = "K") = 20 "Temperature differnce on counter current interchanger (K)";
    parameter Real HeSpecificHeat(unit = "kJ/(kg.K)") = 5.2 "Specific heat capacity of helium at average blanker conditions of 300 to 700 °C at 8 bar (kJ/(kg K))";
    //
    // Variables
    Real heatLost(unit = "kW") "Heat lost (kW)";
    //
  equation
    heatLost = HeMassFlow * HeSpecificHeat * exchangerDT "Determines heat lost through counter current interchanger using Q = m.Cp.dT (kW)";
    //
    //Runtime Assertions
    assert(heatLost >= 0,"---> Assertion Error in [ExchangerHeatLoss], variable [heatLost = "+String(heatLost)+"] cannot be negative!",level = AssertionLevel.error);
    assert(heatLost <= 100,"---> Assertion Warning in [ExchangerHeatLoss], variable [heatLost = "+String(heatLost)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end ExchangerHeatLoss;

  model GetterBedRegenHeating
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real tritiumMassFlow(unit = "g/s") "Tritium flow rate (g/s), imported from TritiumBreedingRate";
    //
    // Specified Parameters
    parameter Real getterSatCapacity(unit = "1") = 0.02 "Saturated getter tritium capacity (wt/wt%)";
    parameter Real getterOperatingTime(unit = "h") = 24 "Time taken between bed regenerations (hr)";
    parameter Real getterRegenTime(unit = "h") = 12 "Time taken for total bed regeneration, NOT including cooldown (hr)";
    parameter Real getterTempOperating(unit = "K") = 573 "Operating temperature of getter bed (K)";
    parameter Real getterTempRegen(unit = "K") = 873 "Regenerating temperature of getter bed (K)";
    parameter Real getterHeatCapacity(unit = "kJ/(kg.K)") = 0.4 "Getter material heat capacity (kJ/kg K)";
    //
    // Variables
    Real getterMass(unit = "kg") "Calulcated getter mass (kg)";
    Real getterHeatPower(unit = "kW") "Heat required to raise bed from operating to regenerating temperature (K)";
    // !!Size this based on GHSV!!
  equation
    getterMass = tritiumMassFlow * 3600 * getterOperatingTime / (1000 * getterSatCapacity) "Evaluates mass of getter material required for a given flow of tritium (kg)";
    getterHeatPower = getterMass * getterHeatCapacity * (getterTempRegen - getterTempOperating) / (getterRegenTime * 3600) "Energy required to heat the getter material to regen temperature (kW)";
 //
    //Runtime Assertions
    assert(getterMass >= 0,"---> Assertion Error in [GetterBedRegenHeating], variable [getterMass = "+String(getterMass)+"] cannot be negative!",level = AssertionLevel.error);
    assert(getterMass <= 1000,"---> Assertion Warning in [GetterBedRegenHeating], variable [getterMass = "+String(getterMass)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(getterHeatPower >= 0,"---> Assertion Error in [GetterBedRegenHeating], variable [getterHeatPower = "+String(getterHeatPower)+"] cannot be negative!",level = AssertionLevel.error);
    assert(getterHeatPower <= 100,"---> Assertion Warning in [GetterBedRegenHeating], variable [getterHeatPower = "+String(getterHeatPower)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end GetterBedRegenHeating;

  model GetterRegenGasCompression
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real tritiumMassFlow(unit = "g/s") "Tritium mass flow (g/s), imported from TritiumBreedingRate ";
    //
    // Specified Parameters
    parameter Real compPressureIn(unit = "Pa") = 1E5 "Pressure at compressor inlet(Pa)";
    parameter Real compPressureOut(unit = "Pa") = 10E5 "Pressure at compressor outlet (Pa)";
    parameter Real compTempIn(unit = "K") = 293 "Temperature at compressor inlet (K)";
    parameter Real blanketCoolantRatioCpCv(unit = "1") = 1.67 "Ratio of coolant Cp/Cv at compressor inlet conditions, assume He from CoolProps";
    parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency of 85 percent";
    parameter Real desiredTritiumMolFrac(unit = "1") = 1E-4 "Desired output concentration (mol frac)";
    parameter Real coolantMolecularWeight(unit = "g/mol") = 4 "Molecular weight of the coolant (g/mol), assuming He";
    //
    // Variables
    Real HePurgeMolarFlow(unit = "mol/s") "He purge molar flowrate (mol/s)";
    Real idealCompressorWork(unit = "kJ/mol") "Ideal compressor work on molar basis (kJ/mol)";
    Real compressorPower(unit = "kW") "Power requirement of purge compressor(kW)";
    //
  equation
    idealCompressorWork = 8.3145 * compTempIn * (blanketCoolantRatioCpCv / (blanketCoolantRatioCpCv - 1)) * ((compPressureOut / compPressureIn) ^ ((blanketCoolantRatioCpCv - 1) / blanketCoolantRatioCpCv) - 1) / 1000 "Determines the ideal isentropic work of compression (kJ/mol)";
    HePurgeMolarFlow = tritiumMassFlow / (desiredTritiumMolFrac * 6) "Calculates the molar flow of He purge to reach specified concentration (mol/s)";
    compressorPower = idealCompressorWork * HePurgeMolarFlow / isentropicEfficiency "Calculates the power drawn by compressing the purge gas stream (kW)";
    //
    //Runtime Assertions
    assert(HePurgeMolarFlow >= 0,"---> Assertion Error in [GetterRegenGasCompression], variable [HePurgeMolarFlow = "+String(HePurgeMolarFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(HePurgeMolarFlow <= 100,"---> Assertion Warning in [GetterRegenGasCompression], variable [HePurgeMolarFlow = "+String(HePurgeMolarFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(idealCompressorWork >= 0,"---> Assertion Error in [GetterRegenGasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"] cannot be negative!",level = AssertionLevel.error);
    assert(idealCompressorWork <= 20,"---> Assertion Warning in [GetterRegenGasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(compressorPower >= 0,"---> Assertion Error in [GetterRegenGasCompression], variable [compressorPower = "+String(compressorPower)+"] cannot be negative!",level = AssertionLevel.error);
    assert(compressorPower <= 100,"---> Assertion Warning in [GetterRegenGasCompression], variable [compressorPower = "+String(compressorPower)+"] outside of reasonable range!",level = AssertionLevel.warning);
 //
  end GetterRegenGasCompression;
end BlanketDetrit;
