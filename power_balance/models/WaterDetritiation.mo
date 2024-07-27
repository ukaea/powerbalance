package WaterDetritiation "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."

model WaterDetritPower
  //
  import SI = Modelica.Units.SI;
  //
  parameter Real ThermalPower(unit = "MW") "Total high grade thermal power, MW";
  //
  // Instantiating models
  ElectrolysisEnergy electrolysisEnergy(ThermalPower = ThermalPower) "Instantiating models";
  WaterHeating waterHeating(ThermalPower = ThermalPower) "Instantiating models";
  GasCompression gasCompression(waterColumnMassFlow = electrolysisEnergy.waterColumnMassFlow) "Instantiating models";
  //
  // Declarations
  parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
  SI.Power ElecPowerConsumed;
  //
equation
  ElecPowerConsumed = 1e3 * (1 + contingencyFactor) * (electrolysisEnergy.electrolysisPower + waterHeating.heatingPower + gasCompression.compressorPower) "Total WDS power; the 1e3 multiplier ensures the output is in W";
  //
  //Runtime Assertions
  assert(ElecPowerConsumed >= 0, "---> Assertion Error in [WaterDetritPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] cannot be negative!", level = AssertionLevel.error);
  assert(ElecPowerConsumed <= 1e8, "---> Assertion Warning in [WaterDetritPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] outside of reasonable range!", level = AssertionLevel.warning);
