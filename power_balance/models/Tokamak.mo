package Tokamak "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model Interdependencies
    parameter String __PrimaryCoolantType = "FLiBe" "STRUCTURAL_PARAMETER";
    parameter String __SecondaryCoolantType = "CO2" "H2O/CO2. STRUCTURAL_PARAMETER";
    parameter String __RatioType = "2.5" "1.5/2/2.5. STRUCTURAL_PARAMETER";
    parameter String __SystemPressure = "200" "bar: 50/90/200. STRUCTURAL_PARAMETER";
    parameter String __VacuumType = "turbo" "'cryo'/'turbo', STRUCTURAL_PARAMETER";
    parameter Real __ThermalPower "Total high grade thermal power, MW; overwritten by profile peak";
    parameter String __ThermalPowerDataPath  = "ThermalPowerOut.mat";
    //
    Utilities.CombiTimeTable combiTimeTableThermal(fileName = __ThermalPowerDataPath, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true);
    //
    BlanketDetrit.Power_NonCarrier blanketdetritpower(ThermalPower = combiTimeTableThermal.value_max/1e6, PrimaryCoolantType = __PrimaryCoolantType) annotation(
        Placement(visible = true, transformation(origin = {-20, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PowerGenEquations.PowerGenCaseByCase powergenerated(PrimaryCoolantType = __PrimaryCoolantType, SecondaryCoolantType = __SecondaryCoolantType, RatioType = __RatioType, SystemPressure = __SystemPressure, thermalPowerData = __ThermalPowerDataPath) annotation(
        Placement(visible = true, transformation(origin = {-70, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    CoolantDetrit.CoolantDetritCaseByCase coolantdetritpower(PrimaryCoolantType = __PrimaryCoolantType, ThermalPower = combiTimeTableThermal.value_max/1e6) annotation(
        Placement(visible = true, transformation(origin = {20, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    VacuumPump.VacuumPumpPower total_vacuumpump_power(vacuumType = __VacuumType, thermalPowerData = __ThermalPowerDataPath) annotation(
        Placement(visible = true, transformation(origin = {-10, -70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Magnets.MagnetPower magnetpower annotation(
        Placement(visible = true, transformation(origin = {-32, 20}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
    CryogenicPlant.CryogenicPower cryogenicpower annotation(
        Placement(visible = true, transformation(origin = {22, 22}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    HCDSystemPkg.HCDSystem hcdsystem annotation(
        Placement(visible = true, transformation(origin = {-16, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    WasteHeatDB.TotalParasitcLoadWH wasteheatpower (ThermalPower = combiTimeTableThermal.value_max/1e9) annotation(
        Placement(visible = true, transformation(origin = {60, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    WaterDetritiation.WaterDetritPower water_detrit_power(ThermalPower = combiTimeTableThermal.value_max/1e6) annotation(
        Placement(visible = true, transformation(origin = {60, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    AirGasDetrit.AirGasPower air_gas_power(ThermalPower = combiTimeTableThermal.value_max/1e6) annotation(
        Placement(visible = true, transformation(origin = {-60, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    //
  equation
    connect(magnetpower.cryoHeat_PF, cryogenicpower.Magnetheat_PF) annotation(
        Line(points = {{-24, 21}, {0, 21}, {0, 22}, {12, 22}}, color = {0, 0, 127}));
    connect(magnetpower.cryoHeat_TF, cryogenicpower.Magnetheat_TF) annotation(
        Line(points = {{-24, 21}, {0, 21}, {0, 22}, {12, 22}}, color = {0, 0, 127}));
    connect(magnetpower.Hflow_tot, cryogenicpower.Magnet_HFlow) annotation(
        Line(points = {{-24, 21}, {0, 21}, {0, 22}, {12, 22}}, color = {0, 0, 127}));
    connect(hcdsystem.P_amb, wasteheatpower.HCDheat) annotation(
        Line(points = {{-10.5, -19}, {6, -19}, {6, -38}, {55, -38}}, color = {0, 0, 127}));
    connect(magnetpower.ambHeat, wasteheatpower.Magnetheat) annotation(
        Line(points = {{-24, 17}, {10, 17}, {10, -34}, {55, -34}}, color = {0, 0, 127}));
    connect(cryogenicpower.P_amb, wasteheatpower.Cryoheat) annotation(
        Line(points = {{34, 24}, {46, 24}, {46, -42}, {55, -42}}, color = {0, 0, 127}));
    connect(magnetpower.cryoHeat_PF, cryogenicpower.Magnetheat_PF) annotation(
        Line(points = {{-24, 24}, {10, 24}, {10, 26}, {10, 26}}, color = {0, 0, 127}));
  end Interdependencies;
end Tokamak;
