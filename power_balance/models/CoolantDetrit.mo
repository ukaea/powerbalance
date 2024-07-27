package CoolantDetrit "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model CoolantDetritCaseByCase
    //
    // Imported Parameters
    import SI = Modelica.Units.SI;
    parameter Real ThermalPower(unit = "MW") "Total high grade thermal power, MW";
    parameter String PrimaryCoolantType;
    SI.Power ElecPowerConsumed;
    //
    // Instantiating models
    TritiumBreedingRate tritiumBreedingRate(ThermalPower = ThermalPower);
    TritiumPermeation tritiumPermeationRate(ThermalPower = ThermalPower);
    // Water coolant - CECE detrit process
    WaterCoolant.WaterCoolantPower waterCoolantPower(tritiumPermeationRate = tritiumPermeationRate.permeationRate);
    // Non-carrier coolant tritium is reliant on permeation through exchanger - Catalyst Recombination & Drier
    GasCoolants.CO2_NonCarrierPower gasCO2NonCarrierPower(tritiumPermeationRate = tritiumPermeationRate.permeationRate);
    GasCoolants.He_NonCarrierPower gasHeliumNonCarrierPower(tritiumPermeationRate = tritiumPermeationRate.permeationRate);
    // Carrier coolant assumes all bred tritium is captured - Catalyst Recombination & Drier
    GasCoolants.CO2_CarrierPower gasCO2CarrierPower(tritiumPermeationRate = tritiumBreedingRate.tritiumBreedRate);
    GasCoolants.He_CarrierPower gasHeliumCarrierPower(tritiumPermeationRate = tritiumBreedingRate.tritiumBreedRate);
    // Molten salt coolant always a carrier - Helium Bubble Tower
    MoltenSaltCoolants.FliBe_Power moltenSaltFliBe(tritiumBreedRate = tritiumBreedingRate.tritiumBreedRate);
    MoltenSaltCoolants.LiPb_Power moltenSaltLiPb(tritiumBreedRate = tritiumBreedingRate.tritiumBreedRate);
    //
    //
  equation
    ElecPowerConsumed = if PrimaryCoolantType == "H2O" then waterCoolantPower.totalPower elseif PrimaryCoolantType == "CO2_NC" then gasCO2NonCarrierPower.totalPower
     elseif PrimaryCoolantType == "He_NC" then gasHeliumNonCarrierPower.totalPower
     elseif PrimaryCoolantType == "CO2_C" then gasCO2CarrierPower.totalPower
     elseif PrimaryCoolantType == "He_C" then gasHeliumCarrierPower.totalPower
     elseif PrimaryCoolantType == "FLiBe" then moltenSaltFliBe.totalPower
     elseif PrimaryCoolantType == "LiPb" then moltenSaltLiPb.totalPower else -1;
    //
    assert(ElecPowerConsumed >= 0, "---> Assertion Error in [CoolantDetritCaseByCase], variable [ElecPowerConsumed] outside of acceptable range!", level = AssertionLevel.error);
    assert(ElecPowerConsumed <= 1e8, "---> Assertion Error in [CoolantDetritCaseByCase], variable [ElecPowerConsumed] outside of acceptable range!", level = AssertionLevel.error);
    assert(tritiumPermeationRate.permeationRate <= tritiumBreedingRate.tritiumBreedRate, "---> Assertion Warning in [TritiumPermeation], variable [permeationRate] outside of reasonable range!", level = AssertionLevel.warning);
    //
  end CoolantDetritCaseByCase;

  model TritiumBreedingRate
      // Imported Parameters
    import SI = Modelica.Units.SI;
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
    //
  equation
    tritiumInput_Reactor = tritiumInput * ThermalPower / 1e3 "Tritium input to reactor (mol/sec)";
    tritiumBreedRate = tritiumInput_Reactor * burnRate * tritiumBreedRatio / 100 "Tritium breeding rate (mol/sec)";
    //
    //Runtime Assertions
    assert(tritiumInput_Reactor >= 0, "---> Assertion Error in [TritiumBreedingRate], variable [tritiumInput_Reactor] cannot be negative!", level = AssertionLevel.error);
    assert(tritiumInput_Reactor <= 1, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumInput_Reactor] outside of reasonable range!", level = AssertionLevel.warning);
    assert(tritiumBreedRate >= 0, "---> Assertion Error in [TritiumBreedingRate], variable [tritiumBreedRate] cannot be negative!", level = AssertionLevel.error);
    assert(tritiumBreedRate <= 1, "---> Assertion Warning in [TritiumBreedingRate], variable [tritiumBreedRate] outside of reasonable range!", level = AssertionLevel.warning);
    //
  end TritiumBreedingRate;

  model TritiumPermeation
    //
    // Imported Parameters
    import SI = Modelica.Units.SI;
    parameter Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    //
    // Parameters
    parameter Real primaryCoolantTemp(unit = "K") = 823 "Primary coolant temperature at the blanket (K)";
    parameter SI.Length thicknessHXarea = 0.001 "Metal thickness of heat exchanger in heat transfer zone (m)";
    parameter Real pressureTritium_BlanketSide(unit = "Pa") = 10 "Partial pressure of Tritium on blanket side (Pa)";
    parameter Real pressureTritium_CoolantSide(unit = "Pa") = 0 "Partial pressure of Tritium on coolant side (Pa), 0 at start-up";
    parameter Real PRF(unit = "1") = 10 "Permeation Reduction Factor (PRF) indluded to account for permeation mitigation techniques, where 1 = no mitigation)";
    //
    // Variables
    Real permeability(unit = "mol/(m.s.Pa)") "Permeability equation for austenetic Stainless steel (mol/(m s Pa^0.5)";
    SI.Area primaryCoolantHXarea "Primary coolant for the HX area of the reactor (m2)";
    SI.MolarFlowRate permeationRate "Permeation rate with Permeation Reduction Factor (mol/sec)";
    //
  equation
    permeability = 0.000000327 * exp(-7902 / primaryCoolantTemp) "Based off LeClair correlation for stainless steel mol/(m s Pa^0.5)";
    primaryCoolantHXarea = 3000 * ThermalPower / 1e3 "Estimate heat exchanger size based off correlation of GW thermal power (m2)";
    permeationRate = (permeability * primaryCoolantHXarea / thicknessHXarea * (sqrt(pressureTritium_BlanketSide) - sqrt(pressureTritium_CoolantSide))) / PRF "Permeation rate of tritium into coolant loop, based off LeClair correlation (mol/s)";
    //
    // Runtime Assertions
    assert(permeability >= 0, "---> Assertion Error in [TritiumPermeation], variable [permeability] cannot be negative!", level = AssertionLevel.error);
    assert(permeability <= 1, "---> Assertion Warning in [TritiumPermeation], variable [permeability] outside of reasonable range!", level = AssertionLevel.warning);
    assert(primaryCoolantHXarea >= 0, "---> Assertion Error in [TritiumPermeation], variable [primaryCoolantHXarea] cannot be negative!", level = AssertionLevel.error);
    assert(primaryCoolantHXarea <= 1e4, "---> Assertion Warning in [TritiumPermeation], variable [primaryCoolantHXarea] outside of reasonable range!", level = AssertionLevel.warning);
    assert(permeationRate >= 0, "---> Assertion Error in [TritiumPermeation], variable [permeationRate] cannot be negative!", level = AssertionLevel.error);
    assert(permeationRate <= 1, "---> Assertion Warning in [TritiumPermeation], variable [permeationRate] outside of reasonable range!", level = AssertionLevel.warning);
    //
  end TritiumPermeation;

  package WaterCoolant
    model WaterCoolantPower
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Tritium permeation rate (mol/s)";
      //
      // Instantiating models
      WaterSplitStream waterSplitStream(tritiumPermeationRate = tritiumPermeationRate);
      ElectrolysisEnergy electrolysisEnergy(splitStreamMassFlow = waterSplitStream.splitStreamMassFlow);
      WaterHeating waterHeating(splitStreamMassFlow = waterSplitStream.splitStreamMassFlow);
      GasCompression gasCompression(waterColumnMassFlow = electrolysisEnergy.waterColumnMassFlow);
      //
      // Parameters and variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      SI.Power totalPower "Total water coolant power (W)";
      //
    equation
      totalPower = (1 + contingencyFactor) * (electrolysisEnergy.electrolysisPower + waterHeating.heatingPower + gasCompression.compressorPower) * 1E3 "W";
    end WaterCoolantPower;

    model WaterSplitStream
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Permeation rate (mol/sec), imported from TritiumPermeation model (mol/s)";
      //
      // Parameters
      parameter Real tritiumAbsRadioactivity(unit = "Bq/g") = 3.57e14 "Tritium asbolute radioactivity (Bq/g)";
      parameter Real mainLoopRadioactiveLim(unit = "Bq/m3") = 1.48e15 "Radioactive limit in the coolant loop (Bq/m3), CANDU limit";
      parameter Real coolantDensity(unit = "kg/m3") = 1000 "Density of coolant, water in this instance (kg/m3)";
      parameter Real removalEfficiency(unit = "1") = 0.95 "Efficiency of system at removing tritium (assume 95 %)";
      //
      // Variables
      Real maxTritiumConc(unit = "mol/m3") "Maximum tritium concentration, molality (mol(T2)/m3(H2O))";
      Real splitStreamMassFlow(unit = "kg/s") "Mass flow of the side stream (kg/sec)";
      //
    equation
      maxTritiumConc = mainLoopRadioactiveLim / (6 * tritiumAbsRadioactivity) "Determines the max concentration of tritium allowed in the main coolant loop based off absolute values (mol(T2)/m3(H2O))";
      splitStreamMassFlow = coolantDensity * tritiumPermeationRate / (maxTritiumConc * removalEfficiency) "Flowrate of splitstream to maintain concentration of T2 in coolant loop (kg(H2O)/s)";
    end WaterSplitStream;

    model ElectrolysisEnergy
      //
      // Imported Parameters
      Real splitStreamMassFlow(unit = "kg/s");
      //
      // Parameters
      parameter Real electrolysisSpecificEnergy(unit = "kJ/kg") = 26895 "Electrolysis power per kg of water (kJ/kg H2O), ref: M. Lehmer, Water Electroysis, Power to Gas: Technology and Business Models (2014)";
      //
      // Variables
      Real waterColumnMassFlow(unit = "kg/s") "Total water flow rate (kg/s)";
      Real electrolysisPower(unit = "kW") "Electrolysis power (kW)";
      //
    equation
      waterColumnMassFlow = splitStreamMassFlow * 50 / 20 "Scaling factor of 50/20 based off Boniface paper";
      electrolysisPower = waterColumnMassFlow * electrolysisSpecificEnergy "Power required for water elecrolysis (kW)";
    end ElectrolysisEnergy;

    model WaterHeating
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real splitStreamMassFlow(unit = "kg/s") "Imported from WaterSplitStream";
      //
      // Parameters
      parameter Real vapourFraction(unit = "1") = 0.14 "Vapour fraction";
      parameter Real waterTargetTemperature(unit = "degC") = 70 "Water target temperature (°C)";
      parameter Real waterAmbientTemperature(unit = "degC") = 20 "Ambient water temperature (°C)";
      parameter Real latentHeatVapourisation(unit = "kJ/kg") = 2264.7 "Latent heat of vapourisation (kJ/kg)";
      parameter Real waterCp(unit = "kJ/(kg.K)") = 4.18 "Water heat capacity (kJ/kg °C)";
      //
      // Variables
      Real waterMassFlowrate(unit = "kg/s") "Water flow rate (kg/s)";
      Real refluxRatioLPCE(unit = "1") "Reflux ratio for the LPCE";
      Real heatingPower(unit = "kW") "Heating power (kW)";
      //
    equation
      waterMassFlowrate = splitStreamMassFlow * 30 / 20 "Scales column flowrate based on Boniface paper correlation !! WHY DIFFERENT TO ELECTROYSIS MODEL? !!";
      refluxRatioLPCE = 1 + vapourFraction / (1 - vapourFraction) "Calculates the reflux ratio based of vapour fraction";
      heatingPower = waterMassFlowrate * (refluxRatioLPCE * waterCp * (waterTargetTemperature - waterAmbientTemperature) + latentHeatVapourisation * vapourFraction) "kW";
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
    end GasCompression;
  end WaterCoolant;

  package GasCoolants
    model CO2_NonCarrierPower
      // Using a catalyst recombination drier technology, which converts the tritium to water and removes in a subsequent adsorbent bed. This model is for a CO2 non-carrier coolant. As stream is a primary coolant, no additional heating prior to the reactor is expected. This model also assumes no ehat integration is present.
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Imported from TritiumPermeation (mol/s)";
      //
      // Parameters
      parameter Real mrCO2(unit = "g/mol") = 44 "Molecular Weight of CO2 (g/mol)";
      parameter Real densityCO2(unit = "kg/m3") = 96.5  "Density of CO2, take 96.5 kg/m3 @ 100 bar, 300 oC (kg/m3)";
      parameter Real ratioCpCvCO2(unit = "1") = 5.65 "CO2 after adsorber (assuming no heat integration), take 5.85 @ 100 bar, 50 oC" ;
      //
      // Instantiating models
      SplitStreamFlow splitStreamFlow(permeationRate = tritiumPermeationRate, gasDensity = densityCO2, coolantMolWeight = mrCO2);
      GasCoolantComp gasCoolantComp(coolantMassFlow = splitStreamFlow.splitstreamMassFlow, coolantMolWeight = mrCO2, ratioCpCv = ratioCpCvCO2);
      GasCoolantRegenBedHeating gasCoolantRegenBedHeating(gasCoolantVolFlow = splitStreamFlow.splitstreamVolFlow);
      GasCoolantCompRegenGas gasCoolantCompRegenGas(totalRegenBedHeating = gasCoolantRegenBedHeating.totalRegenBedHeating, adsorbentTempOperating = gasCoolantRegenBedHeating.adsorbentTempOperating, adsorbentTempRegen = gasCoolantRegenBedHeating.adsorbentTempRegen);
      //
      // Parameters and variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      Real totalPower(unit = "W") "Total power requirement for a CO2 non-carrier detrit process (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (gasCoolantComp.compressorEnergy + gasCoolantRegenBedHeating.totalRegenBedHeating + gasCoolantCompRegenGas.regenAirHeating + gasCoolantCompRegenGas.compressorEnergy) "W";
      //
      //Runtime Assertions
      assert(totalPower >= 0, "---> Assertion Error in [CO2_NonCarrierPower], variable [totalPower] cannot be negative!", level = AssertionLevel.error);
      assert(totalPower <= 1e5, "---> Assertion Warning in [CO2_NonCarrierPower], variable [totalPower] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end CO2_NonCarrierPower;

    model CO2_CarrierPower
      // Using a catalyst recombination drier technology, which converts the tritium to water and removes in a subsequent adsorbent bed. This model is for a CO2 carrier coolant. As stream is a primary coolant, no additional heating prior to the reactor is expected (as is the case in AirGasDetrit).
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Imported from TritiumPermeation (mol/s)";
      //
      // Parameters
      parameter Real mrCO2(unit = "g/mol") = 44 "Molecular Weight of CO2 (g/mol)";
      parameter Real densityCO2(unit = "kg/m3") = 96.5  "Density of CO2, take 96.5 kg/m3 @ 100 bar, 300 oC (kg/m3)";
      parameter Real ratioCpCvCO2(unit = "1") = 5.65 "CO2 after adsorber (assuming no heat integration), take 5.85 @ 100 bar, 50 oC" ;
      //
      // Instantiating models
      SplitStreamFlow splitStreamFlow(permeationRate = tritiumPermeationRate, gasDensity = densityCO2, coolantMolWeight = mrCO2);
      GasCoolantComp gasCoolantComp(coolantMassFlow = splitStreamFlow.splitstreamMassFlow, coolantMolWeight = mrCO2, ratioCpCv = ratioCpCvCO2);
      GasCoolantRegenBedHeating gasCoolantRegenBedHeating(gasCoolantVolFlow = splitStreamFlow.splitstreamVolFlow);
      GasCoolantCompRegenGas gasCoolantCompRegenGas(totalRegenBedHeating = gasCoolantRegenBedHeating.totalRegenBedHeating, adsorbentTempOperating = gasCoolantRegenBedHeating.adsorbentTempOperating, adsorbentTempRegen = gasCoolantRegenBedHeating.adsorbentTempRegen);
      //
      // Parameters and variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      Real totalPower(unit = "W") "Total power requirement for a CO2 carrier detrit process (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (gasCoolantComp.compressorEnergy + gasCoolantRegenBedHeating.totalRegenBedHeating + gasCoolantCompRegenGas.regenAirHeating + gasCoolantCompRegenGas.compressorEnergy) "W";
      //
      // Runtime Assertions
      assert(totalPower >= 0, "---> Assertion Error in [CO2_CarrierPower], variable [totalPower] cannot be negative!", level = AssertionLevel.error);
      assert(totalPower <= 1e5, "---> Assertion Warning in [CO2_CarrierPower], variable [totalPower] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end CO2_CarrierPower;

    model He_NonCarrierPower
      // Using a catalyst recombination drier technology, which converts the tritium to water and removes in a subsequent adsorbent bed. This model is for a He non-carrier coolant. As stream is a primary coolant, no additional heating prior to the reactor is expected (as is the case in AirGasDetrit).
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Imported from TritiumPermeation (mol/s)";
      //
      // Parameters
      parameter Real mrHe(unit = "g/mol") = 4 "Molecular Weight of He (g/mol)";
      parameter Real densityHe(unit = "kg/m3") = 8.2 "Density of He, take as 8.2 @ 302 oC, 100 bar (kg/m3)";
      parameter Real ratioCpCvHe(unit = "1") = 1.66 "Ratio Cp/Cv for He at adsorber outlet, take 1.66 @ 50 oC, 100 bar";
      //
      // Instantiating models
      SplitStreamFlow splitStreamFlow(permeationRate = tritiumPermeationRate, gasDensity = densityHe, coolantMolWeight = mrHe);
      GasCoolantComp gasCoolantComp(coolantMassFlow = splitStreamFlow.splitstreamMassFlow, coolantMolWeight = mrHe, ratioCpCv = ratioCpCvHe);
      GasCoolantRegenBedHeating gasCoolantRegenBedHeating(gasCoolantVolFlow = splitStreamFlow.splitstreamVolFlow);
      GasCoolantCompRegenGas gasCoolantCompRegenGas(totalRegenBedHeating = gasCoolantRegenBedHeating.totalRegenBedHeating, adsorbentTempOperating = gasCoolantRegenBedHeating.adsorbentTempOperating, adsorbentTempRegen = gasCoolantRegenBedHeating.adsorbentTempRegen);
      //
      // Parameters and variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      Real totalPower(unit = "W") "Total power requirement for a He non-carrier detrit process (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (gasCoolantComp.compressorEnergy + gasCoolantRegenBedHeating.totalRegenBedHeating + gasCoolantCompRegenGas.regenAirHeating + gasCoolantCompRegenGas.compressorEnergy) "W";
      //
      // Runtime Assertions
      assert(totalPower >= 0, "---> Assertion Error in [He_NonCarrierPower], variable [totalPower] cannot be negative!", level = AssertionLevel.error);
      assert(totalPower <= 1e7, "---> Assertion Warning in [He_NonCarrierPower], variable [totalPower] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end He_NonCarrierPower;

    model He_CarrierPower
      // Using a catalyst recombination drier technology, which converts the tritium to water and removes in a subsequent adsorbent bed. This model is for a He carrier coolant. As stream is a primary coolant, no additional heating prior to the reactor is expected (as is the case in AirGasDetrit).
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumPermeationRate(unit = "mol/s") "Imported from TritiumPermeation (mol/s)";
      //
      // Parameters
      parameter Real mrHe(unit = "g/mol") = 4 "Molecular Weight of He (g/mol)";
      parameter Real densityHe(unit = "kg/m3") = 8.2 "Density of He, take as 8.2 @ 302 oC, 100 bar (kg/m3)";
      parameter Real ratioCpCvHe(unit = "1") = 1.66 "Ratio Cp/Cv for He at adsorber outlet, take 1.66 @ 50 oC, 100 bar";
      //
      // Instantiating models
      SplitStreamFlow splitStreamFlow(permeationRate = tritiumPermeationRate, gasDensity = densityHe, coolantMolWeight = mrHe);
      GasCoolantComp gasCoolantComp(coolantMassFlow = splitStreamFlow.splitstreamMassFlow, coolantMolWeight = mrHe, ratioCpCv = ratioCpCvHe);
      GasCoolantRegenBedHeating gasCoolantRegenBedHeating(gasCoolantVolFlow = splitStreamFlow.splitstreamVolFlow);
      GasCoolantCompRegenGas gasCoolantCompRegenGas(totalRegenBedHeating = gasCoolantRegenBedHeating.totalRegenBedHeating, adsorbentTempOperating = gasCoolantRegenBedHeating.adsorbentTempOperating, adsorbentTempRegen = gasCoolantRegenBedHeating.adsorbentTempRegen);
      //
      // Parameters and variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      Real totalPower(unit = "W") "Total power requirement for a He carrier detrit process (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (gasCoolantComp.compressorEnergy + gasCoolantRegenBedHeating.totalRegenBedHeating + gasCoolantCompRegenGas.regenAirHeating + gasCoolantCompRegenGas.compressorEnergy) "W";
      //
      // Runtime Assertions
      assert(totalPower >= 0, "---> Assertion Error in [He_CarrierPower], variable [totalPower] cannot be negative!", level = AssertionLevel.error);
      assert(totalPower <= 1e7, "---> Assertion Warning in [He_CarrierPower], variable [totalPower] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end He_CarrierPower;

    model SplitStreamFlow
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real permeationRate(unit = "mol/s") "Permeation rate (mol/sec)";
      Real gasDensity(unit = "kg/m3") "Gas density, imported from parent model depending on gas selected (kg/m3)";
      Real coolantMolWeight(unit = "g/mol") "Gas coolant molecular weight (g/mol)";
      //
      // Parameters
      parameter Real primaryLoopRadioactiveLim(unit = "Bq/kg(H2O)") = 3.7e9 "Radioactive limit in the primary loop, based off ITER estimated limits of 0.1 Ci/kg(H2O) = 3.7e9 (Bq/kg(H2O))";
      parameter Real TritiumAbsoluteActivity(unit = "Bq/g(T2)") = 3.57e14 "Tritium radioactivity (Bq/g(T2))";
      parameter Real removalEfficiency(unit = "1") = 0.90 "Assumed tritium removal efficiency";
      //
      // Variables
      Real maxAbsoluteTritiumConc(unit = "g(T2)/kg(Coolant)") "Maximum tritium concentration based on absolute tritium activity and coolant type(g(T2)/kg(coolant))";
      Real gasCoolantSplitstreamMassFlow(unit = "kg(Coolant)/s");
      Real splitstreamMassFlow(unit = "kg/s") "Total mass flow of the splitstream (kg/s)";
      Real splitstreamVolFlow(unit = "Nm3/h") "Total volumetric flowrate of the splitstream (m3/h)";
      //
    equation
      maxAbsoluteTritiumConc = (primaryLoopRadioactiveLim / TritiumAbsoluteActivity) * (1000 / gasDensity)   "Max coolant concentration based on absolute activity values and ratio of coolant density to CANDU water (g(T2)/kg(coolant)";
      gasCoolantSplitstreamMassFlow = permeationRate * 6 / maxAbsoluteTritiumConc "Calculate flowrate of gas coolant based off the tritium conc (kg(Coolant)/s)";
      splitstreamMassFlow = (gasCoolantSplitstreamMassFlow + permeationRate * 6 / 1000) / removalEfficiency "Calculate total mass flow of splitstream based off assumed removal efficiency and tritium present (kg/s)";
      splitstreamVolFlow = 86.6 * 1000 * splitstreamMassFlow / coolantMolWeight "Convert mass flow to volumetric flow at normal conditions, assuming mr of gas is coolant and where 1 mol/s = 86.6 Nm3/h using ideal gas law";
      //
      // Runtime Assertions
      assert(maxAbsoluteTritiumConc >= 0, "---> Assertion Error in [SplitStreamFlow], variable [maxAbsoluteTritiumConc] cannot be negative!", level = AssertionLevel.error);
      assert(maxAbsoluteTritiumConc <= 1, "---> Assertion Warning in [SplitStreamFlow], variable [maxAbsoluteTritiumConc] outside of reasonable range!", level = AssertionLevel.warning);
      assert(gasCoolantSplitstreamMassFlow >= 0, "---> Assertion Error in [SplitStreamFlow], variable [gasCoolantSplitstreamMassFlow] cannot be negative!", level = AssertionLevel.error);
      assert(gasCoolantSplitstreamMassFlow <= 1e3, "---> Assertion Warning in [SplitStreamFlow], variable [gasCoolantSplitstreamMassFlow] outside of reasonable range!", level = AssertionLevel.warning);
      assert(splitstreamMassFlow >= 0, "---> Assertion Error in [SplitStreamFlow], variable [splitstreamMassFlow] cannot be negative!", level = AssertionLevel.error);
      assert(splitstreamMassFlow <= 1e3, "---> Assertion Warning in [SplitStreamFlow], variable [splitstreamMassFlow] outside of reasonable range!", level = AssertionLevel.warning);
      assert(splitstreamVolFlow >= 0, "---> Assertion Error in [SplitStreamFlow], variable [splitstreamVolFlow] cannot be negative!", level = AssertionLevel.error);
      assert(splitstreamVolFlow <= 1e4, "---> Assertion Warning in [SplitStreamFlow], variable [splitstreamVolFlow] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end SplitStreamFlow;

    model GasCoolantComp
      // Recompression after the detrit before rejoining the main coolant loop.
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real coolantMassFlow(unit = "kg/s") "Mass flow of gas coolant (kg/s), from SplitStreamFlow model";
      Real coolantMolWeight(unit = "g/mol") "Molecular weight of gas dependent on coolant selected (g/mol)";
      Real ratioCpCv(unit = "1") "Cp/Cv ratio at inlet conditions for gas coolant, set by model type";
      //
      // Parameters
      parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency";
      parameter Real pressureInlet(unit = "Pa") = 100E5 "Pressure at compressor inlet (Pa) [Assuming 2 bar dp across equipment]";
      parameter Real pressureOutlet(unit = "Pa") = 102E5 "Pressure at compressor outlet, coolant loop pressure @ 102 bar (Pa)";
      parameter Real tempInlet(unit = "K") = 293 "Temperature at compressor inlet (K)";
      //
      // Variables
      Real idealCompressorWork(unit = "kJ/mol") "Ideal compressor work on mass basis (kJ/mol)";
      Real compressorEnergy(unit = "kW") "Compressor energy (kW)";
      //
    equation
      idealCompressorWork = 8.3145 * tempInlet * (ratioCpCv / (ratioCpCv - 1)) * ((pressureOutlet / pressureInlet) ^ ((ratioCpCv - 1) / ratioCpCv) - 1) / 1000 "Isentropic gas compression calculation on molar basis (kJ/mol)";
      compressorEnergy = idealCompressorWork * coolantMassFlow * 1000 / (coolantMolWeight * isentropicEfficiency) "kW";
      //
      // Runtime Assertions
      assert(idealCompressorWork >= 0, "---> Assertion Error in [GasCoolantComp], variable [idealCompressorWork] cannot be negative!", level = AssertionLevel.error);
      assert(idealCompressorWork <= 20, "---> Assertion Warning in [GasCoolantComp], variable [idealCompressorWork] outside of reasonable range!", level = AssertionLevel.warning);
      assert(compressorEnergy >= 0, "---> Assertion Error in [GasCoolantComp], variable [compressorEnergy] cannot be negative!", level = AssertionLevel.error);
      assert(compressorEnergy <= 1e5, "---> Assertion Warning in [GasCoolantComp], variable [compressorEnergy] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end GasCoolantComp;

    model GasCoolantCompRegenGas
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real totalRegenBedHeating(unit = "kW") "Energy regquired to vaoporise adsorbed water and heat adsorber bed, imported from GasCoolantRegenBedHeating";
      Real adsorbentTempOperating(unit = "K") "Adsorbent bed operating temperature (K), imported from GasCoolantRegenBedHeating";
      Real adsorbentTempRegen(unit = "K") "Adsorbent bed temperature for regneration (K), imported from GasCoolantRegenBedHeating";
      //
      // Specified Parameters (assuming air as regen medium)
      parameter Real airExcessAmount(unit = "1") = 0.20 "Factor of excess air for cooldown etc.";
      parameter Real airSpecificHeat(unit = "kJ/(kg.K)") = 1.05;
      parameter Real airTempCompInlet(unit = "K") = 293 "Temperature of regen air at the compressor inlet (K)";
      parameter Real airRatioCpCv(unit = "1") = 1.40 "Ratio of specific heat capacities (Cp/Cv) at inlet conditions";
      parameter Real airPressureInlet(unit = "Pa") = 1E5 "Pressure of air at compressor inlet (Pa)";
      parameter Real airPressureOutlet(unit = "Pa") = 2E5 "Pressure of air at compressor outlet (Pa)";
      parameter Real airMolWeight(unit = "g/mol") = 28.97 "Assuming dry air as regen gas (g/mol)";
      parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency";
      //
      // Variables
      Real regenAirMassFlow(unit = "kg/s") "Required air flowrate based on heating energy required and excess specified (kg/s)";
      Real compressorWork(unit = "kJ/mol") "Isentropic work of compression on molar basis (kJ/mol)";
      Real compressorEnergy(unit = "kW") "Compressor energy (kW)";
      Real regenAirHeating(unit = "kW") "Energy required to heat the regen gas to regen temperature (kW)";
      Real airTempCompOut(unit = "K") "Temperature of regen air at compressor outlet (K)";
      //
    equation
      regenAirMassFlow = (1 + airExcessAmount) * totalRegenBedHeating / (airSpecificHeat * (adsorbentTempRegen - adsorbentTempOperating)) "m = Q/Cp.dT, where Q is total energy required for regen heating calculated in previous model";
      compressorWork = 8.3145 * airTempCompInlet * (airRatioCpCv / (airRatioCpCv - 1)) * ((airPressureOutlet / airPressureInlet) ^ ((airRatioCpCv - 1) / airRatioCpCv) - 1) / 1000 "Based off isentropic gas compression equation (kJ/mol)";
      compressorEnergy = compressorWork * regenAirMassFlow * 1000 / (airMolWeight * isentropicEfficiency) "Calculates compressor energy (kW)";
      airTempCompOut = airTempCompInlet * (airPressureOutlet / airPressureInlet) ^ ((airRatioCpCv - 1) / airRatioCpCv) "Calculates temperature of air at compressor outlet";
      // Checks if temperature out of compressor is less than that required for bed regeneration and if heating is required
      if airTempCompOut < adsorbentTempRegen then
        regenAirHeating = regenAirMassFlow * airSpecificHeat * (adsorbentTempRegen - airTempCompOut) "Calculates energy required to take air from compressor outlet temperature to that required for bed regeneration (kW)";
      else
        regenAirHeating = 0;
      end if;
      //
      //Runtime Assertions
      assert(regenAirMassFlow >= 0, "---> Assertion Error in [GasCoolantCompRegenGas], variable [regenAirMassFlow] cannot be negative!", level = AssertionLevel.error);
      assert(regenAirMassFlow <= 10, "---> Assertion Warning in [GasCoolantCompRegenGas], variable [regenAirMassFlow] outside of reasonable range!", level = AssertionLevel.warning);
      assert(compressorWork >= 0, "---> Assertion Error in [GasCoolantCompRegenGas], variable [compressorWork] cannot be negative!", level = AssertionLevel.error);
      assert(compressorWork <= 20, "---> Assertion Warning in [GasCoolantCompRegenGas], variable [compressorWork] outside of reasonable range!", level = AssertionLevel.warning);
      assert(compressorEnergy >= 0, "---> Assertion Error in [GasCoolantCompRegenGas], variable [compressorEnergy] cannot be negative!", level = AssertionLevel.error);
      assert(compressorEnergy <= 1e5, "---> Assertion Warning in [GasCoolantCompRegenGas], variable [compressorEnergy] outside of reasonable range!", level = AssertionLevel.warning);
      assert(regenAirHeating >= 0, "---> Assertion Error in [GasCoolantCompRegenGas], variable [regenAirHeating] cannot be negative!", level = AssertionLevel.error);
      assert(regenAirHeating <= 1e4, "---> Assertion Warning in [GasCoolantCompRegenGas], variable [regenAirHeating] outside of reasonable range!", level = AssertionLevel.warning);
      assert(airTempCompOut >= 0, "---> Assertion Error in [GasCoolantCompRegenGas], variable [airTempCompOut] cannot be negative!", level = AssertionLevel.error);
      assert(airTempCompOut <= 315, "---> Assertion Warning in [GasCoolantCompRegenGas], variable [airTempCompOut] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end GasCoolantCompRegenGas;

    model GasCoolantRegenBedHeating
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real gasCoolantVolFlow(unit = "Nm3/h") "Volumetric flowrate of air (Nm3/hr), imported from AirGasFlowrate";
      //
      // Specified Parameters
      parameter Real adsorbentBedGHSV(unit = "1/h") = 15000 "Determines the relative bed size based on the Gas Hourly Space Velocity, take 15000 1/h from DEMO estimate (GHSV = vol flow/reactor vol)";
      parameter Real adsorbentBulkDensity(unit = "kg/m3") = 705 "Packing density of the adsorbent when loaded (kg/m3) from manufacturer";
      parameter Real adsorbentSaturationCapacity(unit = "1") = 0.21 "Mol seive saturation capacity fraction, Sigma-Aldritch 3A 21 w/w%  (wt H2O/wt adsorbent)";
      parameter Real adsorbentRegenTime(unit = "h") = 12 "Time taken for bed heating and holding for complete regeneration (hours), NOT including cool down period";
      parameter Real adsorbentHeatCapacity(unit = "kJ/(kg.K)") = 1 "Mol sieve bed heat capacity (based on ceramic type absorbent heat capacity) (kJ/kg K)";
      parameter Real adsorbentTempOperating(unit = "K") = 298 "Adsorbent bed operating temperature (K)";
      parameter Real adsorbentTempRegen(unit = "K") = 573 "Adsorbent bed temperature for regneration (K)";
      parameter Real waterLatentHeatVaporisation(unit = "kJ/kg") = 2260 "Water latent heat of vapourisation (kJ/kg)";
      //
      // Variables
      Real adsorbentDryMass(unit = "kg") "Absorbent mass per bed (kg)";
      Real adsorbentSatCapacity(unit = "kg") "Mass of adsorbed water at saturation (kg)";
      Real adsorbentHeating(unit = "kW") "Energy requjired to heat adsorbent to regen temperature (kW)";
      Real waterEvaporisation(unit = "kW") "Energy requried for evaporation (kw)";
      Real totalRegenBedHeating(unit = "kW") "Total regen heating rate (kW)";
      //
      //
    equation
      // Regen Heating
      adsorbentDryMass = adsorbentBulkDensity * gasCoolantVolFlow / adsorbentBedGHSV "Determines mass of bed adsorbent (kg)";
      adsorbentSatCapacity = adsorbentDryMass * adsorbentSaturationCapacity "Determines mass of water adsorbed to adsorbent bed when saturated (kg)";
      adsorbentHeating = adsorbentDryMass * adsorbentHeatCapacity * (adsorbentTempRegen - adsorbentTempOperating) / (adsorbentRegenTime * 3600) "Determines the total power (kW) required for heating the adsorbent mass over a regen cycle";
      waterEvaporisation = waterLatentHeatVaporisation * adsorbentSatCapacity / (adsorbentRegenTime * 3600) "Energy required to vaporise all water adsorbed (kW)";
      totalRegenBedHeating = waterEvaporisation + adsorbentHeating "kW";
      //
      //Runtime Assertions
      assert(adsorbentDryMass >= 0, "---> Assertion Error in [GasCoolantRegenBedHeating], variable [adsorbentDryMass] cannot be negative!", level = AssertionLevel.error);
      assert(adsorbentDryMass <= 1000, "---> Assertion Warning in [GasCoolantRegenBedHeating], variable [adsorbentDryMass] outside of reasonable range!", level = AssertionLevel.warning);
      assert(adsorbentSatCapacity >= 0, "---> Assertion Error in [GasCoolantRegenBedHeating], variable [adsorbentSatCapacity] cannot be negative!", level = AssertionLevel.error);
      assert(adsorbentSatCapacity <= 0.22 * adsorbentDryMass, "---> Assertion Warning in [GasCoolantRegenBedHeating], variable [adsorbentSatCapacity] outside of reasonable range!", level = AssertionLevel.warning);
      assert(adsorbentHeating >= 0, "---> Assertion Error in [GasCoolantRegenBedHeating], variable [adsorbentHeating] cannot be negative!", level = AssertionLevel.error);
      assert(adsorbentHeating <= 1e4, "---> Assertion Warning in [GasCoolantRegenBedHeating], variable [adsorbentHeating] outside of reasonable range!", level = AssertionLevel.warning);
      assert(waterEvaporisation >= 0, "---> Assertion Error in [GasCoolantRegenBedHeating], variable [waterEvaporisation] cannot be negative!", level = AssertionLevel.error);
      assert(waterEvaporisation <= 1e4, "---> Assertion Warning in [GasCoolantRegenBedHeating], variable [waterEvaporisation] outside of reasonable range!", level = AssertionLevel.warning);
      assert(totalRegenBedHeating >= 0, "---> Assertion Error in [GasCoolantRegenBedHeating], variable [totalRegenBedHeating] cannot be negative!", level = AssertionLevel.error);
      assert(totalRegenBedHeating <= 1e5, "---> Assertion Warning in [GasCoolantRegenBedHeating], variable [totalRegenBedHeating] outside of reasonable range!", level = AssertionLevel.warning);
      //
    end GasCoolantRegenBedHeating;
  end GasCoolants;

  package MoltenSaltCoolants
    model LiPb_Power
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumBreedRate(unit = "mol/s") "Imported from TritiumBreedingRate";
      //
      // Parameters
      parameter Real LiPbMassFlow(unit = "kg/s") = 1500 "Flowrate of LiPb coolant (kg/s)";
      parameter Real mrLiPb(unit = "g/mol") = 214 "Molecular weight of LiPb (g/mol)";
      parameter Real densityLiPb(unit = "kg/m3") = 10000 "Density of LiPb (kg/m3)";
      //
      // Instantiating Models
      HeStreamCalc heStreamCalc(tritiumBreedRate = tritiumBreedRate, coolantMolWeight = mrLiPb, coolantMassFlow = LiPbMassFlow);
      HeGasComp heGasComp(heMassFlow = heStreamCalc.heMassFlow);
      CoolantPumping coolantPumping(coolantMassFlow = LiPbMassFlow, coolantDensity = densityLiPb);
      LossOfHeat lossOfHeat(heMassFlow = heStreamCalc.heMassFlow);
      GetterRegenHeating getterRegenHeating(heMassFlow = heStreamCalc.heMassFlow);
      PurgeHeGasCompression purgeHeGasCompression(tritiumMolFlow = tritiumBreedRate);
      //
      // Parameters and Variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      SI.Power totalPower "Total molten salt LiPb power (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (heGasComp.compressorEnergy + coolantPumping.coolantPumpPower + lossOfHeat.heatLoss + getterRegenHeating.getterHeatPower + purgeHeGasCompression.compressorEnergy) "W";
      //
    end LiPb_Power;

    model FliBe_Power
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumBreedRate(unit = "mol/s") "Imported from TritiumBreedingRate";
      //
      // Parameters
      parameter Real FLiBeMassFlow(unit = "kg/s") = 1500 "Flowrate of FLiBe coolant (kg/s)";
      parameter Real mrFLiBe(unit = "g/mol") = 35 "Molecular weight of FLiBe (g/mol)";
      parameter Real densityFLiBe(unit = "kg/m3") = 1940 "Density of FLiBe (kg/m3)";
      //
      // Instantiating Models
      HeStreamCalc heStreamCalc(tritiumBreedRate = tritiumBreedRate, coolantMolWeight = mrFLiBe, coolantMassFlow = FLiBeMassFlow);
      HeGasComp heGasComp(heMassFlow = heStreamCalc.heMassFlow);
      CoolantPumping coolantPumping(coolantMassFlow = FLiBeMassFlow, coolantDensity = densityFLiBe);
      LossOfHeat lossOfHeat(heMassFlow = heStreamCalc.heMassFlow);
      GetterRegenHeating getterRegenHeating(heMassFlow = heStreamCalc.heMassFlow);
      PurgeHeGasCompression purgeHeGasCompression(tritiumMolFlow = tritiumBreedRate);
      //
      // Parameters and Variables
      parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
      SI.Power totalPower "Total molten salt LiPb power (W)";
      //
    equation
      totalPower = 1000 * (1 + contingencyFactor) * (heGasComp.compressorEnergy + coolantPumping.coolantPumpPower + lossOfHeat.heatLoss + getterRegenHeating.getterHeatPower + purgeHeGasCompression.compressorEnergy) "W";
      //
    end FliBe_Power;

    model HeStreamCalc
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real tritiumBreedRate(unit = "mol/s") "As calculated in TritiumBreedingRate";
      Real coolantMolWeight(unit = "g/mol") "Molecular weight of coolant dependant on selected coolant (g/mol)";
      Real coolantMassFlow(unit = "kg/s") "Assumed coolant flowrate (kg/sec)";
      //
      // Variables
      Real coolantMolFlow(unit = "mol/s") "Coolant molar flowrate (mol/s)";
      Real tritiumMolConcIn(unit = "mol/mol") "Initial molar concentration of tritium (mol(T2)/mol(Coolant))";
      Real tritiumMolConcOut(unit = "mol/mol") "Outlet tritium molar concentration (mol(T2)/mol(Coolant))";
      Real heMolFlow(unit = "mol/s") "Outlet He flowrate (mol/sec)";
      Real heMassFlow(unit = "kg/s") "Mass flowrate of helium (kg/s)";
      //
    equation
      coolantMolFlow = 1000 * coolantMassFlow / coolantMolWeight;
      tritiumMolConcIn = tritiumBreedRate / coolantMolFlow;
      tritiumMolConcOut = tritiumMolConcIn * 100 "Relationship from Fukada et. al. !!NEEDS LOOKING INTO!!";
      heMolFlow = tritiumBreedRate / (tritiumMolConcOut + Modelica.Constants.eps);
      heMassFlow = heMolFlow * 4 / 1000;
    end HeStreamCalc;

    model HeGasComp
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real heMassFlow(unit = "kg/s") "Mass flow of air (kg/s), from AirGasFlowrate model";
      //
      // Parameters
      parameter Real mrHe(unit = "g/mol") = 4 "Molecular weight of helium (g/mol)";
      parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency";
      parameter Real pressureInlet(unit = "Pa") = 75E5 "Pressure at compressor inlet (Pa) [Assuming 5 bar dp across equipment]";
      parameter Real pressureOutlet(unit = "Pa") = 80E5 "Pressure at compressor outlet (Pa)";
      parameter Real tempInlet(unit = "K") = 593 "Temperature at compressor inlet (K)";
      parameter Real ratioCpCv(unit = "1") = 1.67 "Ratio of Cp/Cv at inlet conditions, based off CoolProp for helium";
      //
      // Variables
      Real idealCompressorWork(unit = "kJ/mol") "Ideal compressor work on mass basis (kJ/mol)";
      Real compressorEnergy(unit = "kW") "Compressor energy (kW)";
      //
    equation
      idealCompressorWork = 8.3145 * tempInlet * (ratioCpCv / (ratioCpCv - 1)) * ((pressureOutlet / pressureInlet) ^ ((ratioCpCv - 1) / ratioCpCv) - 1) / 1000 "Isentropic gas compression calculation on molar basis (kJ/mol)";
      compressorEnergy = idealCompressorWork * heMassFlow * 1000 / (mrHe * isentropicEfficiency) "kW";
    //
    end HeGasComp;

    model CoolantPumping
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real coolantMassFlow(unit = "kg/s");
      Real coolantDensity(unit = "kg/m3");
      //
      // Parameters
      parameter Real detritSystemdP(unit = "bar") = 1 "Pressure drop over the detrit system (bar)";
      parameter Real pumpEfficiency(unit = "1") = 0.9 "Pump efficiency";
      //
      // Variables
      Real coolantVolFlow(unit = "m3/s") "Volumetric flowrate of the coolant (m3/sec)";
      Real coolantPumpPower(unit = "kW") "Coolant pumping power (kW)";
      //
    equation
      coolantVolFlow = coolantMassFlow / coolantDensity;
      coolantPumpPower = coolantVolFlow * detritSystemdP * 10 ^ 5 / (1000 * pumpEfficiency);
    end CoolantPumping;

    model LossOfHeat
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real heMassFlow(unit = "kg/s") "Imported from HeStreamCalc (kg/s)";
      //
      // Parameters
      parameter Real tempDiff(unit = "K") = 20 "Temperature difference over the counter current interchanger (K)";
      parameter Real heHeatCapacity(unit = "kJ/kg") = 5.2 "Helium heat capacity, averaged over 300-700 deg C @ 80 bar (kJ/kg)";
      //
      // Variables
      Real heatLoss(unit = "kW") "Heat lost (kW)";
      //
    equation
      heatLoss = heMassFlow * heHeatCapacity * tempDiff;
    end LossOfHeat;

    model GetterRegenHeating
      //
      // Imported Parameters
      import SI = Modelica.Units.SI;
      Real heMassFlow(unit = "kg/s") "Helium mass flow rate (kg/s), imported from HeStreamCalc";
      //
      // Specified Parameters
      parameter Real getterSatCapacity(unit = "wt/wt") = 0.02 "Saturated getter tritium capacity (wt/wt%)";
      parameter Real getterOperatingTime(unit = "h") = 12 "Time taken between bed regenerations (hr)";
      parameter Real getterRegenTime(unit = "h") = 24 "Time taken for total bed regeneration, NOT including cooldown (hr)";
      parameter Real getterTempOperating(unit = "K") = 573 "Operating temperature of getter bed (K)";
      parameter Real getterTempRegen(unit = "K") = 873 "Regenerating temperature of getter bed (K)";
      parameter Real getterHeatCapacity(unit = "kJ/(kg.K)") = 0.4 "Getter material heat capacity (kJ/kg K)";
      //
      // Variables
      Real getterMass(unit = "kg") "Calulcated getter mass (kg)";
      Real getterHeatPower(unit = "kW") "Heat required to raise bed from operating to regenerating temperature (K)";
      // !!Size this based on GHSV?!!
    equation
      getterMass = heMassFlow * getterOperatingTime * 3600 / (1000 * getterSatCapacity) "Evaluates mass of getter material required for a given flow of tritium (kg)";
      getterHeatPower = getterMass * getterHeatCapacity * (getterTempRegen - getterTempOperating) / (getterRegenTime * 3600) "Energy required to heat the getter material to regen temperature (kW)";
    end GetterRegenHeating;

    model PurgeHeGasCompression
      // Requirement for purge stream dependant on confidence of normal helium stream to remove required tritium
      //
      // Imported Parameters
      Real tritiumMolFlow(unit = "mol/s") "Mass flow of air (mol/s), from TritiumBreedingRate";
      //
      // Parameters
      parameter Real mrHe(unit = "g/mol") = 4 "Molecular weight of helium (g/mol)";
      parameter Real tritiumConcOut(unit = "mol") = 100 "Tritium molar concentration at the outlet (mol-ppm)";
      parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency";
      parameter Real pressureInlet(unit = "Pa") = 1E5 "Pressure at compressor inlet (Pa)";
      parameter Real pressureOutlet(unit = "Pa") = 15E5 "Pressure at compressor outlet (Pa)";
      parameter Real tempInlet(unit = "K") = 293 "Temperature at compressor inlet (K)";
      parameter Real ratioCpCv(unit = "1") = 1.67 "Ratio of Cp/Cv at inlet conditions, based off CoolProp for helium";
      //
      // Variables
      Real hePurgeMassFlow(unit = "kg/s") "Mass flow rate of helium purge stream (kg/s)";
      Real idealCompressorWork(unit = "kJ/mol") "Ideal compressor work on mass basis (kJ/mol)";
      Real compressorEnergy(unit = "kW") "Compressor energy (kW)";
      //
    equation
      hePurgeMassFlow = mrHe * tritiumMolFlow * 1E6 / (tritiumConcOut * 1000);
      idealCompressorWork = 8.3145 * tempInlet * (ratioCpCv / (ratioCpCv - 1)) * ((pressureOutlet / pressureInlet) ^ ((ratioCpCv - 1) / ratioCpCv) - 1) / 1000 "Isentropic gas compression calculation on molar basis (kJ/mol)";
      compressorEnergy = idealCompressorWork * hePurgeMassFlow * 1000 / (mrHe * isentropicEfficiency) "kW";
      //
    end PurgeHeGasCompression;
  end MoltenSaltCoolants;
end CoolantDetrit;