end WaterDetritPower;
  model ElectrolysisEnergy
    //
    // Imported Parameters
    parameter Real ThermalPower(unit = "MW") "Total high grade thermal power, MW";
    //
    // Parameters
    parameter Real electrolysisSpecificEnergy(unit = "kJ/kg") = 26895 "Electrolysis power per kg of water (kJ/kg H2O), ref: M. Lehmer, Water Electroysis, Power to Gas: Technology and Business Models (2014)";
    //
    // Variables
    Real waterColumnMassFlow(unit = "kg/s") "Water flow rate (kg/s)";
    Real electrolysisPower(unit = "kW") "Electrolysis Power (kW)";
    //
  equation
    waterColumnMassFlow = 100 * ThermalPower / (1000 * 3600) "Water flowrate (kg/s), based off thermal power (in GW) relationship";
    electrolysisPower = waterColumnMassFlow * electrolysisSpecificEnergy "Times by 1/3600 to convert per hour to per second (kW)";
    //
    //Runtime Assertions
    assert(waterColumnMassFlow >= 0, "---> Assertion Error in [ElectrolysisEnergy], variable [waterColumnMassFlow = "+String(waterColumnMassFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(waterColumnMassFlow <= 100, "---> Assertion Warning in [ElectrolysisEnergy], variable [waterColumnMassFlow = "+String(waterColumnMassFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(electrolysisPower >= 0, "---> Assertion Error in [ElectrolysisEnergy], variable [electrolysisPower = "+String(electrolysisPower)+"] cannot be negative!", level = AssertionLevel.error);
    assert(electrolysisPower <= 1e4, "---> Assertion Warning in [ElectrolysisEnergy], variable [electrolysisPower = "+String(electrolysisPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end ElectrolysisEnergy;

  model WaterHeating
    //
    // Imported Parameters
    import SI = Modelica.Units.SI;
    Real ThermalPower(unit = "MW") "Total high grade thermal power, MW";
    //
    // Parameters
    parameter Real waterTargetTemp(unit = "degC") = 70 "Water target temperature (°C)";
    parameter Real waterAmbientTemp(unit = "degC") = 20 "Ambient water temperature (°C)";
    parameter Real vapourFraction(unit = "1") = 0.14 "Vapour fraction";
    parameter Real latentHeatVapourisation(unit = "kJ/kg") = 2264.7 "Latent heat of vapourisation (kJ/kg)";
    parameter Real waterCp(unit = "kJ/(kg.degC)") = 4.18 "Water heat capacity (kJ/kg °C)";
    //
    // Variables
    Real waterMassFlow(unit = "kg/s") "Water flow rate";
    Real heatingPower(unit = "kW") "Heating power";
    Real refluxRatioLPCE(unit = "1") "LPCE reflux ratio";
    //
  equation
    waterMassFlow = 60 * ThermalPower / (1000 * 3600) "Water flow rate (kg/s), based off thermal power (in GW) relationship !! Why different from electrolysis energy? !!";
    refluxRatioLPCE = 1 + vapourFraction / (1 - vapourFraction);
    heatingPower = waterMassFlow * (refluxRatioLPCE * waterCp * (waterTargetTemp - waterAmbientTemp) + latentHeatVapourisation * vapourFraction) "Main equation for heating power (kW)";
    //
    //Runtime Assertions
    assert(waterMassFlow >= 0, "---> Assertion Error in [WaterHeating], variable [waterMassFlow = "+String(waterMassFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(waterMassFlow <= 100, "---> Assertion Warning in [WaterHeating], variable [waterMassFlow = "+String(waterMassFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(heatingPower >= 0, "---> Assertion Error in [WaterHeating], variable [heatingPower = "+String(heatingPower)+"] cannot be negative!", level = AssertionLevel.error);
    assert(heatingPower <= 1e8, "---> Assertion Warning in [WaterHeating], variable heatingPower = "+String(heatingPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(refluxRatioLPCE >= 0, "---> Assertion Error in [WaterHeating], variable [refluxRatioLPCE = "+String(refluxRatioLPCE)+"] cannot be negative!", level = AssertionLevel.error);
    assert(refluxRatioLPCE <= 100, "---> Assertion Warning in [WaterHeating], variable [refluxRatioLPCE = "+String(refluxRatioLPCE)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end WaterHeating;

  model GasCompression
    //
    // Imported Parameters
    import SI = Modelica.Units.SI;
    Real waterColumnMassFlow(unit = "kg/s") "Imported from ElectrolysisEnergy";
    //
    // Parameters
    parameter Real compPressureIn(unit = "Pa") = 1E5 "Pressure at the compressor inlet (Pa)";
    parameter Real compPressureOut(unit = "Pa") = 5E5 "Pressure at the compressor outlet (Pa)";
    parameter Real compTempIn(unit = "K") = 293 "Temperature at the compressor inlet (K)";
    parameter Real hydrogenRatioCpCv(unit = "1") = 1.41 "Ratio of Cp/Cv for hydrogen at inlet conditions";
    parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency of 85 percent";
    //
    // Variables
    Real hydrogenMolarFlow(unit = "mol/s") "Molar flow rate of hydrogen produced via electrolysis (mol/s)";
    Real idealCompressorWork(unit = "kJ/mol") "Compressor ideal work of compression (kJ/mol)";
    Real compressorPower(unit = "kW") "Compressor energy (kW)";
    //
  equation
    hydrogenMolarFlow = 1000 * waterColumnMassFlow / 18 "Assuming all water is electrolysed (mol/s)";
    idealCompressorWork = 8.3145 * compTempIn * (hydrogenRatioCpCv / (hydrogenRatioCpCv - 1)) * ((compPressureOut / compPressureIn) ^ ((hydrogenRatioCpCv - 1) / hydrogenRatioCpCv) - 1) / 1000 "Determines the ideal isentropic work of compression (kJ/mol)";
    compressorPower = idealCompressorWork * hydrogenMolarFlow / isentropicEfficiency "kW";
    //
    //Runtime Assertions
    assert(hydrogenMolarFlow >= 0, "---> Assertion Error in [GasCompression], variable [hydrogenMolarFlow = "+String(hydrogenMolarFlow)+"] cannot be negative!", level = AssertionLevel.error);
    assert(hydrogenMolarFlow <= 100, "---> Assertion Warning in [GasCompression], variable [hydrogenMolarFlow = "+String(hydrogenMolarFlow)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(idealCompressorWork >= 0, "---> Assertion Error in [GasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"] cannot be negative!", level = AssertionLevel.error);
    assert(idealCompressorWork <= 20, "---> Assertion Warning in [GasCompression], variable [idealCompressorWork = "+String(idealCompressorWork)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(compressorPower >= 0, "---> Assertion Error in [GasCompression], variable [compressorPower = "+String(compressorPower)+"] cannot be negative!", level = AssertionLevel.error);
    assert(compressorPower <= 1e4, "---> Assertion Warning in [GasCompression], variable [compressorPower = "+String(compressorPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end GasCompression;
end WaterDetritiation;
