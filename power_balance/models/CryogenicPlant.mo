package CryogenicPlant "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model CryogenicPower "Model of the power loads of the cryogenic plant"
    // Imported Parameters
    import SI = Modelica.SIunits;
    parameter Real __cryoFlow_HydrogenFreezing(unit = "g/s") = 1;
    parameter Real __cryoTemp_TF(unit = "K") = 4.2;
    parameter Real __cryoTemp_PF(unit = "K") = 4.2;   
    parameter Real __PFcrMW(unit = "W") = 0.1 "????PF conduction and radiation losses????";
    //
    Modelica.Blocks.Interfaces.RealInput Magnetheat_TF(unit = "W") "Heat dissipated by TF coils at cryogenic temperature" annotation(
      Placement(visible = true, transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealInput Magnetheat_PF(unit = "W") "Heat dissipated by PF coils at cryogenic temperature" annotation(
      Placement(visible = true, transformation(origin = {-110, 40}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 40}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealInput Magnet_HFlow(unit = "g/s") "Magnets cryogenic hydrogen mass flow rate. May need to be separated into PF and TF" annotation(
      Placement(visible = true, transformation(origin = {-110, 80}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 80}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealOutput P_amb(unit = "W") "Heat dissipated to air (W)" annotation(
      Placement(visible = true, transformation(extent = {{100, 10}, {120, 30}}, rotation = 0), iconTransformation(extent = {{100, 10}, {120, 30}}, rotation = 0)));
    //
    // Variables
    SI.Power ElecPowerConsumed "Power consumption of all cyogenics (W)";
    //
    // Instantiating Models
    CurrentLeads currentLeads(Magnet_HFlow = Magnet_HFlow);
    TFCoils tfCoils(MagnetHeat_TF = Magnetheat_TF, cryoTemp_TF = __cryoTemp_TF);
    PFCoils pfCoils(MagnetHeat_PF = Magnetheat_PF, cryoTemp_PF = __cryoTemp_PF, PFcrMW = __PFcrMW);
    Cryodistillation CD();
    FuelMatterInjection fuelMatterInjection(cryoFlow_FuelMatterInjection = __cryoFlow_HydrogenFreezing);
    //
    // Convert Cryodistillation output into electrical load (!!To be combine in Cryodistillation model!!)
    ConvertCryoElec cryoDistConversion(cryoTemp = CD.InTemp1, cryoPower = CD.Load_Total);
    ConvertCryoElec cryoDistN2Conversion(cryoTemp = 80, cryoPower = CD.NitrogenLoadInput_Total);
    //
  initial equation
    // Input Parameter Assertions
    assert(__cryoFlow_HydrogenFreezing >= 2 and __cryoFlow_HydrogenFreezing <= 7, "---> Assertion Warning in [CryogenicPower], variable [cryoFlow_HydrogenFreezing = "+String(__cryoFlow_HydrogenFreezing)+"] outside of reasonable range!", AssertionLevel.warning);
    assert(__cryoFlow_HydrogenFreezing > 0 and __cryoFlow_HydrogenFreezing <=10, "---> Assertion Error in [CryogenicPower], variable [cryoFlow_HydrogenFreezing = "+String(__cryoFlow_HydrogenFreezing)+"] outside of acceptable range!", AssertionLevel.error);
    assert(__cryoTemp_TF >= 4 and __cryoTemp_TF <= 20, "---> Assertion Warning in [CryogenicPower], variable [cryoTemp_TF = "+String(__cryoTemp_TF)+"] outside of reasonable range!", AssertionLevel.warning);
    assert(__cryoTemp_TF > 0 and __cryoTemp_TF <= 130, "---> Assertion Error in [CryogenicPower], variable [cryoTemp_TF = "+String(__cryoTemp_TF)+"] outside of acceptable range!", AssertionLevel.error);
    assert(__cryoTemp_PF >= 4 and __cryoTemp_PF <= 20, "---> Assertion Warning in [CryogenicPower], variable [cryoTemp_PF = "+String(__cryoTemp_PF)+"] outside of reasonable range!", AssertionLevel.warning);
    assert(__cryoTemp_PF > 0 and __cryoTemp_PF <= 130, "---> Assertion Error in [CryogenicPower], variable [cryoTemp_PF = "+String(__cryoTemp_PF)+"] outside of acceptable range!", AssertionLevel.error);
    assert(__PFcrMW >= 0.0001 and __PFcrMW <= 0.5, "---> Assertion Warning in [CryogenicPower], variable [PFcrMW = "+String(__PFcrMW)+"] outside of reasonable range!", AssertionLevel.warning);
    assert(__PFcrMW > 0 and __PFcrMW <= 10, "---> Assertion Error in [CryogenicPower], variable [PFcrMW = "+String(__PFcrMW)+"] outside of acceptable range!", AssertionLevel.error);
  equation
    // Totals
    ElecPowerConsumed = currentLeads.ElecPower_CurrentLeads + tfCoils.ElecPower_TF + pfCoils.ElecPower_PF + cryoDistConversion.elecPower + cryoDistN2Conversion.elecPower + fuelMatterInjection.ElecPower_FuelMatterInjection "Sum of all power loads";
    P_amb = ElecPowerConsumed + CD.Load_Total + Magnetheat_PF + Magnetheat_TF + CD.NitrogenLoadInput_Total "Heat to the hot sink is the sum of input work and heat from cold sink";
    //
  end CryogenicPower;

  model ConvertCryoElec
    // Function converting cryogenic flow or duty to electrical duty
    // For a coolingPower load at some cryogenic temperature it estimates the electrical load using the Carnot Efficiency and a Figure of Merit (FOM) for a system. Inefficiencies expressed as a percent of the Carnot Efficiency.
    //
    // Imported Parameters NOTE: LEAVE AS 0, THESE GET OVERWRITTEN WHEN CALLED BY A MODEL
    import SI = Modelica.SIunits;
    Real cryoTemp(unit = "K") = 0 "Cryogenic temperature required by model (K)";
    Real cryoPower(unit = "W") = 0 "Cryogenic duty requirements from model, if using cryogenic power conversion (W)";
    Real cryoFlow(unit = "g/s") = 0 "Import cryogenic flowrate, if using cryogenic flow conversion (g/s)";
    //
    // Specified Paramers
    parameter SI.Temperature roomTemp = 298 "Room temperature assumed constant across loads (K)";
    parameter Real FOM4K(unit = "percent") = 30 "Figure of merit for system at ~4 K, expected input to be 30<=FOM<=40 (%), STRUCTURAL_PARAMETER";
    parameter Real FOM20K(unit = "percent") = 30 "Figure of merit for cryo system at ~20 K (%), STRUCTURAL_PARAMETER";
    parameter Real FOM80K(unit = "percent") = 30 "Figure of merit for cryo loop at ~80 K (%, STRUCTURAL_PARAMETER)";
    //
    // Variables
    Real sysFOM(unit = "percent") "Figure of merit for system based on cryo temperature (%)";
    Real carnotMult(unit = "1") "Carnot efficiency multiplier, 1/(Carnot Efficiency)";
    Real enthalpyChangeHe(unit = "J/g") "Specific energy change of helium cooled to cryogenic temperature (J/g)";
    SI.Power elecPower_CryoPower;
    SI.Power elecPower_CryoFlow;
    SI.Power elecPower "Electrical power out (W)";
    //
  equation
    // Selects the appropriate figure of merit based on the cryogenic temperautre of the system
    if cryoTemp < 20 then
      sysFOM = FOM4K;
    elseif cryoTemp < 80 then
      sysFOM = FOM20K;
    elseif cryoTemp >= 80 then
      sysFOM = FOM80K;
    else
      sysFOM = 30;
    end if;
    //
    // Equations for converting cyro power to electrical power
    carnotMult = (roomTemp - cryoTemp) / cryoTemp "1 / Carnot Efficiency";
    elecPower_CryoPower = 100 / sysFOM * carnotMult * cryoPower "Converts the cryogenic duty to electrical duty";
    // Equations for converting cryoFlow to electrical power
    enthalpyChangeHe = (-1672 * log(cryoTemp)) + 8098.3 "Logarithmic fit to temperatures below 100K. Data taken from CoolProp. For better fidelity and wider applicability, interface Modelica with CoolProp";
    elecPower_CryoFlow = cryoFlow * enthalpyChangeHe * (100 / sysFOM);
    //
    // Returns appropriate power output, based on the input parameter (cryogenic power or flow)
  algorithm
    if cryoPower > 0 then
      elecPower := elecPower_CryoPower;
    elseif cryoFlow > 0 then
      elecPower := elecPower_CryoFlow;
    else
      elecPower := 0;
    end if;
    //
  end ConvertCryoElec;

  model CurrentLeads
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real Magnet_HFlow(unit = "g/s") "Imported from Magnet Model";
    //
    // Specified Parameters
    parameter SI.Temperature cryoTemp_CurrentLeads = 4.5 "HTS current leads temperature (K)";
    //
    // Variables
    Real FOM_CurrentLeads "Figure-of-merit for feeders' power conversion (%)";
    SI.Power ElecPower_CurrentLeads;
    //
    // Current leads cryogenics power consumption
    ConvertCryoElec currentLeadsConversion(cryoTemp = cryoTemp_CurrentLeads, cryoFlow = Magnet_HFlow);
    //
  equation
    ElecPower_CurrentLeads = currentLeadsConversion.elecPower;
    FOM_CurrentLeads = currentLeadsConversion.sysFOM;
    //
    // Runtime Assertions
    assert(ElecPower_CurrentLeads >= 0, "Variable [ElecPower_CurrentLeads = " + String(ElecPower_CurrentLeads) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(ElecPower_CurrentLeads <= 3e8, "Variable [ElecPower_CurrentLeads = " + String(ElecPower_CurrentLeads) + "] outside of reasonable range", level = AssertionLevel.warning);
    //
  end CurrentLeads;

  model TFCoils
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real MagnetHeat_TF(unit = "W");
    SI.Temperature cryoTemp_TF = 4.2 "TF coils cryogenic temperature (K)";
    //
    // Specified Parameters
    //
    // Variables
    Real FOM_TF(unit = "percent") "Figure-of-merit for TF coil power conversion (%)";
    SI.Power ElecPower_TF "Electrical consumption of the TF coil cooling (W)";
    //
    // TF Coil Power Conversion
    ConvertCryoElec tfCoilConversion(cryoTemp = cryoTemp_TF, cryoPower = MagnetHeat_TF);
    //
  equation
    ElecPower_TF = tfCoilConversion.elecPower;
    FOM_TF = tfCoilConversion.sysFOM;
    //
    // Runtime Assertions
    assert(ElecPower_TF >= 0, "Variable [ElecPower_TF = " + String(ElecPower_TF) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(ElecPower_TF <= 3e8, "Variable [ElecPower_TF = " + String(ElecPower_TF) + "] outside of reasonable range", level = AssertionLevel.warning);
    assert(cryoTemp_TF >= 4 and cryoTemp_TF <= 20, "---> Assertion Warning in [TFCoils], variable [cryoTemp_TF = " + String(cryoTemp_TF) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(cryoTemp_TF > 0 and cryoTemp_TF <= 130, "---> Assertion Error in [TFCoils], variable [cryoTemp_TF = " + String(cryoTemp_TF) + "] outside of acceptable range!", AssertionLevel.error);
    //
  end TFCoils;

  model PFCoils
    // Cooling PF coils
    // Imported Parameters
    import SI = Modelica.SIunits;
    SI.Power MagnetHeat_PF;
    SI.Temperature cryoTemp_PF = 4.2 "PF coil cryogenic temperature (K)";
    Real PFcrMW = 0 "????PF conduction and radiation losses????";
    //
    // Variables
    Real FOM_PF(unit = "percent") "Figure-of-merit for PF coil power conversion (%)";
    SI.Power ElecPower_PF "Electrical consumption of the PF coil cooling (W)";
    //
    // PF Coil Power Conversions
    ConvertCryoElec pfCoilConversion(cryoTemp = cryoTemp_PF, cryoPower = MagnetHeat_PF + PFcrMW);
    //
  equation
    ElecPower_PF = pfCoilConversion.elecPower;
    FOM_PF = pfCoilConversion.sysFOM;
    //
    //
    // Runtime Assertions
    assert(ElecPower_PF >= 0, "Variable [ElecPower_PF = " + String(ElecPower_PF) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(ElecPower_PF <= 3e8, "Variable [ElecPower_PF = " + String(ElecPower_PF) + "] outside of reasonable range", level = AssertionLevel.warning);
    assert(cryoTemp_PF >= 4 and cryoTemp_PF <= 20, "---> Assertion Warning in [CryogenicPower], variable [cryoTemp_PF = " + String(cryoTemp_PF) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(cryoTemp_PF > 0 and cryoTemp_PF <= 130, "---> Assertion Error in [CryogenicPower], variable [cryoTemp_PF = " + String(cryoTemp_PF) + "] outside of acceptable range!", AssertionLevel.error);
    assert(PFcrMW > 0 and PFcrMW <= 0.5, "---> Assertion Warning in [PFCoils], variable [PFcrMW = " + String(PFcrMW) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(PFcrMW > 0 and PFcrMW <= 10, "---> Assertion Error in [PFCoils], variable [PFcrMW = " + String(PFcrMW) + "] outside of acceptable range!", AssertionLevel.error);
    //
  end PFCoils;

  model FuelMatterInjection
    // Imported Parameters
    import SI = Modelica.SIunits;
    Real cryoFlow_FuelMatterInjection(unit = "g/s") = 3.5 "Cryogenic mass flow rate for the load (g/s), from Pellet Injection on JT60SA www.jt60sa.org/pdfs/cdr/10-3.5_Cryogenic_System.pdf";
    // Specified Parameters
    parameter SI.Temperature cryoTemp_HydrogenFreezing = 4 "Cryogenic temperature of Hydrogen Freezing";
    //
    // Variables
    Real FOM_FuelMatterInjection(unit = "percent") "Figure of merit for FMI system (%)";
    SI.Power ElecPower_FuelMatterInjection "Electrical consumption of Hydrogen Freezing";
    //
    ConvertCryoElec fmiConversion(cryoTemp = cryoTemp_HydrogenFreezing, cryoFlow = cryoFlow_FuelMatterInjection);
    //
    equation
    ElecPower_FuelMatterInjection = fmiConversion.elecPower;
    FOM_FuelMatterInjection = fmiConversion.sysFOM;
    //
    // Runtime Assertions
    assert(ElecPower_FuelMatterInjection >= 0, "Variable [ElecPower_FuelMatterInjection = " + String(ElecPower_FuelMatterInjection) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(ElecPower_FuelMatterInjection <= 1e8, "Variable [ElecPower_FuelMatterInjection = " + String(ElecPower_FuelMatterInjection) + "] outside of reasonable range", level = AssertionLevel.warning);
    assert(cryoFlow_FuelMatterInjection >= 2 and cryoFlow_FuelMatterInjection <= 7, "---> Assertion Warning in [FuelMatterInjection], variable [cryoFlow_FuelMatterInjection = " + String(cryoFlow_FuelMatterInjection) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(cryoFlow_FuelMatterInjection > 0 and cryoFlow_FuelMatterInjection <= 10, "---> Assertion Error in [FuelMatterInjection], variable [cryoFlow_FuelMatterInjection = " + String(cryoFlow_FuelMatterInjection) + "] outside of acceptable range!", AssertionLevel.error);
    //
  end FuelMatterInjection;

  model Cryodistillation "A model for cryodistillation power consumption"
    //
    import SI = Modelica.SIunits;
    //
    // Constant Definitions
    constant SI.SpecificHeatCapacity GH_Cp = 12504 "Specific heat of gaseous hydrogen";
    constant SI.SpecificHeatCapacity LH_Cp = 8000 "Specific heat of liquid hydrogen";
    constant Real Heat_Evap(unit = "J/kg") = 450000 "Latent heat of evaporation";
    constant SI.Temperature Temp_Evap = 20.27 "Temperature of evaporation";
    //
    // Input Parameters
    parameter SI.MassFlowRate __InputFlowRateCol_1 = 1 / 3600 "Input flow rate to Col 1";
    parameter SI.MassFlowRate __InputFlowRateCol_2 = 1 / 3600 "Input flow rate to Col 2";
    //
    // Plant Configuration Parameters
    parameter Real RefluxCol_1 = 10 "Reflux ratio Col 1";
    parameter Real RefluxCol_3 = 10 "Reflux ratio Col 3";
    parameter Real RefluxCol_4 = 10 "Reflux ratio Col 4";
    parameter SI.MassFlowRate __FBCol_2 = 1 / 3600 "Feedback loop between Col 2 and Col 1";
    parameter SI.MassFlowRate __FBCol_3 = 1 / 3600 "Feedback loop between Col 3 and Col 1";
    parameter SI.Temperature InTemp1 = 18 "Temperature of input Col 1";
    parameter SI.Temperature InTemp2 = 20 "Temperature of input Col 2";
    parameter SI.Temperature FBTemp1 = 18 "Temperature of reflux feedback Col 1";
    parameter SI.Temperature FBTemp2 = 20 "Temperature of reflux feedback Col 2";
    parameter SI.Temperature FBTemp3 = 20 "Temperature of reflux feedback Col 3";
    parameter SI.Temperature FBTemp4 = 20 "Temperature of reflux feedback Col 4";
    //
    // Output Parameters
    parameter SI.MassFlowRate __OutputStreamRateCol_1 = 0.3 / 3600 "Output stream rate from Col 1 ";
    parameter SI.MassFlowRate __OutputStreamRateCol_2 = 0.5 / 3600 "Output stream rate from Col 2";
    parameter SI.MassFlowRate __OutputStreamRateCol_3 = 0.3 / 3600 "Output stream rate from Col 3";
    parameter SI.MassFlowRate __OutputStreamRateCol_4 = 0.5 / 3600 "Output stream rate from Col 4";
    parameter SI.MassFlowRate netFlow_1_2 = -0.3 / 3600 "Net flow from Col 1 to Col 2";
    //
    // Condensor Power Loads - all cryoload
    SI.Power LoadInput_1 "Condensor load on input stream to Col 1";
    SI.Power LoadInput_2 "Condensor load on input stream to Col 2";
    SI.Power NitrogenLoadInput_1;
    SI.Power NitrogenLoadInput_2;
    SI.Power NitrogenLoadInput_Total;
    SI.Power Load_1 "Condensor load on reflux stream for Col 1";
    SI.Power Load_2 "Condensor load on feedack stream from Col 2 to Col 1";
    SI.Power Load_3 "Condensor load on reflux stream for Col 3";
    SI.Power Load_4 "Condensor load on reflux stream for Col 4";
    SI.Power Load_Total "Total cryogenic heat load of cryodistillation plant";
    //
  initial equation
    // Input Parameter Assertions
    assert(__FBCol_2 >= 0.00001 and __FBCol_2 <= 0.05, "---> Assertion Warning in [Cryodistillation], input parameter [FBCol_2 = " + String(__FBCol_2) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__FBCol_2 >= 0 and __FBCol_2 <= 1, "---> Assertion Error in [Cryodistillation], input parameter [FBCol_2 = " + String(__FBCol_2) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__FBCol_3 >= 0.00001 and __FBCol_3 <= 0.05, "---> Assertion Warning in [Cryodistillation], input parameter [FBCol_3 = " + String(__FBCol_3) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__FBCol_3 >= 0 and __FBCol_3 <= 1, "---> Assertion Error in [Cryodistillation], input parameter [FBCol_3 = " + String(__FBCol_3) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__InputFlowRateCol_1 >= 1e-5 and __InputFlowRateCol_1 <= 0.05, "---> Assertion Warning in [Cryodistillation], input parameter [InputFlowRateCol_1 = " + String(__InputFlowRateCol_1) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__InputFlowRateCol_1 >= 0 and __InputFlowRateCol_1 <= 1, "---> Assertion Error in [Cryodistillation], input parameter [InputFlowRateCol_1 = " + String(__InputFlowRateCol_1) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__InputFlowRateCol_2 >= 1e-5 and __InputFlowRateCol_2 <= 0.05, "---> Assertion Warning in [Cryodistillation], input parameter [InputFlowRateCol_2 = " + String(__InputFlowRateCol_2) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__InputFlowRateCol_2 >= 0 and __InputFlowRateCol_2 <= 1, "---> Assertion Error in [Cryodistillation], input parameter [InputFlowRateCol_2 = " + String(__InputFlowRateCol_2) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__OutputStreamRateCol_1 >= 1e-7 and __OutputStreamRateCol_1 <= 0.001, "---> Assertion Warning in [Cryodistillation], input parameter [OutputStreamRateCol_1 = " + String(__OutputStreamRateCol_1) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__OutputStreamRateCol_1 >= 0 and __OutputStreamRateCol_1 <= 0.05, "---> Assertion Error in [Cryodistillation], input parameter [OutputStreamRateCol_1 = " + String(__OutputStreamRateCol_1) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__OutputStreamRateCol_2 >= 1e-5 and __OutputStreamRateCol_2 <= 0.01, "---> Assertion Warning in [Cryodistillation], input parameter [OutputStreamRateCol_2 = " + String(__OutputStreamRateCol_2) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__OutputStreamRateCol_2 >= 0 and __OutputStreamRateCol_2 <= 0.5, "---> Assertion Error in [Cryodistillation], input parameter [OutputStreamRateCol_2 = " + String(__OutputStreamRateCol_2) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__OutputStreamRateCol_3 >= 1e-7 and __OutputStreamRateCol_3 <= 0.001, "---> Assertion Warning in [Cryodistillation], input parameter [OutputStreamRateCol_3 = " + String(__OutputStreamRateCol_3) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__OutputStreamRateCol_3 >= 0 and __OutputStreamRateCol_3 <= 0.5, "---> Assertion Error in [Cryodistillation], input parameter [OutputStreamRateCol_3 = " + String(__OutputStreamRateCol_3) + "] outside of acceptable range!", AssertionLevel.error);
    assert(__OutputStreamRateCol_4 >= 1e-5 and __OutputStreamRateCol_4 <= 0.01, "---> Assertion Warning in [Cryodistillation], input parameter [OutputStreamRateCol_4 = " + String(__OutputStreamRateCol_4) + "] outside of reasonable range!", AssertionLevel.warning);
    assert(__OutputStreamRateCol_4 >= 0 and __OutputStreamRateCol_4 <= 0.5, "---> Assertion Error in [Cryodistillation], input parameter [OutputStreamRateCol_4 = " + String(__OutputStreamRateCol_4) + "] outside of acceptable range!", AssertionLevel.error);
    //
  equation
    // Mass-balance (eventually will do a mass balance across whole plant to determine netflows)
    // Input Condensors
    LoadInput_1 = __InputFlowRateCol_1 * (GH_Cp * (77 - Temp_Evap) + Heat_Evap + LH_Cp * (Temp_Evap - InTemp1));
    LoadInput_2 = __InputFlowRateCol_2 * (GH_Cp * (77 - Temp_Evap) + Heat_Evap + LH_Cp * (Temp_Evap - InTemp2));
    NitrogenLoadInput_1 = __InputFlowRateCol_1 * (GH_Cp * (293 - 77));
    NitrogenLoadInput_2 = __InputFlowRateCol_2 * (GH_Cp * (293 - 77));
    // Feedback Condensors
    Load_1 = __OutputStreamRateCol_1 * RefluxCol_1 * (Heat_Evap + LH_Cp * (Temp_Evap - FBTemp1));
    Load_2 = (__FBCol_2 - netFlow_1_2) * (Heat_Evap + LH_Cp * (Temp_Evap - FBTemp2));
    Load_3 = __FBCol_3 * RefluxCol_3 * (Heat_Evap + LH_Cp * (Temp_Evap - FBTemp3));
    Load_4 = __OutputStreamRateCol_4 * RefluxCol_4 * (Heat_Evap + LH_Cp * (Temp_Evap - FBTemp4));
    // Total Power Usage
    Load_Total = LoadInput_1 + LoadInput_2 + Load_1 + Load_2 + Load_3 + Load_4;
    NitrogenLoadInput_Total = NitrogenLoadInput_2 + NitrogenLoadInput_1;
    //
    //
    // Runtime Assertions
    assert(LoadInput_1 >= 0, "---> Assertion Error in [Cryodistillation], variable [LoadInput_1 = " + String(LoadInput_1) + "] cannot be negative!", level = AssertionLevel.error);
    assert(LoadInput_1 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [LoadInput_1 = " + String(LoadInput_1) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(LoadInput_2 >= 0, "---> Assertion Error in [Cryodistillation], variable [LoadInput_2 = " + String(LoadInput_2) + "] cannot be negative!", level = AssertionLevel.error);
    assert(LoadInput_2 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [LoadInput_2 = " + String(LoadInput_2) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(NitrogenLoadInput_1 >= 0, "---> Assertion Error in [Cryodistillation], variable [NitrogenLoadInput_1 = " + String(NitrogenLoadInput_1) + "] cannot be negative!", level = AssertionLevel.error);
    assert(NitrogenLoadInput_1 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [NitrogenLoadInput_1 = " + String(NitrogenLoadInput_1) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(NitrogenLoadInput_2 >= 0, "---> Assertion Error in [Cryodistillation], variable [NitrogenLoadInput_2 = " + String(NitrogenLoadInput_2) + "] cannot be negative!", level = AssertionLevel.error);
    assert(NitrogenLoadInput_2 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [NitrogenLoadInput_2 = " + String(NitrogenLoadInput_2) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(NitrogenLoadInput_Total >= 0, "---> Assertion Error in [Cryodistillation], variable [NitrogenLoadInput_Total = " + String(NitrogenLoadInput_Total) + "] cannot be negative!", level = AssertionLevel.error);
    assert(NitrogenLoadInput_Total <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [NitrogenLoadInput_Total = " + String(NitrogenLoadInput_Total) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Load_1 >= 0, "---> Assertion Error in [Cryodistillation], variable [Load_1 = " + String(Load_1) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Load_1 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [Load_1 = " + String(Load_1) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Load_2 >= 0, "---> Assertion Error in [Cryodistillation], variable [Load_2 = " + String(Load_2) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Load_2 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [Load_2 = " + String(Load_2) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Load_3 >= 0, "---> Assertion Error in [Cryodistillation], variable [Load_3 = " + String(Load_3) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Load_3 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [Load_3 = " + String(Load_3) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Load_4 >= 0, "---> Assertion Error in [Cryodistillation], variable [Load_4 = " + String(Load_4) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Load_4 <= 1e4, "---> Assertion Warning in [Cryodistillation], variable [Load_4 = " + String(Load_4) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Load_Total >= 0, "---> Assertion Error in [Cryodistillation], variable [Load_Total = " + String(Load_Total) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Load_Total <= 1e5, "---> Assertion Warning in [Cryodistillation], variable [Load_Total = " + String(Load_Total) + "] outside of reasonable range!", level = AssertionLevel.warning);
  end Cryodistillation;

  annotation(
    uses(Modelica(version = "3.2.3")));
end CryogenicPlant;
