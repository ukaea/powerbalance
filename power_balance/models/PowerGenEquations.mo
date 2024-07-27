package PowerGenEquations "The efficiency values used in the power generation model are derived from a separate Excel model produced by UKAEA. 
This Excel model was built on a body of work produced by the Nuclear Advanced Manufacturing Research Centre and EGB Engineering for UKAEA titled 
'UKAEA STEP WP11: FEASIBILITY STUDY OF MODULAR REACTOR DESIGNS (LOT 2): FEASIBILITY OF ADVANCED NUCLEAR TECHNOLOGIES BALANCE OF PLANT (BOP)'

DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct.

"
  model PowerGenCaseByCase
    //
    import SI = Modelica.Units.SI;
    //  parameter String PrimaryCoolantType = CoolantDetrit.CoolantDetritCaseByCase.__PrimaryCoolantType;
    parameter String PrimaryCoolantType = "He_C";
    parameter String SecondaryCoolantType = "CO2";
    parameter String RatioType = "2.5";
    parameter String SystemPressure = "200";
    parameter Real powergenOutletTemp = 456 "Degrees Celsius; STRUCTURAL_PARAMETER";
    parameter String thermalPowerData;
    parameter Boolean __usePowergenEffValue = false "Set to true to use an efficiency value, false to use the model";
    parameter Real __powergenEff = 0.45 "Efficiency value for the powegen models";
    //
    // Instantiating Models
    PowerGen_CO2 PowerGenCO2(SecondaryCoolantType = SecondaryCoolantType, RatioType = RatioType, SystemPressure = SystemPressure, outletTemp = powergenOutletTemp, thermalPowerData = thermalPowerData) if PrimaryCoolantType == "CO2_C" or PrimaryCoolantType == "CO2_NC";
    PowerGen_He PowerGenHe(SecondaryCoolantType = SecondaryCoolantType, RatioType = RatioType, SystemPressure = SystemPressure, outletTemp = powergenOutletTemp, thermalPowerData = thermalPowerData) if PrimaryCoolantType == "He_C" or PrimaryCoolantType == "He_NC";
    PowerGen_SubCritWater PowerGenSubCritWater(SecondaryCoolantType = SecondaryCoolantType, RatioType = RatioType, SystemPressure = SystemPressure, outletTemp = powergenOutletTemp, thermalPowerData = thermalPowerData) if PrimaryCoolantType == "H2O";
    PowerGen_FliBe PowerGenFliBe(SecondaryCoolantType = SecondaryCoolantType, RatioType = RatioType, SystemPressure = SystemPressure, outletTemp = powergenOutletTemp, thermalPowerData = thermalPowerData) if PrimaryCoolantType == "FLiBe";
    PowerGen_LiPb PowerGenLiPb(SecondaryCoolantType = SecondaryCoolantType, RatioType = RatioType, SystemPressure = SystemPressure, outletTemp = powergenOutletTemp, thermalPowerData = thermalPowerData) if PrimaryCoolantType == "LiPb";
    //
    // Variables
    SI.Power ElecPowerGen "total electrical SI.Power generated";
    //
  initial equation
    // Input Parameter Assertions
    assert(PrimaryCoolantType == "H2O" or PrimaryCoolantType == "CO2_NC" or PrimaryCoolantType == "He_NC" or PrimaryCoolantType == "CO2_C" or PrimaryCoolantType == "He_C" or PrimaryCoolantType == "FLiBe" or PrimaryCoolantType == "LiPb", "---> Illegal value for PrimaryCoolantType", level = AssertionLevel.error);
    assert(SecondaryCoolantType == "H2O" or SecondaryCoolantType == "CO2", "---> Illegal value for SecondaryCoolantType", level = AssertionLevel.error);
    assert(RatioType == "1.5" or RatioType == "2" or RatioType == "2.5", "---> Illegal value for RatioType", level = AssertionLevel.error);
    assert(SystemPressure == "50" or SystemPressure == "90" or SystemPressure == "200", "---> Illegal value for SystemPressure", level = AssertionLevel.error);
    assert(__powergenEff > 0 and __powergenEff <= 1, "---> Illegal value for powergenEff", level = AssertionLevel.error);
    //
  equation
    ElecPowerGen =
     if PrimaryCoolantType == "H2O" then (if __usePowergenEffValue then (PowerGenSubCritWater.ThermalPower * __powergenEff) else PowerGenSubCritWater.powerGenerated)
     elseif PrimaryCoolantType == "CO2_NC" then (if __usePowergenEffValue then (PowerGenCO2.ThermalPower * __powergenEff) else PowerGenCO2.powerGenerated)
     elseif PrimaryCoolantType == "He_NC" then (if __usePowergenEffValue then (PowerGenHe.ThermalPower * __powergenEff) else PowerGenHe.powerGenerated)
     elseif PrimaryCoolantType == "CO2_C" then (if __usePowergenEffValue then (PowerGenCO2.ThermalPower * __powergenEff) else PowerGenCO2.powerGenerated)
     elseif PrimaryCoolantType == "He_C" then (if __usePowergenEffValue then (PowerGenHe.ThermalPower * __powergenEff) else PowerGenHe.powerGenerated)
     elseif PrimaryCoolantType == "FLiBe" then (if __usePowergenEffValue then (PowerGenFliBe.ThermalPower * __powergenEff) else PowerGenFliBe.powerGenerated)
     elseif PrimaryCoolantType == "LiPb" then (if __usePowergenEffValue then (PowerGenLiPb.ThermalPower * __powergenEff) else PowerGenLiPb.powerGenerated)
     else -1;
    //
    // Runtime Asstertions
    assert(ElecPowerGen >= 0, "---> Power generation cannot be negative! Most likely the outletTemp is not allowed with the specified system parameters. Double check the specified parameters and whether they can work together", level = AssertionLevel.error);
  end PowerGenCaseByCase;

  partial model BasePowerGen
    //
    import SI = Modelica.Units.SI;
    import NonSI = Modelica.Units.NonSI;
    //
    parameter String thermalPowerData;
    //
    // Data Import - Required funtion to import .mat file containing power profile
    import Modelica.Blocks.Sources.CombiTimeTable;
    Modelica.Blocks.Sources.CombiTimeTable combiTimeTable1D(fileName = thermalPowerData, tableOnFile = true, tableName = "data");
    //
    SI.Power ThermalPower = combiTimeTable1D.y[1] "Total high grade heat. Equated to thermal power in to primary coolant loop";
    parameter NonSI.Temperature_degC outletTemp "Outlet temperature start point (C)";
    //
    // Setting parameter strings for if statements
    parameter String SecondaryCoolantType = "";
    parameter String RatioType = "";
    parameter String SystemPressure = "";
    //
    // CO2 Secondary Coolant
    Real efficiencyCO2_1_5(unit = "1") "Efficiency of the CO2 secondary coolant with a compression ratio of 1.5";
    Real efficiencyCO2_2(unit = "1") "Efficiency of the CO2 secondary coolant with a compression ratio of 2";
    Real efficiencyCO2_2_5(unit = "1") "Efficiency of the CO2 secondary coolant with a compression ratio of 2.5";
    //
    // Water Secondary Coolant
    Real efficiencyH2O_50(unit = "1") "Efficiency of the H2O secondary coolant with a system pressure of 50";
    Real efficiencyH2O_90(unit = "1") "Efficiency of the H2O secondary coolant with a system pressure of 90";
    Real efficiencyH2O_200(unit = "1") "Efficiency of the H2O secondary coolant with a system pressure of 200";
    //
    // Power
    SI.Power powerCO2_1_5 "Power from outletTemp";
    SI.Power powerCO2_2 "Power from outletTemp";
    SI.Power powerCO2_2_5 "Power from outletTemp";
    SI.Power powerH2O_50 "Power from outletTemp";
    SI.Power powerH2O_90 "Power from outletTemp";
    SI.Power powerH2O_200 "Power from outletTemp";
    SI.Power powerGenerated;
    //
    // Polynomial coefficients
    // ax^4 + bx^3 + cx^2 + dx + e
    constant Real a_CO2_1_5(unit = "1/K4");
    constant Real b_CO2_1_5(unit = "1/K3");
    constant Real c_CO2_1_5(unit = "1/K2");
    constant Real d_CO2_1_5(unit = "1/K");
    constant Real e_CO2_1_5(unit = "1");
    //
    constant Real a_CO2_2(unit = "1/K4");
    constant Real b_CO2_2(unit = "1/K3");
    constant Real c_CO2_2(unit = "1/K2");
    constant Real d_CO2_2(unit = "1/K");
    constant Real e_CO2_2(unit = "1");
    //
    constant Real a_CO2_2_5(unit = "1/K4");
    constant Real b_CO2_2_5(unit = "1/K3");
    constant Real c_CO2_2_5(unit = "1/K2");
    constant Real d_CO2_2_5(unit = "1/K");
    constant Real e_CO2_2_5(unit = "1");
    //
    constant Real a_H2O_50(unit = "1/K4");
    constant Real b_H2O_50(unit = "1/K3");
    constant Real c_H2O_50(unit = "1/K2");
    constant Real d_H2O_50(unit = "1/K");
    constant Real e_H2O_50(unit = "1");
    //
    constant Real a_H2O_90(unit = "1/K4");
    constant Real b_H2O_90(unit = "1/K3");
    constant Real c_H2O_90(unit = "1/K2");
    constant Real d_H2O_90(unit = "1/K");
    constant Real e_H2O_90(unit = "1");
    //
    constant Real a_H2O_200(unit = "1/K4");
    constant Real b_H2O_200(unit = "1/K3");
    constant Real c_H2O_200(unit = "1/K2");
    constant Real d_H2O_200(unit = "1/K");
    constant Real e_H2O_200(unit = "1");
    //
    // Reference temperatures
    constant NonSI.Temperature_degC refTemp_CO2_1_5_min;
    constant NonSI.Temperature_degC refTemp_CO2_2_min;
    constant NonSI.Temperature_degC refTemp_CO2_2_5_min;
    //
    constant NonSI.Temperature_degC refTemp_H2O_50_min;
    constant NonSI.Temperature_degC refTemp_H2O_90_min;
    constant NonSI.Temperature_degC refTemp_H2O_200_min;
    //
    constant NonSI.Temperature_degC refTemp_CO2_1_5_max;
    constant NonSI.Temperature_degC refTemp_CO2_2_max;
    constant NonSI.Temperature_degC refTemp_CO2_2_5_max;
    //
    constant NonSI.Temperature_degC refTemp_H2O_50_max;
    constant NonSI.Temperature_degC refTemp_H2O_90_max;
    constant NonSI.Temperature_degC refTemp_H2O_200_max;
    //
  equation
    // Efficiencies
    efficiencyCO2_1_5 = a_CO2_1_5 * outletTemp ^ 4 + b_CO2_1_5 * outletTemp ^ 3 - c_CO2_1_5 * outletTemp ^ 2 + d_CO2_1_5 * outletTemp - e_CO2_1_5;
    efficiencyCO2_2 = a_CO2_2 * outletTemp ^ 4 + b_CO2_2 * outletTemp ^ 3 - c_CO2_2 * outletTemp ^ 2 + d_CO2_2 * outletTemp - e_CO2_2;
    efficiencyCO2_2_5 = a_CO2_2_5 * outletTemp ^ 4 + b_CO2_2_5 * outletTemp ^ 3 - c_CO2_2_5 * outletTemp ^ 2 + d_CO2_2_5 * outletTemp - e_CO2_2_5;
    //
    efficiencyH2O_50 = a_H2O_50 * outletTemp ^ 4 + b_H2O_50 * outletTemp ^ 3 - c_H2O_50 * outletTemp ^ 2 + d_H2O_50 * outletTemp - e_H2O_50;
    efficiencyH2O_90 = a_H2O_90 * outletTemp ^ 4 + b_H2O_90 * outletTemp ^ 3 - c_H2O_90 * outletTemp ^ 2 + d_H2O_90 * outletTemp - e_H2O_90;
    efficiencyH2O_200 = a_H2O_200 * outletTemp ^ 4 + b_H2O_200 * outletTemp ^ 3 - c_H2O_200 * outletTemp ^ 2 + d_H2O_200 * outletTemp - e_H2O_200;
    //
    // Power Equations
    powerCO2_1_5 = efficiencyCO2_1_5 * ThermalPower "Power from outletTemp";
    powerCO2_2 = efficiencyCO2_2 * ThermalPower "Power from outletTemp";
    powerCO2_2_5 = efficiencyCO2_2_5 * ThermalPower "Power from outletTemp";
    powerH2O_50 = efficiencyH2O_50 * ThermalPower "Power from outletTemp";
    powerH2O_90 = efficiencyH2O_90 * ThermalPower "Power from outletTemp";
    powerH2O_200 = efficiencyH2O_200 * ThermalPower "Power from outletTemp";
    //
    // If statements for SecondaryCoolantType
    powerGenerated = 
      if SecondaryCoolantType == "CO2" then
        if RatioType == "1.5" and outletTemp >= refTemp_CO2_1_5_min and outletTemp < refTemp_CO2_1_5_max then powerCO2_1_5
        elseif RatioType == "2" and outletTemp >= refTemp_CO2_2_min and outletTemp < refTemp_CO2_2_max then powerCO2_2
        elseif RatioType == "2.5" and outletTemp >= refTemp_CO2_2_5_min and outletTemp < refTemp_CO2_2_5_max then powerCO2_2_5
        else -1
      elseif SecondaryCoolantType == "H2O" then
        if SystemPressure == "50" and outletTemp >= refTemp_H2O_50_min and outletTemp < refTemp_H2O_50_max then powerH2O_50
        elseif SystemPressure == "90" and outletTemp >= refTemp_H2O_90_min and outletTemp < refTemp_H2O_90_max then powerH2O_90
        elseif SystemPressure == "200" and outletTemp >= refTemp_H2O_200_min and outletTemp < refTemp_H2O_200_max then powerH2O_200
        else -2
      else -3;
    //
    // Runtime Assertions
    if SecondaryCoolantType == "CO2" then
  
      if RatioType == "1.5" and outletTemp >= refTemp_CO2_1_5_min and outletTemp < refTemp_CO2_1_5_max then
        assert(efficiencyCO2_1_5 > 0 and efficiencyCO2_1_5 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyCO2_1_5 = "+String(efficiencyCO2_1_5)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyCO2_1_5 >= 0.25 and efficiencyCO2_1_5 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyCO2_1_5 = "+String(efficiencyCO2_1_5)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerCO2_1_5 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerCO2_1_5 = "+String(powerCO2_1_5)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerCO2_1_5 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerCO2_1_5 = "+String(powerCO2_1_5)+"] outside of reasonable range!", level = AssertionLevel.warning);
      
      elseif RatioType == "2" and outletTemp >= refTemp_CO2_2_min and outletTemp < refTemp_CO2_2_max then
        assert(efficiencyCO2_2 > 0 and efficiencyCO2_2 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyCO2_2 = "+String(efficiencyCO2_2)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyCO2_2 >= 0.25 and efficiencyCO2_2 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyCO2_2 = "+String(efficiencyCO2_2)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerCO2_2 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerCO2_2 = "+String(powerCO2_2)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerCO2_2 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerCO2_2 = "+String(powerCO2_2)+"] outside of reasonable range!", level = AssertionLevel.warning);
      
      elseif RatioType == "2.5" and outletTemp >= refTemp_CO2_2_5_min and outletTemp < refTemp_CO2_2_5_max then
        assert(efficiencyCO2_2_5 > 0 and efficiencyCO2_2_5 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyCO2_2_5 = "+String(efficiencyCO2_2_5)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyCO2_2_5 >= 0.25 and efficiencyCO2_2_5 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyCO2_2_5 = "+String(efficiencyCO2_2_5)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerCO2_2_5 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerCO2_2_5 = "+String(powerCO2_2_5)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerCO2_2_5 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerCO2_2_5 = "+String(powerCO2_2_5)+"] outside of reasonable range!", level = AssertionLevel.warning);
      end if;
    
    elseif SecondaryCoolantType == "H2O" then
    
      if SystemPressure == "50" and outletTemp >= refTemp_H2O_50_min and outletTemp < refTemp_H2O_50_max then
        assert(efficiencyH2O_50 > 0 and efficiencyH2O_50 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyH2O_50 = "+String(efficiencyH2O_50)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyH2O_50 >= 0.25 and efficiencyH2O_50 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyH2O_50 = "+String(efficiencyH2O_50)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerH2O_50 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerH2O_50 = "+String(powerH2O_50)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerH2O_50 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerH2O_50 = "+String(powerH2O_50)+"] outside of reasonable range!", level = AssertionLevel.warning);
      
      elseif SystemPressure == "90" and outletTemp >= refTemp_H2O_90_min and outletTemp < refTemp_H2O_90_max then
        assert(efficiencyH2O_90 > 0 and efficiencyH2O_90 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyH2O_90 = "+String(efficiencyH2O_90)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyH2O_90 >= 0.25 and efficiencyH2O_90 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyH2O_90 = "+String(efficiencyH2O_90)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerH2O_90 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerH2O_90 = "+String(powerH2O_90)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerH2O_90 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerH2O_90 = "+String(powerH2O_90)+"] outside of reasonable range!", level = AssertionLevel.warning);
      
      elseif SystemPressure == "200" and outletTemp >= refTemp_H2O_200_min and outletTemp < refTemp_H2O_200_max then
        assert(efficiencyH2O_200 > 0 and efficiencyH2O_200 <= 1, "---> Assertion Error in [BasePowerGen], variable [efficiencyH2O_200 = "+String(efficiencyH2O_200)+"] outside of acceptable range!", level = AssertionLevel.error);
        assert(efficiencyH2O_200 >= 0.25 and efficiencyH2O_200 <= 0.75, "---> Assertion Warning in [BasePowerGen], variable [efficiencyH2O_200 = "+String(efficiencyH2O_200)+"] outside of reasonable range!", level = AssertionLevel.warning);
        assert(powerH2O_200 >= 0, "---> Assertion Error in [BasePowerGen], variable [powerH2O_200 = "+String(powerH2O_200)+"] cannot be negative!", level = AssertionLevel.error);
        assert(powerH2O_200 <= 1e9, "---> Assertion Warning in [BasePowerGen], variable [powerH2O_200 = "+String(powerH2O_200)+"] outside of reasonable range!", level = AssertionLevel.warning);
      end if;
    
    end if;
  
  end BasePowerGen;

  model PowerGen_CO2
    extends PowerGenEquations.BasePowerGen(
      a_CO2_1_5 = -2.76E-12,
      b_CO2_1_5 = 1.09E-8,
      c_CO2_1_5 = 1.61E-5,
      d_CO2_1_5 = 1.06E-2,
      e_CO2_1_5 = 2.33,

      a_CO2_2 = -1.04E-12,
      b_CO2_2 = 3.90E-9,
      c_CO2_2 = 5.57E-6,
      d_CO2_2 = 3.68E-3,
      e_CO2_2 = 0.528,

      a_CO2_2_5 = -1.14E-12,
      b_CO2_2_5 = 4.26E-9,
      c_CO2_2_5 = 6.10E-6,
      d_CO2_2_5 = 4.06E-3,
      e_CO2_2_5 = 0.595,

      a_H2O_50 = -4.23E-12,
      b_H2O_50 = 1.38E-8,
      c_H2O_50 = 1.62E-5,
      d_H2O_50 = 0.00823,
      e_H2O_50 = 1.15,

      a_H2O_90 = -5.46E-12,
      b_H2O_90 = 1.81E-8,
      c_H2O_90 = 2.19E-5,
      d_H2O_90 = 0.0115,
      e_H2O_90 = 1.80,

      a_H2O_200 = -2.90E-12,
      b_H2O_200 = 9.85E-9,
      c_H2O_200 = 1.23E-5,
      d_H2O_200 = 0.00685,
      e_H2O_200 = 1.01,

      refTemp_CO2_1_5_min = 400,
      refTemp_CO2_2_min = 350,
      refTemp_CO2_2_5_min = 350,

      refTemp_H2O_50_min = 425,
      refTemp_H2O_90_min = 400,
      refTemp_H2O_200_min = 475,

      refTemp_CO2_1_5_max = 999999,
      refTemp_CO2_2_max = 999999,
      refTemp_CO2_2_5_max = 999999,

      refTemp_H2O_50_max = 999999,
      refTemp_H2O_90_max = 999999,
      refTemp_H2O_200_max = 999999);
  
  initial equation
    if RatioType == "1.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 400, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "50" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 425, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "90" and SecondaryCoolantType == "H2O" then 
      assert(outletTemp >= 400, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "200" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 475, "---> Assertion Error in [PowerGen_CO2], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    end if;
  
  equation

  end PowerGen_CO2;

  model PowerGen_He
    extends PowerGenEquations.BasePowerGen(
      a_CO2_1_5 = -2.54E-12,
      b_CO2_1_5 = 1.01E-08,
      c_CO2_1_5 = 1.52E-05,
      d_CO2_1_5 = 1.02E-02,
      e_CO2_1_5 = 2.27,

      a_CO2_2 = -1.03E-12,
      b_CO2_2 = 3.90E-09,
      c_CO2_2 = 5.63E-06,
      d_CO2_2 = 3.77E-03,
      e_CO2_2 = 5.76E-01,

      a_CO2_2_5 = -1.15E-12,
      b_CO2_2_5 = 4.33E-09,
      c_CO2_2_5 = 6.23E-06,
      d_CO2_2_5 = 4.19E-03,
      e_CO2_2_5 = 6.48E-01,

      a_H2O_50 = 0,
      b_H2O_50 = 1.66E-9,
      c_H2O_50 = 3.85E-6,
      d_H2O_50 = 3.06E-3,
      e_H2O_50 = 4.14E-1,

      a_H2O_90 = 0,
      b_H2O_90 = 2E-9,
      c_H2O_90 = 4E-6,
      d_H2O_90 = 0.0033,
      e_H2O_90 = 0.4525,

      a_H2O_200 = 0,
      b_H2O_200 = 0,
      c_H2O_200 = 0,
      d_H2O_200 = 2.37E-4,
      e_H2O_200 = 2.94E-1,

      refTemp_CO2_1_5_min = 450,
      refTemp_CO2_2_min = 350,
      refTemp_CO2_2_5_min = 350,

      refTemp_H2O_50_min = 350,
      refTemp_H2O_90_min = 400,
      refTemp_H2O_200_min = 475,

      refTemp_CO2_1_5_max = 999999,
      refTemp_CO2_2_max = 999999,
      refTemp_CO2_2_5_max = 999999,

      refTemp_H2O_50_max = 999999,
      refTemp_H2O_90_max = 999999,
      refTemp_H2O_200_max = 999999);
      
  initial equation
    if RatioType == "1.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 450, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "50" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "90" and SecondaryCoolantType == "H2O" then 
      assert(outletTemp >= 400, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "200" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 475, "---> Assertion Error in [PowerGen_He], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error); 
    end if;
  
  equation

  end PowerGen_He;

  model PowerGen_SubCritWater
    extends PowerGenEquations.BasePowerGen(
      a_CO2_1_5 = -1.98E-12,
      b_CO2_1_5 = 8.36E-09,
      c_CO2_1_5 = 1.30E-05,
      d_CO2_1_5 = 8.98E-03,
      e_CO2_1_5 = 1.99,

      a_CO2_2 = -1.02E-12,
      b_CO2_2 = 3.57E-09,
      c_CO2_2 = 4.88E-06,
      d_CO2_2 = 3.15E-03,
      e_CO2_2 = 3.81E-01,

      a_CO2_2_5 = -9.81E-13,
      b_CO2_2_5 = 3.58E-09,
      c_CO2_2_5 = 5.08E-06,
      d_CO2_2_5 = 3.40E-03,
      e_CO2_2_5 = 4.31E-01,

      a_H2O_50 = 0,
      b_H2O_50 = 0,
      c_H2O_50 = 0,
      d_H2O_50 = 4E-4,
      e_H2O_50 = -2.21E-1,

      a_H2O_90 = 0,
      b_H2O_90 = 0,
      c_H2O_90 = 0,
      d_H2O_90 = 4.15E-4,
      e_H2O_90 = -2.39E-1,

      a_H2O_200 = 0,
      b_H2O_200 = 0,
      c_H2O_200 = 0,
      d_H2O_200 = 0,
      e_H2O_200 = 0,

      refTemp_CO2_1_5_min = 325,
      refTemp_CO2_2_min = 200,
      refTemp_CO2_2_5_min = 250,

      refTemp_H2O_50_min = 300,
      refTemp_H2O_90_min = 325,
      refTemp_H2O_200_min = 0,

      refTemp_CO2_1_5_max = 350,
      refTemp_CO2_2_max = 325,
      refTemp_CO2_2_5_max = 350,

      refTemp_H2O_50_max = 325,
      refTemp_H2O_90_max = 350,
      refTemp_H2O_200_max = 0);
  
  initial equation
    if RatioType == "1.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 325 and outletTemp <= 350, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 200 and outletTemp <= 325, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 250 and outletTemp <= 350, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "50" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 300 and outletTemp <= 325, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "90" and SecondaryCoolantType == "H2O" then 
      assert(outletTemp >= 325 and outletTemp <= 350, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "200" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 0 and outletTemp <= 0, "---> Assertion Error in [PowerGen_SubCritWater], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error); 
    end if;
  
  equation
  
  end PowerGen_SubCritWater;

  model PowerGen_FliBe
    extends PowerGenEquations.BasePowerGen(
      a_CO2_1_5 = 2.42E-13,
      b_CO2_1_5 = 7.04E-10,
      c_CO2_1_5 = 3.47E-06,
      d_CO2_1_5 = 3.86E-03,
      e_CO2_1_5 = 1.01,

      a_CO2_2 = -1.22E-12,
      b_CO2_2 = 4.12E-09,
      c_CO2_2 = 5.42E-06,
      d_CO2_2 = 3.37E-03,
      e_CO2_2 = 4.16E-01,

      a_CO2_2_5 = -1.06E-12,
      b_CO2_2_5 = 3.80E-09,
      c_CO2_2_5 = 5.30E-06,
      d_CO2_2_5 = 3.51E-03,
      e_CO2_2_5 = 4.48E-01,

      a_H2O_50 = 0,
      b_H2O_50 = 0,
      c_H2O_50 = -2.85E-7,
      d_H2O_50 = 7.53E-4,
      e_H2O_50 = 0.117,

      a_H2O_90 = 0,
      b_H2O_90 = 0,
      c_H2O_90 = -2.71E-7,
      d_H2O_90 = 8.39E-4,
      e_H2O_90 = 0.08,

      a_H2O_200 = 0,
      b_H2O_200 = 0,
      c_H2O_200 = -3.96E-7,
      d_H2O_200 = 1.21E-3,
      e_H2O_200 = 0.11,

      refTemp_CO2_1_5_min = 375,
      refTemp_CO2_2_min = 350,
      refTemp_CO2_2_5_min = 350,

      refTemp_H2O_50_min = 300,
      refTemp_H2O_90_min = 325,
      refTemp_H2O_200_min = 400,

      refTemp_CO2_1_5_max = 999999,
      refTemp_CO2_2_max = 999999,
      refTemp_CO2_2_5_max = 999999,

      refTemp_H2O_50_max = 999999,
      refTemp_H2O_90_max = 999999,
      refTemp_H2O_200_max = 999999);
  
  initial equation
    if RatioType == "1.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 375, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2.5" and SecondaryCoolantType == "CO2" then 
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "50" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 300, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "90" and SecondaryCoolantType == "H2O" then 
      assert(outletTemp >= 325, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "200" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 400, "---> Assertion Error in [PowerGen_FliBe], input parameter [outletTemp = "+String(outletTemp)+"] outside of acceptable range!", level = AssertionLevel.error); 
    end if;

  equation

  end PowerGen_FliBe;

  model PowerGen_LiPb
    extends PowerGenEquations.BasePowerGen(
      a_CO2_1_5 = 4.26E-13,
      b_CO2_1_5 = 1.42E-10,
      c_CO2_1_5 = 2.98E-06,
      d_CO2_1_5 = 3.84E-03,
      e_CO2_1_5 = 1.11,
      
      a_CO2_2 = -8.79E-13,
      b_CO2_2 = 3.35E-09,
      c_CO2_2 = 4.90E-06,
      d_CO2_2 = 3.33E-03,
      e_CO2_2 = 4.69E-01,
      
      a_CO2_2_5 = -9.12E-13,
      b_CO2_2_5 = 3.48E-09,
      c_CO2_2_5 = 5.12E-06,
      d_CO2_2_5 = 3.54E-03,
      e_CO2_2_5 = 4.98E-01,
      
      a_H2O_50 = -2.66E-12,
      b_H2O_50 = 8.01E-9,
      c_H2O_50 = 8.81E-6,
      d_H2O_50 = 0.0045,
      e_H2O_50 = 0.461,
      
      a_H2O_90 = -1.12e-12,
      b_H2O_90 = 3.93e-9,
      c_H2O_90 = 5.18e-6,
      d_H2O_90 = 0.00333,
      e_H2O_90 = 0.353,
      
      a_H2O_200 = -3.34e-13,
      b_H2O_200 = 1.68e-9,
      c_H2O_200 = 3.18e-6,
      d_H2O_200 = 0.0029,
      e_H2O_200 = 0.415,
      
      refTemp_CO2_1_5_min = 425,
      refTemp_CO2_2_min = 350,
      refTemp_CO2_2_5_min = 350,
      
      refTemp_H2O_50_min = 300,
      refTemp_H2O_90_min = 325,
      refTemp_H2O_200_min = 400,
      
      refTemp_CO2_1_5_max = 999999,
      refTemp_CO2_2_max = 999999,
      refTemp_CO2_2_5_max = 999999,
      
      refTemp_H2O_50_max = 999999,
      refTemp_H2O_90_max = 999999,
      refTemp_H2O_200_max = 999999);
  
  initial equation
    if RatioType == "1.5" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 425, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "2.5" and SecondaryCoolantType == "CO2" then
      assert(outletTemp >= 350, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "50" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 300, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "90" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 325, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    elseif RatioType == "200" and SecondaryCoolantType == "H2O" then
      assert(outletTemp >= 400, "---> Assertion Error in [PowerGen_LiPb], input parameter [outletTemp = " + String(outletTemp) + "] outside of acceptable range!", level = AssertionLevel.error);
    end if;
  
  equation

  end PowerGen_LiPb;
end PowerGenEquations;
