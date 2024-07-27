package VacuumPump "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model VacuumPumpPower
    //
    import SI = Modelica.Units.SI;
    //
    // Instantiating models
    Pump_Turbo turboPump(thermalPowerOut = thermalPowerData) if vacuumType == "turbo";
    Pump_Booster1 boosterPump1(thermalPowerOut = thermalPowerData) if vacuumType == "turbo";
    Pump_Booster2 boosterPump2(thermalPowerOut = thermalPowerData) if vacuumType == "turbo";
    Pump_Screw screwPump(thermalPowerOut = thermalPowerData) if vacuumType == "turbo";
    //
    CryoPump cryoPump if vacuumType == "cryo";
    //
    parameter String vacuumType "'cryo' or 'turbo'";
    SI.Power ElecPowerConsumed;
    //
    // Parameters and variables
    parameter Real contingencyFactor(unit = "1") = 0.5 "Contingency factor";
    parameter String thermalPowerData;
    SI.Power totalContingency "Total contingency from previous 4 models (W)";
    SI.Power totalTurbopumpPower "Total TurboPumpPower (W)";
    //
  equation
    totalContingency =  if vacuumType == "turbo" then (turboPump.powerPump + boosterPump1.powerPump + boosterPump2.powerPump + screwPump.powerPump) else 0;
    totalTurbopumpPower =  if vacuumType == "turbo" then (1 + contingencyFactor) * totalContingency else 0 "W";
    //
    ElecPowerConsumed = if vacuumType == "turbo" then totalTurbopumpPower else cryoPump.ElecTotalPower;
    //
    // Runtime Assertions
    assert(totalContingency >= 0, "---> Assertion Error in [TurboPumpPower], variable [totalContingency = "+String(totalContingency)+"] cannot be negative!", level = AssertionLevel.error);
    assert(totalContingency<= 1e8, "---> Assertion Warning in [TurboPumpPower], variable [totalContingency = "+String(totalContingency)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(totalTurbopumpPower >= totalContingency, "---> Assertion Error in [TurboPumpPower], variable [totalTurbopumpPowerl = "+String(totalTurbopumpPower)+"] outside of acceptable range!", level = AssertionLevel.error);
    assert(totalTurbopumpPower <= 1e8, "---> Assertion Warning in [TurboPumpPower], variable [totalTurbopumpPower = "+String(totalTurbopumpPower)+"] outside of reasonable range!", level = AssertionLevel.warning);
    assert(ElecPowerConsumed >= 0, "---> Assertion Error in [TurboPumpPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] cannot be negative!", level = AssertionLevel.error);
    assert(ElecPowerConsumed <= 1e8, "---> Assertion Warning in [TurboPumpPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] outside of reasonable range!", level = AssertionLevel.warning);
  end VacuumPumpPower;

  partial model BaseTurboPump
    //
    import SI = Modelica.Units.SI;
    //
    // Data Import - Required funtion to import .mat file containing power profile
    import Modelica.Blocks.Sources.CombiTimeTable;
    Modelica.Blocks.Sources.CombiTimeTable combiTimeTable1D(fileName = thermalPowerOut, tableOnFile = true, tableName = "data");
    //
    // Parameters
    parameter String thermalPowerOut;
    Real ThermalPower(unit = "GW") = combiTimeTable1D.y[1] / 1e9 "Total high grade heat. Equated to thermal power into primary coolant loop. Input should be in W, scaled to GW";
    parameter SI.Temperature gasTemperature "Gas temperature (K)";
    parameter Real gasFlowComponent(unit = "mol/(s.GW)") "Total gas flow per component per GW thermal (mol/s GW)";
    parameter Real pressure(unit = "mbar") "Inlet/divertor pressure (mbar)";
    parameter SI.VolumeFlowRate pumpSpeed "Single booster pump speed (m3/sec)";
    parameter SI.Power pumpEnergy "Single turbomolecular pump energy (W)";
    //
    // Variables
    SI.MolarFlowRate totalGasFlow "Total gas flow";
    SI.VolumeFlowRate reqFlowrate "Required flowrate (m3/sec)";
    SI.Power powerPump "Turbo power (W)";
    //
  equation
    totalGasFlow = gasFlowComponent * ThermalPower;
    reqFlowrate = totalGasFlow * 8.314 * gasTemperature / (pressure * 100);
    powerPump = 1e3 * pumpEnergy * 0.001 * (reqFlowrate / pumpSpeed) "W";
    //
    //Runtime Assertions
    assert(totalGasFlow >= 0,"---> Assertion Error in [BasePump], variable [totalGasFlow = "+String(totalGasFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(totalGasFlow <= 100,"---> Assertion Warning in [BasePump], variable [totalGasFlow = "+String(totalGasFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(reqFlowrate >= 0,"---> Assertion Error in [BasePump], variable [reqFlowrate = "+String(reqFlowrate)+"] cannot be negative!",level = AssertionLevel.error);
    assert(reqFlowrate <= 100,"---> Assertion Warning in [BasePump], variable [reqFlowrate = "+String(reqFlowrate)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(powerPump >= 0,"---> Assertion Error in [BasePump], variable [powerPump = "+String(powerPump)+"] cannot be negative!",level = AssertionLevel.error);
    assert(powerPump <= 1e8,"---> Assertion Warning in [BasePump], variable [powerPump = "+String(powerPump)+"] outside of reasonable range!",level = AssertionLevel.warning);

  end BaseTurboPump;

  model Pump_Turbo
    extends BaseTurboPump(
      gasTemperature = 873,
      gasFlowComponent = 0.04,
      pressure = 0.005,
      pumpSpeed = 5,
      pumpEnergy = 600);
  equation

  end Pump_Turbo;

  model Pump_Booster1
    extends BaseTurboPump(
    gasTemperature = 873,
    gasFlowComponent = 0.04,
    pressure = 0.2,
    pumpSpeed = 1,
    pumpEnergy = 9000);
  equation

  end Pump_Booster1;

  model Pump_Booster2
    extends BaseTurboPump(
      gasTemperature = 873,
      gasFlowComponent = 0.04,
      pressure = 2,
      pumpSpeed = 0.5,
      pumpEnergy = 3300);
  equation

  end Pump_Booster2;

  model Pump_Screw
    extends BaseTurboPump(
      gasTemperature = 873,
      gasFlowComponent = 0.04,
      pressure = 10,
      pumpSpeed = 0.1,
      pumpEnergy = 22000);
  equation

  end Pump_Screw;

  model CryoPump "A model to simulate a cryopump operation"
    //
    import SI = Modelica.Units.SI;
    import NonSI = Modelica.Units.NonSI;
    //
    // Parameters
    parameter SI.Temperature gasTemperature = 873 "Assumption of gas SI.Temperature being 873K";
    parameter Real R(unit = "m3.mbar/(K.mol)") = 8.31e-2 "Assumption of the Universal Gas constant of 8.31e-2 (m3 mbar k-1 mol-1)";
    parameter SI.MolarFlowRate Deuterium_MolarRate_Ini = 0.02 "Initial injected Deutrium mol flow (mol/s)";
    parameter SI.MolarFlowRate Tritium_MolarRate_Ini = 0.02 "Initial injected Tritium mol flow (mol/s)";
    parameter SI.MolarFlowRate Argon_MolarRate = 0;
    parameter SI.MolarFlowRate Helium_4_MolarRate = 0.0005 "He-4 from burn fraction of T2";
    parameter Real Cp(unit = "J/(g.K)") = 14.3 "Specific heat J/(g K) |OF WHAT?|";
    parameter Real heatFusion(unit = "J/mol") = 58.7 "Heat of fusion J/mol";
    parameter Real heatVapourisation(unit = "J/mol") = 449.4 "Heat of vapourisation J/mol";
    parameter Real Deuterium_MolWeight(unit = "g/mol") = 4 "4g/mol molecular Deutrium weight";
    parameter Real Tritium_MolWeight(unit = "g/mol") = 6 "6g/mol molecular Tritium weight";
    parameter SI.Temperature DeuteriumTemperature_High = 120 "High temperature (K)";
    parameter SI.Temperature TritiumTemperature_High = 120 "High temperature (K)";
    parameter SI.Temperature DeuteriumTemperature_Low = 20 "Low temperature (K)";
    parameter SI.Temperature TritiumTemperature_Low = 20 "Low temperature (K)";
    parameter Real Tritium_TotalWeight(unit = "g") = 120 "120g of Tritium (Same inventory limit as ITER)";
    parameter Real P1(unit = "mbar") = 1 "Value for regeneration from ITER (mbar)";
    parameter Real Q(unit = "mbar.m3/s") = 2 "Value for regeneration from ITER (mbar m^3/s)";
    parameter Real P2(unit = "mbar") = 1e-6 "(mbar)";
    parameter SI.VolumeFlowRate S1 = 2 "Volume flow rate (m^3/s)";
    parameter SI.VolumeFlowRate S2 = 6 "Volume flow rate  (m^3/s)";
    parameter SI.Power powerConsumed_1 = 1000 "The power consumed during regeneration by a 8000 l/s ";
    parameter SI.Power power_BasePressure = 500 "Power of running 2 more 8000 l/s at base pressure (500 Watt)";
    parameter SI.Power powerConsumed_2 = 9000 "The power consumption at 0.1 mbar is estimated to be around 9000 Watt";
    parameter SI.Power powerConsumed_3 = 2300 "The power consumption at 0.1 mbar is estimated to be around 2300 Watt";
    parameter SI.Power powerConsumed_4 = 7000 "The power consumption for one 650 m3/hr between 0.1 and 8 mbar is about 7000 Watt";
    //
    // Variables
    SI.MolarFlowRate Deuterium_99percentFlow "Deutrium at a flow rate of 99%";
    SI.MolarFlowRate Tritium_99percentFlow "Tritium at a flow rate of 99%";
    SI.MolarFlowRate cryopumpTrap "Trapped by a cryo pump (mol/s)";
    SI.MolarFlowRate injectedComponentFlow "Injected component mole flow, (mol/s)";
    NonSI.MassFlowRate_gps DeuteriumMassFlow "Mass flow rate of D2 ";
    NonSI.MassFlowRate_gps TritiumMassFlow "Mass flow rate of T2";
    SI.Temperature tempChange_Deuterium "Change in temperature in Deutrium (K)";
    SI.Temperature tempChange_Tritium "Change in temperature in Tritium (K)";
    SI.Power Cp_energyChange_Deuterium "Energy change specific heat in Deutrium (J/s)";
    SI.Power Cp_energyChange_Tritium "Energy change specific heat in Tritium (J/s)";
    SI.Power fusionHeat_energyChange_Deuterium "Heat of fusion in Deutrium (J/s)";
    SI.Power fusionHeat_energyChange_Tritium "Heat of fusion in Tritium (J/s)";
    SI.Power vapourisationHeat_Deuterium "Heat of vapourisation in Deutrium (J/s)";
    SI.Power vapourisationHeat_Tritium "Heat of vapourisation in Tritium (J/s)";
    SI.Power thermalLoad_Deuterium "Thermal load at 4K in Deutrium (J/s)";
    SI.Power thermalLoad_Tritium "Thermal load at 4K in Tritium (J/s)";
    SI.Power cryogenicLoad_Deuterium "Cryogenic load in Deutrium (J/s)";
    SI.Power cryogenicLoad_Tritium "Cryogenic load in Tritium (J/s)";
    SI.Power totalCryogenicLoad "Total croygenic load (J/s)";
    SI.Power contCryogenicLoad "To ensure continuous cryo pump power consumption, miniumum of 2 sets are required";
    Real DeuteriumMass_ITER(unit = "g", min = 0) "Deutrium mass over the pump cycle (g) ";
    SI.AmountOfSubstance DeuteriumMolWeight_ITER "Deutrium molecular weight (mol)";
    Real TritiumMass_ITER(unit = "g", min = 0) "Tritium mass over the pump cycle (g) ";
    SI.AmountOfSubstance TritiumMolWeight_ITER "Tritium molecular weight (mol)";
    SI.AmountOfSubstance totalMolWeight "Deutrium and Tritium added together (mol)";
    SI.Volume gasVolume_ITER "Volume from the Ideal gas law PV = nRT (m^3)";
    SI.Time timeCVC_S1_ITER "Time for ITER CVC pumping speed at S1 t=V/S1*ln(P1/P2)(s)";
    SI.Time timeCVC_S2_ITER "Time for ITER CVC pumping speed at S2 t=V/S2*ln(P1/P2)(s)";
    SI.Time cryopumpTimeIncrease "Time for the cryopump to increase (s)";
    SI.Power totalPower_1 "Assuming the power consumed during regeneration by a 8000 l/s is about 1000 watts plus the power of running 2 more 8000 l/s at base pressure (500 Watt)";
    SI.Power totalPower_2 "The power consumption at 0.1 mbar is estimated to be around 9000 Watt. Because 3 boosters are required";
    SI.Power totalPower_3 "The power consumption at 0.1 mbar is estimated to be around 2300 Watt. The power from 3 off 2000 m3/hr";
    SI.Power totalPower_4 "The power consumption for one 650 m3/hr between 0.1 and 8 mbar is about 7000 Watt. Because 3 roughing pumps would be required";
    SI.Power ElecTotalPower "Total powers added up (W)";
    //
  equation
    Deuterium_99percentFlow = Deuterium_MolarRate_Ini * 0.99 "Deuterium at a flow rate of 99%";
    Tritium_99percentFlow = Tritium_MolarRate_Ini * 0.99 "Tritium at a flow rate of 99%";
    cryopumpTrap = Tritium_99percentFlow + Deuterium_99percentFlow "Trapped by a cryo pump (mol/s)";
    injectedComponentFlow = Argon_MolarRate + Helium_4_MolarRate + Tritium_MolarRate_Ini + Deuterium_MolarRate_Ini "Injected component mole flow, (mol/s)";
    DeuteriumMassFlow = Deuterium_99percentFlow * Deuterium_MolWeight "Mass flow rate of Deuterium g/s";
    TritiumMassFlow = Tritium_99percentFlow * Tritium_MolWeight "Mass flow rate of Tritium g/s";
    tempChange_Deuterium = DeuteriumTemperature_High - DeuteriumTemperature_Low "Change in temperature in Deutrium (K)";
    tempChange_Tritium = TritiumTemperature_High - TritiumTemperature_Low "Change in temperature in Tritium (K)";
    Cp_energyChange_Deuterium = DeuteriumMassFlow * tempChange_Deuterium * Cp "Energy change in specific heat in Deutrium (J/s)";
    Cp_energyChange_Tritium = TritiumMassFlow * tempChange_Tritium * Cp "Energy change in specific heat in Deutrium (J/s)";
    fusionHeat_energyChange_Deuterium = Deuterium_99percentFlow * heatFusion "Heat of fusion in Deutrium (J/s)";
    fusionHeat_energyChange_Tritium = Tritium_99percentFlow * heatFusion "Heat of fusion in Tritium (J/s)";
    vapourisationHeat_Deuterium = heatVapourisation * Deuterium_99percentFlow "Heat of vapourisation in Deutrium (J/s)";
    vapourisationHeat_Tritium = heatVapourisation * Tritium_99percentFlow "Heat of vapourisation in Tritium (J/s)";
    thermalLoad_Deuterium = Cp_energyChange_Deuterium + fusionHeat_energyChange_Deuterium + vapourisationHeat_Deuterium "Thermal load at 4K in Deutrium (J/s)";
    thermalLoad_Tritium = Cp_energyChange_Tritium + fusionHeat_energyChange_Tritium + vapourisationHeat_Tritium "Thermal load at 4K in Tritium (J/s)";
    cryogenicLoad_Deuterium = thermalLoad_Deuterium * 230 "Cryogenic load in Deutrium (J/s)";
    cryogenicLoad_Tritium = thermalLoad_Tritium * 230 "Cryogenic load in Tritium (J/s)";
    totalCryogenicLoad = cryogenicLoad_Deuterium + cryogenicLoad_Tritium "Total cryogenic load (W)";
    cryopumpTimeIncrease = Tritium_TotalWeight / TritiumMassFlow "Time to increase the cryo pump inventory for each pump has max of 60g Tritium";
    contCryogenicLoad = 2 * totalCryogenicLoad "To ensure continuous cryo pump power consumption, miniumum of 2 sets are required (W)";
    DeuteriumMass_ITER = DeuteriumMassFlow * cryopumpTimeIncrease "Deutrium mass over the pump cycle (g)";
    DeuteriumMolWeight_ITER = DeuteriumMass_ITER / Deuterium_MolWeight "Deutrium molecular weight (mol)";
    TritiumMass_ITER = TritiumMassFlow * cryopumpTimeIncrease "Tritium mass over the pump cycle (g)";
    TritiumMolWeight_ITER = TritiumMass_ITER / Tritium_MolWeight "Tritium molecular weight (mol)";
    totalMolWeight = DeuteriumMolWeight_ITER + TritiumMolWeight_ITER "Deutrium and Tritium added together (mol)";
    gasVolume_ITER = totalMolWeight * 0.0831 * 120 / P1 "Volume from the Ideal gas law PV = nRT (m^3)";
    timeCVC_S1_ITER = gasVolume_ITER / S1 * log(P1 / P2) "Time for ITER CVC pumping speed t=V/S1*ln(P1/P2)(s)";
    timeCVC_S2_ITER = gasVolume_ITER / S2 * log(P1 / P2) "Time for ITER CVC pumping speed t=V/S2*ln(P1/P2)(s)";
    totalPower_1 = powerConsumed_1 + 3 * power_BasePressure "Assuming the power consumed during regeneration by a 8000 l/s is about 1000 watts plus the power of running 2 more 8000 l/s at base pressure (500 Watt)";
    totalPower_2 = 3 * powerConsumed_2 "The power consumption at 0.1 mbar is estimated to be around 9000 Watt. Because 3 booster are required";
    totalPower_3 = 3 * powerConsumed_3 "The power consumption at  0.1 mbar is estimated to be around 2300 Watt. The power from 3 off 2000 m3/hr";
    totalPower_4 = 3 * powerConsumed_4 "The power consumption for one 650 m3/hr  between 0.1 and 8 mbar is about 7000 Watt. Because 3 roughing pumps are required";
    //
    ElecTotalPower = contCryogenicLoad + totalPower_1 + totalPower_2 + totalPower_3 + totalPower_4 "Total powers added up (W). Total power is electrical";
    //
    // Runtime Assertions
    assert(ElecTotalPower >= 0, "---> Assertion Error in [CryoPump], variable [ElecTotalPower = " + String(ElecTotalPower) + "] cannot be negative!", level = AssertionLevel.error);
    assert(ElecTotalPower <= 1e8, "---> Assertion Warning in [CryoPump], variable [ElecTotalPower = " + String(ElecTotalPower) + "] outside of reasonable range!", level = AssertionLevel.warning);
  end CryoPump;

end VacuumPump;
