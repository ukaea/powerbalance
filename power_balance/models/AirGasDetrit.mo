package AirGasDetrit "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model AirGasPower
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    //
    // Instantiating models
    AirGasFlowrate airFlowrate(ThermalPower = ThermalPower);
    RecombinerHeat recombinerHeat(airMassFlow = airFlowrate.airMassFlow);
    CompFeedGas compFeedGas(airMassFlow = airFlowrate.airMassFlow);
    RegenBedHeating regenBedHeating(airVolFlow = airFlowrate.airVolFlow, airMassFlow = airFlowrate.airMassFlow);
    CompRegenGas compRegenGas(totalRegenBedHeating = regenBedHeating.totalRegenBedHeating, adsorbentTempOperating = regenBedHeating.adsorbentTempOperating, adsorbentTempRegen = regenBedHeating.adsorbentTempRegen);
    //
    // Parameters and variables
    parameter Real contingencyFactor(unit = "1") = 0.15 "Contingency factor (accounting for smaller loads such as pumps)";
    Real sumPower(unit = "kW") "Summation of all power users (kW)";
    Real ElecPowerConsumed(unit = "W") "Power consumed including contingency (W)";
    //
  equation
    sumPower = regenBedHeating.totalRegenBedHeating + compFeedGas.compressorEnergy + compRegenGas.compressorEnergy + compRegenGas.regenAirHeating + recombinerHeat.heatLoad;
    ElecPowerConsumed = 1E3 * (1 + contingencyFactor) * sumPower;
    //
    //Runtime Assertions
    assert(sumPower >= 0, "---> Assertion Error in [AirGasPower], variable [sumPower = "+String(sumPower)+"] cannot be negative!", level = AssertionLevel.error);
    assert(sumPower <= 1e5, "---> Assertion Warning in [AirGasPower], variable [sumPower = "+String(sumPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(ElecPowerConsumed >= sumPower, "---> Assertion Error in [AirGasPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] outside of acceptable range!", level = AssertionLevel.error);
    assert(ElecPowerConsumed <= 1e8, "---> Assertion Warning in [AirGasPower], variable [ElecPowerConsumed = "+String(sumPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end AirGasPower;

  model AirGasFlowrate
    //
    // Imported Parameters
    Real ThermalPower(unit = "MW") "Total high grade thermal power (MW)";
    //
    // Parameters
    Real airVolFlowConst(unit = "Nm3/h") = 3500 "Estimated volumetric flowrate scaled from ITER (Nm3/hr)";
    //
    // Variables
    Real airVolFlow(unit = "Nm3/h") "Acutal volumetric flow of air based on building scaling (Nm3/hr)";
    Real airMassFlow(unit = "kg/s") "Actual mass flow of air based on building scaling (kg/s)";
    //
  equation
    airVolFlow = (ThermalPower / 1000) ^ 0.6 * airVolFlowConst "Scales flow rate on building size (Nm3/hr) for thermal power in GW";
    airMassFlow = 1 / 3600 * airVolFlow * (28.97 / 1000) * 101325 / (8.3145 * 293.15) "Air flowrate (kg/s), assuming Mr air = 28.97 g/mol";
    //
    //Runtime Assertions
    assert(airMassFlow >= 0,"---> Assertion Error in [AirGasFlowrate], variable [airMassFlow = "+String(airMassFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(airMassFlow <= 100,"---> Assertion Warning in [AirGasFlowrate], variable [airMassFlow = "+String(airMassFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(airVolFlow >= 0,"---> Assertion Error in [AirGasFlowrate], variable [airVolFlow = "+String(airVolFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(airVolFlow <= 1e6,"---> Assertion Warning in [AirGasFlowrate], variable [airVolFlow = "+String(airVolFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end AirGasFlowrate;

  model RecombinerHeat
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real airMassFlow(unit = "kg/s") "Mass flowrate of air (kg/s), importing from AirGasFlowrate model";
    //
    // Specified Parameters
    parameter Real airTempIn(unit = "K") = 293 "Ambient temperature (K)";
    parameter Real recombinerTemp(unit = "K") = 773 "Temperature of recombiner operating temperature (K)";
    parameter Real airHeatCapacity(unit = "kJ/(kg.K)") = 1.05 "Heat capacity of air at inlet conditions (kJ/kg K)";
    //
    // Variables
    Real heatLoad(unit = "kW") "Heat load consumption (kW)";
    //
  equation
    heatLoad = airMassFlow * airHeatCapacity * (recombinerTemp - airTempIn) "kW";
    //
    //Runtime Assertions
    assert(heatLoad >= 0,"---> Assertion Error in [RecombinerHeat], variable [heatLoad = "+String(heatLoad)+"] cannot be negative!",level = AssertionLevel.error);
    assert(heatLoad <= 100,"---> Assertion Warning in [RecombinerHeat], variable [heatLoad = "+String(heatLoad)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end RecombinerHeat;

  model CompFeedGas
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real airMassFlow(unit = "kg/s") "Mass flow of air (kg/s), from AirGasFlowrate model";
    //
    // Parameters
    parameter Real isentropicEfficiency(unit = "1") = 0.85 "Isentropic efficiency";
    parameter Real pressureInlet(unit = "Pa") = 1E5 "Pressure at compressor inlet (Pa)";
    parameter Real pressureOutlet(unit = "Pa") = 20E5 "Pressure at compressor outlet (Pa)";
    parameter Real tempInlet(unit = "K") = 293 "Temperature at compressor inlet (K)";
    parameter Real ratioCpCv(unit = "1") = 1.40 "Ratio of Cp/Cv at inlet conditions, check when changing inlet conditions";
    parameter Real airMolWeight(unit = "g/mol") = 28.97;
    //
    // Variables
    Real idealCompressorWork(unit = "kJ/mol") "Ideal compressor work on mass basis (kJ/mol)";
    Real compressorEnergy(unit = "kW") "Compressor energy (kW)";
    //
  equation
    idealCompressorWork = 8.3145 * tempInlet * (ratioCpCv / (ratioCpCv - 1)) * ((pressureOutlet / pressureInlet) ^ ((ratioCpCv - 1) / ratioCpCv) - 1) / 1000 "Isentropic gas compression calculation on molar basis (kJ/mol)";
    compressorEnergy = idealCompressorWork * airMassFlow * 1000 / (airMolWeight * isentropicEfficiency) "kW";
    //
    //Runtime Assertions
    assert(idealCompressorWork >= 0,"---> Assertion Error in [CompFeedGas], variable [idealCompressorWork = "+String(idealCompressorWork)+"] cannot be negative!",level = AssertionLevel.error);
    assert(idealCompressorWork <= 20,"---> Assertion Warning in [CompFeedGas], variable [idealCompressorWork = "+String(idealCompressorWork)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(compressorEnergy >= 0,"---> Assertion Error in [CompFeedGas], variable [compressorEnergy = "+String(compressorEnergy)+"] cannot be negative!",level = AssertionLevel.error);
    assert(compressorEnergy <= 100,"---> Assertion Warning in [CompFeedGas], variable [compressorEnergy = "+String(compressorEnergy)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end CompFeedGas;

  model RegenBedHeating
    //
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real airVolFlow(unit = "Nm3/h") "Volumetric flowrate of air (Nm3/hr), imported from AirGasFlowrate";
    Real airMassFlow(unit = "kg/s") "Mass flowrate of air (kg/s), imported from AirGasFlowrate";
    //
    // Specified Parameters
    parameter Real adsorbentBedGHSV(unit = "1/h") = 6500 "Determines the relative bed size based on the Gas Hourly Space Velocity (GHSV = vol flow/reactor vol)";
    parameter Real adsorbentBulkDensity(unit = "kg/m3") = 705 "Packing density of the adsorbent when loaded (kg/m3) from manufacturer";
    parameter Real adsorbentSaturationCapacity(unit = "1") = 0.22 "3A Absorbent mol seive saturation capacity fraction (wt H2O/wt adsorbent)";
    parameter Real airPresIn(unit = "Pa") = 3E5 "Pressure of air from KOP (Pa)";
    parameter Real waterVapourPressure(unit = "Pa") = 0.1E5 "Water vapour @ 40°C (Pa)";
    parameter Real adsorbentRegenTime(unit = "h") = 1 "Time taken for bed heating and holding for complete regeneration (hours), NOT including cool down period";
    parameter Real adsorbentHeatCapacity(unit = "kJ/(kg.K)") = 1 "Mol sieve bed heat capacity (based on ceramic type absorbent heat capacity) (kJ/kg K)";
    parameter Real adsorbentTempOperating(unit = "K") = 298 "Adsorbent bed operating temperature (K)";
    parameter Real adsorbentTempRegen(unit = "K") = 573 "Adsorbent bed temperature for regneration (K)";
    parameter Real waterLatentHeatVaporisation(unit = "kJ/kg") = 2260 "Water latent heat of vapourisation (kJ/kg)";
    //
    // Variables
    Real waterMassFlow(unit = "kg/s") "Water flow in air (kg/s) based on building size and vapour pressure";
    Real waterVapMolFrac(unit = "1") "Vapour fraction of water in air at conditions";
    Real adsorbentDryMass(unit = "kg") "Absorbent mass per bed (kg)";
    Real adsorbentSatCapacity(unit = "kg") "Mass of adsorbed water at saturation (kg)";
    Real adsorbentHeating(unit = "kW") "Constant heating of ceramic energy (kW)";
    Real waterEvaporisation(unit = "kW") "Water evolving energy (kw)";
    Real totalRegenBedHeating(unit = "kW") "Total regen heating rate (kW)";
    //
    //
  equation
    // Regen Heating
    waterVapMolFrac = waterVapourPressure / airPresIn;
    waterMassFlow = airMassFlow * waterVapMolFrac * 18 / 28.97 "Mass flow of water in air (kg/s)";
    adsorbentDryMass = adsorbentBulkDensity * airVolFlow / adsorbentBedGHSV "Determines mass of bed adsorbent (kg)";
    adsorbentSatCapacity = adsorbentDryMass * adsorbentSaturationCapacity / (adsorbentRegenTime * 3600) "Determines mass of water adsorbed to adsorbent bed when saturated (kg)";
    adsorbentHeating = adsorbentDryMass * adsorbentHeatCapacity * (adsorbentTempRegen - adsorbentTempOperating) / (adsorbentRegenTime * 3600) "Determines the total power (kW) required for heating the adsorbent mass over a regen cycle";
    waterEvaporisation = waterLatentHeatVaporisation * adsorbentSatCapacity "Energy required to vaporise all water adsorbed (kW)";
    totalRegenBedHeating = waterEvaporisation + adsorbentHeating "kW";
    //
    //Runtime Assertions
    assert(waterMassFlow >= 0,"---> Assertion Error in [RegenBedHeating], variable [waterMassFlow = "+String(waterMassFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(waterMassFlow <= 1,"---> Assertion Warning in [RegenBedHeating], variable [waterMassFlow = "+String(waterMassFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(waterVapMolFrac >= 0,"---> Assertion Error in [RegenBedHeating], variable [waterVapMolFrac = "+String(waterVapMolFrac)+"] cannot be negative!",level = AssertionLevel.error);
    assert(waterVapMolFrac <= 0.9,"---> Assertion Warning in [RegenBedHeating], variable [waterVapMolFrac = "+String(waterVapMolFrac)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(adsorbentDryMass >= 0,"---> Assertion Error in [RegenBedHeating], variable [adsorbentDryMass = "+String(adsorbentDryMass)+"] cannot be negative!",level = AssertionLevel.error);
    assert(adsorbentDryMass <= 1e4,"---> Assertion Warning in [RegenBedHeating], variable [adsorbentDryMass = "+String(adsorbentDryMass)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(adsorbentSatCapacity >= 0,"---> Assertion Error in [RegenBedHeating], variable [adsorbentSatCapacity = "+String(adsorbentSatCapacity)+"] cannot be negative!",level = AssertionLevel.error);
    assert(adsorbentSatCapacity <= 0.25 * adsorbentDryMass,"---> Assertion Warning in [RegenBedHeating], variable [adsorbentSatCapacity = "+String(adsorbentSatCapacity)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(adsorbentHeating >= 0,"---> Assertion Error in [RegenBedHeating], variable [adsorbentHeating = "+String(adsorbentHeating)+"] cannot be negative!",level = AssertionLevel.error);
    assert(adsorbentHeating <= 1e3,"---> Assertion Warning in [RegenBedHeating], variable [adsorbentHeating = "+String(adsorbentHeating)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(waterEvaporisation >= 0,"---> Assertion Error in [RegenBedHeating], variable [waterEvaporisation = "+String(waterEvaporisation)+"] cannot be negative!",level = AssertionLevel.error);
    assert(waterEvaporisation <= 1e3,"---> Assertion Warning in [RegenBedHeating], variable [waterEvaporisation = "+String(waterEvaporisation)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(totalRegenBedHeating >= 0,"---> Assertion Error in [RegenBedHeating], variable [totalRegenBedHeating = "+String(totalRegenBedHeating)+"] cannot be negative!",level = AssertionLevel.error);
    assert(totalRegenBedHeating <= 1e3,"---> Assertion Warning in [RegenBedHeating], variable [totalRegenBedHeating = "+String(totalRegenBedHeating)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end RegenBedHeating;

  model CompRegenGas
    //
    //Imported Parameters
    import SI = Modelica.SIunits;
    Real totalRegenBedHeating(unit = "kW") "Energy regquired to vaoporise adsorbed water and heat adsorber bed, imported from RegenBedHeating";
    Real adsorbentTempOperating(unit = "K") "Adsorbent bed operating temperature (K), imported from RegenBedHeating";
    Real adsorbentTempRegen(unit = "K") "Adsorbent bed temperature for regneration (K), imported from RegenBedHeating";
    //
    // Specified Parameters (assuming air as regen medium)
    parameter Real airExcessAmount(unit = "percent") = 10 "Percent of excess air for regeneration";
    parameter Real airSpecificHeat(unit = "kJ/(kg.K)") = 1.05;
    parameter Real airTempCompInlet(unit = "K") = 293 "Temperature of regen air at the compressor inlet (K)";
    parameter Real airRatioCpCv(unit = "1") = 1.40 "Ratio of specific heat capacities (Cp/Cv) at inlet conditions";
    parameter Real airPressureInlet(unit = "Pa") = 1E5 "Pressure of air at compressor inlet (Pa)";
    parameter Real airPressureOutlet(unit = "Pa") = 6E5 "Pressure of air at compressor outlet (Pa)";
    parameter Real airMolWeight(unit = "g/mol") = 28.97;
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
    regenAirMassFlow = (100 + airExcessAmount) / 100 * totalRegenBedHeating / (airSpecificHeat * (adsorbentTempRegen - adsorbentTempOperating)) "m = Q/Cp.dT, where Q is total energy required for regen heating calculated in previous model";
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
    assert(regenAirMassFlow >= 0,"---> Assertion Error in [CompRegenGas], variable [regenAirMassFlow = "+String(regenAirMassFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(regenAirMassFlow <= 50,"---> Assertion Warning in [CompRegenGas], variable [regenAirMassFlow = "+String(regenAirMassFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(compressorWork >= 0,"---> Assertion Error in [CompRegenGas], variable [compressorWork = "+String(compressorWork)+"] cannot be negative!",level = AssertionLevel.error);
    assert(compressorWork <= 20,"---> Assertion Warning in [CompRegenGas], variable [compressorWork = "+String(compressorWork)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(compressorEnergy >= 0,"---> Assertion Error in [CompRegenGas], variable [compressorEnergy = "+String(compressorEnergy)+"] cannot be negative!",level = AssertionLevel.error);
    assert(compressorEnergy <= 100,"---> Assertion Warning in [CompRegenGas], variable [compressorEnergy = "+String(compressorEnergy)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(regenAirHeating >= 0,"---> Assertion Error in [CompRegenGas], variable [regenAirHeating = "+String(regenAirHeating)+"] cannot be negative!",level = AssertionLevel.error);
    assert(regenAirHeating <= 1e3,"---> Assertion Warning in [CompRegenGas], variable [regenAirHeating = "+String(regenAirHeating)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(airTempCompOut >= 0,"---> Assertion Error in [CompRegenGas], variable [airTempCompOut = "+String(airTempCompOut)+"] cannot be negative!",level = AssertionLevel.error);
    assert(airTempCompOut <= 500,"---> Assertion Warning in [CompRegenGas], variable [airTempCompOut = "+String(airTempCompOut)+"] outside of reasonable range!",level = AssertionLevel.warning);
  end CompRegenGas;
end AirGasDetrit;
