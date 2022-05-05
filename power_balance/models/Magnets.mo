/* !!! Jinja statements are for code substitution and should not be removed !!!

   Please ensure Modelica code in the tagged Jinja statements is also updated
   where appropriate when changes are made to the sources. Jinja statements are
   comments prefixed with "<jinja>"
*/

//<jinja>{% raw %}
package Magnets "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  partial model BaseMagnet "A partial model to act as a platform on which specialized magnet systems can be built."
    import SI = Modelica.SIunits;
    //
    // =============================== Define Outputs ============================
    Modelica.Blocks.Interfaces.RealInput i_in(unit = "A") "Real current input" annotation(
      Placement(visible = true, transformation(origin = {-114, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-114, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealOutput P_amb(unit = "W") "Heat dissipated at room temp" annotation(
      Placement(visible = true, transformation(origin = {110, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {110, 50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput P_cryo(unit = "W") "Heat dissipated in cryo plant" annotation(
      Placement(visible = true, transformation(origin = {110, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {110, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput P_tot(unit = "W") "Total electrical power input" annotation(
      Placement(visible = true, transformation(origin = {110, -90}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {110, -90}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealOutput Hflow(unit = "g/s") "Mass flow rate of cryogenic Helium" annotation(
      Placement(visible = true, transformation(extent = {{100, 60}, {120, 80}}, rotation = 0), iconTransformation(extent = {{100, 60}, {120, 80}}, rotation = 0)));
    //
    // ============================= Define Parameters ===========================
    parameter Boolean isSuperconFeeder = false "Set to true switches to superconductor feeder";
    parameter Boolean isSuperconCoil = false "Set to true switches to superconductor coil, otherwise cryoalumnium coil";
    parameter Boolean useSuperconModel = true "Set to false switches to an inductance only coil, otherwise use superconductor model (if isSuperconCoil is true)";
    parameter Boolean isPSUeffValue = false "Set to true to use value for power supply efficiency, false for model";
    //
    // ========================== Power Supply Parameters ========================
    parameter SI.Voltage __Vdrop = 1.45 "Voltage drop across a switching branch in the rectifier";
    parameter Real __PSUefficiency = 0.95 "Default PSU efficiency value";
    //
    // ============================ Feeder Parameters ============================
    parameter SI.Resistance __Rfeeder = 1e-7 "Resistance of the feeder";
    parameter Real __Feeder_Qk = 0.1 "Conduction loss through feeder/Maximum current through coil (W/kA/lead)";
    parameter Real __Feeder_m = 0.005 "Coolant mass flow rate in feeders' heat exchanger/Maximum current through coil (g/s/kA/lead)";
    //
    // ============================ Coil Parameters ==============================
    parameter SI.Resistance __Rcoil = 1 "Resistance of the whole coil";
    parameter SI.Resistance __Rjoint = 1 "Resistance of a joint";
    parameter Real __nTurn = 1 "Number of turns in a coil";
    parameter Integer __JpTurn = 4 "Number of joints per turn";
    parameter Integer __numCoils = 1 "Number of coils in the system";
    parameter SI.Inductance __Lself = 1 "Self inductance of the coil";
    parameter SI.Current __maxCurrent = 10e3 "The maximum operating current in the coil, per turn. Can be supplied either externally or from the input profile";
    parameter SI.Length __coilLength = 10 "Circumference/length of one coil";
    parameter SI.Power __neutronicsPower = 1000 "The neutronic heating power deposited inside the coil";
    parameter SI.Resistance coilZeroOhmSuperconR = 1e-32 "Resistance to be used when the superconducting model is turned off, as it cannot be zero";
    //
    // ================== Supercon hysteresis model descaling ====================
    parameter Real numTapes = __maxCurrent / (0.4 * I_c) "Descaled number of tapes assuming operation at 40% of critical current";
    parameter SI.Length length = __numCoils * __nTurn * __coilLength "Lenght of all conductors in the coil system at hand";
    // Supercon details come from M. Sjostrom, 'Hysteresis modelling of high temperature superconductors', Infoscience, 2001. http://infoscience.epfl.ch/record/32848 (accessed Jan. 29, 2021)
    parameter SI.Current I_c = 16.85 "Supercon tape critical current";
    parameter Real N = 20 "Supercon tape power index";
    parameter Magnets.ResistancePerMetre R_bypass = 1e-3 "Resistance/length of the matrix/bypass material";
    parameter Magnets.ResistancePerMetre R_n = 1e8 "Normal state resistance/length of the superconductor";
    //
    // ======================= General Components ================================
    Modelica.Electrical.Analog.Sources.SignalCurrent current annotation(
      Placement(visible = true, transformation(origin = {-80, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Electrical.Analog.Basic.Ground ground annotation(
      Placement(visible = true, transformation(origin = {0, -90}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    // ==================== Power Supply Components ==============================
    Modelica.Electrical.Analog.Sources.ConstantVoltage powerSuppliesIdeal(V = __Vdrop * 2) if not isPSUeffValue annotation(
      Placement(visible = true, transformation(origin = {-80, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));
    Modelica.Electrical.Analog.Ideal.Short short_psu if isPSUeffValue annotation(
      Placement(visible = true, transformation(origin = {-52, -20}, extent = {{-9, -9}, {9, 9}}, rotation = 90)));
    // ======================== Feeder Components ================================
    Magnets.Superconductor.SuperconLayer superconFeeder(I_c = I_c, N = N, R_bypass = R_bypass, R_n = R_n, len = length, numTapes = numTapes) if isSuperconFeeder and useSuperconModel annotation(
      Placement(visible = true, transformation(origin = {-50, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Resistor resistiveFeeder(R = if (not useSuperconModel and isSuperconFeeder) then coilZeroOhmSuperconR else __Rfeeder) if not isSuperconFeeder or (not useSuperconModel and isSuperconFeeder) annotation(
      Placement(visible = true, transformation(origin = {-50, 70}, extent = {{-9, -9}, {9, 9}}, rotation = 0)));
    // ========================== Coil Components ================================
    Superconductor.SuperconLayer superconCoil(I_c = I_c, N = N, R_bypass = R_bypass, R_n = R_n, len = length, numTapes = numTapes) if isSuperconCoil and useSuperconModel annotation(
      Placement(visible = true, transformation(origin = {52, 30}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Resistor resistiveCoil(R = if (not useSuperconModel and isSuperconCoil) then coilZeroOhmSuperconR else __Rcoil) if not isSuperconCoil or (not useSuperconModel and isSuperconCoil) annotation(
      Placement(visible = true, transformation(origin = {50, 70}, extent = {{-9, -9}, {9, 9}}, rotation = 0)));
    Modelica.Electrical.Analog.Basic.Resistor joints(R = __Rjoint) annotation(
      Placement(visible = true, transformation(origin = {80, 0}, extent = {{-10, -10}, {10, 10}}, rotation = -90)));
    Modelica.Electrical.Analog.Basic.Inductor inductorCoil(L = __Lself) annotation(
      Placement(visible = true, transformation(origin = {0, 50}, extent = {{-9, -9}, {9, 9}}, rotation = 0)));
    //
    SI.Power LossFeeder "Variable for determining the loss in the feeder depending on the used model";
    SI.Power LossCoil "Variable for determining the loss in the coil depending on the used model";
    SI.Power feederLeak "Heat leaking through feeders into TF coil coolant loop";
    SI.Power P_load "Electrical load; P_load = P_tot * efficiency";
    //
  initial equation
    // ======================== Input Parameter Assertions =======================
    assert(__numCoils >= 1, "---> Assertion Error in [BaseMagnet], input parameter [numCoils = " + String(__numCoils) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__JpTurn >= 0, "---> Assertion Error in [BaseMagnet], input parameter [__JpTurn = " + String(__JpTurn) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Rjoint >= 1e-10 and __Rjoint <= 1e-5, "---> Assertion Warning in [BaseMagnet], input parameter [__Rjoint = " + String(__Rjoint) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Rjoint > 0, "---> Assertion Error in [BaseMagnet], input parameter [__Rjoint = " + String(__Rjoint) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Rcoil >= 1e-10 and __Rcoil <= 1e-5, "---> Assertion Warning in [BaseMagnet], input parameter [__Rcoil = " + String(__Rcoil) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Rcoil > 0, "---> Assertion Error in [BaseMagnet], input parameter [__Rcoil = " + String(__Rcoil) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Vdrop >= 0.5 and __Vdrop <= 200, "---> Assertion Warning in [BaseMagnet], input parameter [Vdrop = " + String(__Vdrop) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Vdrop > 0, "---> Assertion Error in [BaseMagnet], input parameter [Vdrop = " + String(__Vdrop) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Rfeeder >= 1e-10 and __Rfeeder <= 1e-4, "---> Assertion Warning in [BaseMagnet], input parameter [Rfeeder = " + String(__Rfeeder) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Rfeeder > 0, "---> Assertion Error in [BaseMagnet], input parameter [Rfeeder = " + String(__Rfeeder) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__nTurn <= 500, "---> Assertion Warning in [BaseMagnet], input parameter [nTurn = " + String(__nTurn) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__nTurn >= 1, "---> Assertion Error in [BaseMagnet], input parameter [nTurn = " + String(__nTurn) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__maxCurrent <= 5e5, "---> Assertion Warning in [BaseMagnet], input parameter [maxCurrent = " + String(__nTurn) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__maxCurrent >= 0, "---> Assertion Error in [BaseMagnet], input parameter [maxCurrent = " + String(__maxCurrent) + "] cannot be negative!", level = AssertionLevel.error);
    assert(__coilLength >= 6 and __coilLength <= 1e5, "---> Assertion Warning in [BaseMagnet], input parameter [coilLength = " + String(__maxCurrent) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__coilLength >= 0, "---> Assertion Error in [BaseMagnet], input parameter [coilLength = " + String(__coilLength) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Feeder_Qk >= 0.05 and __Feeder_Qk <= 0.45, "---> Assertion Warning in [BaseMagnet], input parameter [Feeder_Qk = " + String(__Feeder_Qk) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Feeder_Qk > 0 and __Feeder_Qk <= 0.7, "---> Assertion Error in [BaseMagnet], input parameter [Feeder_Qk = " + String(__Feeder_Qk) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__Feeder_m >= 0.02 and __Feeder_m <= 0.3, "---> Assertion Warning in [BaseMagnet], input parameter [Feeder_m = " + String(__Feeder_m) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__Feeder_m > 0 and __Feeder_m <= 0.6, "---> Assertion Error in [BaseMagnet], input parameter [Feeder_m = " + String(__Feeder_m) + "] outside of acceptable range!", level = AssertionLevel.error);
    assert(__neutronicsPower >= 0, "---> Assertion Error in [BaseMagnet], input parameter [neutronicsPower = " + String(__neutronicsPower) + "] cannot be negative!", level = AssertionLevel.error);
    assert(__neutronicsPower <= 1e6, "---> Assertion Warning in [BaseMagnet], input parameter [neutronicsPower = " + String(__neutronicsPower) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(__PSUefficiency >= 0 and __PSUefficiency <= 1, "---> Assertion Error in [BaseMagnet], input parameter [PSUefficiency = " + String(__PSUefficiency) + "] outside of acceptable range!", level = AssertionLevel.error);
    //
  equation
    LossFeeder = if (isSuperconFeeder and useSuperconModel) then numTapes * superconFeeder.LossPower else resistiveFeeder.LossPower;
    LossCoil = if (isSuperconCoil and useSuperconModel) then numTapes * superconCoil.LossPower else resistiveCoil.LossPower;
    // picks the correct variable name depending on the model setup
    feederLeak = __Feeder_Qk * (__maxCurrent / 1e3) * __numCoils;
    // Heat leaking through feeders proportional to current rating of feeders.
    Hflow = __Feeder_m * (__maxCurrent / 1e3) * __numCoils;
    // Cryogenic helium mass flow rate through feeders heat exchanger proportional to current rating of feeders.
    // nTFcoils is used to indicate the number of feeders (assumed one feeder per TF pair as ITER, and we have a supply and return feeder)
    P_cryo = abs(LossFeeder) + abs(LossCoil) + abs(joints.LossPower) + feederLeak + __neutronicsPower;
    P_load = current.i * (-current.v);
    P_tot = if isPSUeffValue then P_load / __PSUefficiency else P_load;
    P_amb = if isPSUeffValue then abs(P_load * (1 - __PSUefficiency) / __PSUefficiency) else abs(powerSuppliesIdeal.i * powerSuppliesIdeal.v);
    //
    connect(i_in, current.i) annotation(
      Line(points = {{-114, -60}, {-92, -60}}, color = {0, 0, 127}));
    connect(current.p, ground.p) annotation(
      Line(points = {{-80, -70}, {-80, -80}, {0, -80}}, color = {0, 0, 255}));
    connect(resistiveCoil.n, joints.p) annotation(
      Line(points = {{60, 70}, {70, 70}, {70, 52}, {80, 52}, {80, 10}, {80, 10}}, color = {0, 0, 255}));
    connect(superconCoil.n, joints.p) annotation(
      Line(points = {{62, 30}, {70, 30}, {70, 52}, {80, 52}, {80, 10}}, color = {0, 0, 255}));
    connect(current.n, powerSuppliesIdeal.p) annotation(
      Line(points = {{-80, -50}, {-80, -50}, {-80, -30}, {-80, -30}}, color = {0, 0, 255}));
    connect(powerSuppliesIdeal.n, resistiveFeeder.p) annotation(
      Line(points = {{-80, -10}, {-80, -10}, {-80, 50}, {-70, 50}, {-70, 70}, {-58, 70}, {-58, 70}}, color = {0, 0, 255}));
    connect(powerSuppliesIdeal.n, superconFeeder.p) annotation(
      Line(points = {{-80, -10}, {-80, -10}, {-80, 50}, {-70, 50}, {-70, 30}, {-60, 30}, {-60, 30}}, color = {0, 0, 255}));
    connect(resistiveCoil.p, inductorCoil.n) annotation(
      Line(points = {{42, 70}, {30, 70}, {30, 50}, {10, 50}, {10, 50}}, color = {0, 0, 255}));
    connect(superconCoil.p, inductorCoil.n) annotation(
      Line(points = {{42, 30}, {30, 30}, {30, 50}, {10, 50}, {10, 50}}, color = {0, 0, 255}));
    connect(joints.n, ground.p) annotation(
      Line(points = {{80, -10}, {80, -10}, {80, -80}, {0, -80}, {0, -80}}, color = {0, 0, 255}));
    connect(resistiveFeeder.n, inductorCoil.p) annotation(
      Line(points = {{-40, 70}, {-32, 70}, {-32, 50}, {-8, 50}, {-8, 50}}, color = {0, 0, 255}));
    connect(superconFeeder.n, inductorCoil.p) annotation(
      Line(points = {{-40, 30}, {-32, 30}, {-32, 50}, {-8, 50}, {-8, 50}}, color = {0, 0, 255}));
    connect(short_psu.p, current.n) annotation(
      Line(points = {{-52, -30}, {-52, -40}, {-80, -40}, {-80, -50}}, color = {0, 0, 255}));
    connect(short_psu.n, superconFeeder.p) annotation(
      Line(points = {{-52, -10}, {-52, 0}, {-80, 0}, {-80, 50}, {-70, 50}, {-70, 30}, {-60, 30}}, color = {0, 0, 255}));
    connect(short_psu.n, resistiveFeeder.p) annotation(
      Line(points = {{-52, -10}, {-52, 0}, {-80, 0}, {-80, 50}, {-70, 50}, {-70, 70}, {-58, 70}}, color = {0, 0, 255}));
    //
    // Runtime assertions for BaseMagnet variables (Ranges are only temporary for testing. USE CORRECT RANGES IN FINAL VERSION!)
    assert(LossFeeder >= 0, "---> Assertion Error in [BaseMagnet], variable [LossFeeder = " + String(LossFeeder) + "] cannot be negative!", level = AssertionLevel.error);
    assert(LossFeeder <= 1e6, "---> Assertion Warning in [BaseMagnet], variable [LossFeeder = " + String(LossFeeder) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(LossCoil >= 0, "---> Assertion Error in [BaseMagnet], variable [LossCoil = " + String(LossCoil) + "] cannot be negative!", level = AssertionLevel.error);
    assert(LossCoil <= 1e7, "---> Assertion Warning in [BaseMagnet], variable [LossCoil = " + String(LossCoil) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(feederLeak >= 0, "---> Assertion Error in [BaseMagnet], variable [feederLeak = " + String(feederLeak) + "] cannot be negative!", level = AssertionLevel.error);
    assert(feederLeak <= 1000, "---> Assertion Warning in [BaseMagnet], variable [feederLeak = " + String(feederLeak) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(Hflow >= 0, "---> Assertion Error in [BaseMagnet], variable [Hflow = " + String(Hflow) + "] cannot be negative!", level = AssertionLevel.error);
    assert(Hflow <= 100, "---> Assertion Warning in [BaseMagnet], variable [Hflow = " + String(Hflow) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(P_amb >= 0, "---> Assertion Error in [BaseMagnet], variable [P_amb = " + String(P_amb) + "] cannot be negative!", level = AssertionLevel.error);
    assert(P_amb <= 1e6, "---> Assertion Warning in [BaseMagnet], variable [P_amb = " + String(P_amb) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(P_tot >= (-2e8) and P_tot <= 2e8, "Assertion Error in [BaseMagnet], variable [P_tot = " + String(P_tot) + "] outside of acceptable range!", level = AssertionLevel.warning);
    assert(P_tot >= (-1e8) and P_tot <= 1e8, "Assertion Warning in [BaseMagnet], variable [P_tot = " + String(P_tot) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(P_cryo >= 0, "---> Assertion Error in [BaseMagnet], variable [P_cryo = " + String(P_cryo) + "] cannot be negative!", level = AssertionLevel.error);
    assert(P_cryo <= 2e6, "---> Assertion Warning in [BaseMagnet], variable [P_cryo = " + String(P_cryo) + "] outside of reasonable range!", level = AssertionLevel.warning);
  protected
    annotation(
      defaultComponentName = "MagnetCoil",
      Diagram(coordinateSystem(preserveAspectRatio = false, initialScale = 0.1), graphics = {Rectangle(origin = {48, 53}, lineColor = {255, 170, 0}, fillColor = {255, 255, 191}, pattern = LinePattern.Dash, lineThickness = 1, extent = {{-64, 27}, {42, -73}}, radius = 5), Rectangle(origin = {-52, 47}, lineColor = {255, 0, 255}, fillColor = {255, 213, 224}, pattern = LinePattern.Dash, lineThickness = 1, extent = {{-26, 33}, {28, -33}}, radius = 5), Rectangle(origin = {-65.2337, -20.2972}, lineColor = {85, 255, 0}, fillColor = {220, 255, 201}, pattern = LinePattern.Dash, lineThickness = 1, extent = {{-28.7663, 21.9174}, {26.465, -21.9174}}, radius = 5), Text(origin = {-50, 86}, extent = {{-16, 4}, {16, -4}}, textString = "Feeder"), Text(origin = {-50, -46}, extent = {{-16, 4}, {16, -4}}, textString = "Power Supply"), Text(origin = {58, 86}, extent = {{-16, 4}, {16, -4}}, textString = "Coil"), Polygon(origin = {0, -120}, lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-134, 63}, {-124, 60}, {-134, 57}, {-134, 63}}), Line(origin = {-3.17759, -119.461}, points = {{-150, 60}, {-125, 60}}, color = {160, 160, 164}), Polygon(origin = {4, -22}, lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{141, -57}, {151, -60}, {141, -63}, {141, -57}}), Line(origin = {-1.2193, -22.6656}, points = {{125, -60}, {150, -60}}, color = {160, 160, 164}, thickness = 0.5), Text(origin = {-8, -26}, lineColor = {160, 160, 164}, extent = {{128, -56}, {148, -41}}, textString = "Power"), Text(origin = {2, -122}, lineColor = {160, 160, 164}, extent = {{-150, 63}, {-133, 78}}, textString = "i"), Polygon(origin = {0, -120}, lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-134, 63}, {-124, 60}, {-134, 57}, {-134, 63}}), Line(origin = {-3.17759, -119.459}, points = {{-150, 60}, {-125, 60}}, color = {160, 160, 164}, thickness = 0.5), Polygon(origin = {284, -14}, lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-134, 63}, {-124, 60}, {-134, 57}, {-134, 63}}), Line(origin = {274.655, -13.8252}, points = {{-150, 60}, {-125, 60}}, color = {160, 160, 164}, thickness = 0.5), Text(origin = {2, -122}, lineColor = {160, 160, 164}, extent = {{-150, 63}, {-133, 78}}, textString = "i"), Text(origin = {290, -12}, lineColor = {160, 160, 164}, extent = {{-150, 63}, {-133, 78}}, textString = "Heat")}),
      Icon(coordinateSystem(preserveAspectRatio = false, initialScale = 0.1), graphics = {Line(points = {{-30, 100}, {-90, 100}}, color = {0, 0, 255}), Line(points = {{-30, -100}, {-90, -100}}, color = {0, 0, 255}), Line(points = {{0, 80}, {-100, 80}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{-100, 80}, {-100, -80}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{0, -80}, {-100, -80}}, color = {0, 0, 255}, pattern = LinePattern.Dash), Line(points = {{100, 80}, {0, 80}}, color = {255, 127, 0}, pattern = LinePattern.Dash), Line(points = {{100, -80}, {0, -80}}, color = {255, 127, 0}, pattern = LinePattern.Dash), Line(points = {{100, 80}, {100, -80}}, color = {255, 127, 0}, pattern = LinePattern.Dash), Ellipse(lineColor = {255, 127, 0}, extent = {{-4, -34}, {64, 34}}, endAngle = 360), Line(points = {{30, -100}, {30, -34}}, color = {255, 127, 0}), Line(points = {{18, 0}, {42, 0}}, color = {255, 127, 0}), Line(points = {{42, 10}, {42, -12}}, color = {255, 127, 0}), Line(points = {{30, 34}, {30, 100}}, color = {255, 127, 0}), Line(points = {{30, 100}, {90, 100}}, color = {255, 127, 0}), Line(points = {{30, -100}, {90, -100}}, color = {255, 127, 0}), Text(lineColor = {0, 0, 255}, extent = {{-150, 150}, {150, 110}}, textString = "%name"), Line(points = {{18, 10}, {18, -12}}, color = {255, 127, 0}), Line(points = {{-110, 30}, {-110, -30}}, color = {0, 0, 255}), Polygon(lineColor = {0, 0, 255}, fillColor = {0, 0, 255}, fillPattern = FillPattern.Solid, points = {{-110, -30}, {-104, -10}, {-116, -10}, {-110, -30}}), Line(points = {{110, 32}, {110, -28}}, color = {255, 128, 0}), Polygon(lineColor = {255, 128, 0}, fillColor = {255, 128, 0}, fillPattern = FillPattern.Solid, points = {{110, -28}, {116, -8}, {104, -8}, {110, -28}}), Rectangle(lineColor = {255, 128, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{72, 28}, {88, -24}}), Line(points = {{80, 28}, {80, 100}}, color = {255, 128, 0}), Line(points = {{80, -24}, {80, -100}}, color = {255, 128, 0}), Line(origin = {-23, 45}, rotation = 270, points = {{-15, -7}, {-14, -1}, {-7, 7}, {7, 7}, {14, -1}, {15, -7}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {-23, 15}, rotation = 270, points = {{-15, -7}, {-14, -1}, {-7, 7}, {7, 7}, {14, -1}, {15, -7}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {-23, -15}, rotation = 270, points = {{-15, -7}, {-14, -1}, {-7, 7}, {7, 7}, {14, -1}, {15, -7}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {-23, -45}, rotation = 270, points = {{-15, -7}, {-14, -1}, {-7, 7}, {7, 7}, {14, -1}, {15, -7}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(points = {{-30, 60}, {-30, 100}}, color = {28, 108, 200}), Line(points = {{-30, -100}, {-30, -60}}, color = {28, 108, 200})}),
      uses(Modelica(version = "3.2.3")));
  end BaseMagnet;

  model TF_Magnet "A specialized magnet model for a TF coil system."
    //
    import SI = Modelica.SIunits;
    extends Magnets.BaseMagnet(
      __Rjoint = __numCoils * __JpTurn * __nTurn * (if isSuperconCoil then __Rjoint_Supercon else __Rjoint_Resistive),
      __numCoils = 18,
      __neutronicsPower = 10e3);
    //
    parameter SI.Resistance __Rjoint_Supercon = 200e-9 "Resistance per joint in superconductor";
    parameter SI.Resistance __Rjoint_Resistive = 20e-9 "Resistance per joint in cryoaluminium";
    //
  initial equation
    // ====================== Input Parameter Assertions =========================
    assert(__Rjoint_Supercon <= 5e-9, "---> Assertion Warning in [TF Magnet], input parameter [Rjoint_Supercon = "+String(__Rjoint_Supercon)+"] outside of reasonable range", AssertionLevel.warning);
    assert(__Rjoint_Supercon > 0, "---> Assertion Error in [TF Magnet], input parameter [Rjoint_Supercon = "+String(__Rjoint_Supercon)+"] outside of acceptable range", AssertionLevel.error);
    assert(__Rjoint_Resistive <= 5e-9, "---> Assertion Warning in [TF Magnet], input parameter [Rjoint_Resistive = "+String(__Rjoint_Resistive)+"] outside of reasonable range", AssertionLevel.warning);
    assert(__Rjoint_Resistive > 0, "---> Assertion Error in [TF Magnet], input parameter [Rjoint_Resistive = "+String(__Rjoint_Resistive)+"] outside of acceptable range", AssertionLevel.error);
  equation
    //
  protected
    annotation(
      defaultComponentName = "magsys_TF",
      Diagram(graphics = {Text(origin = {-47, -58}, extent = {{-13, 8}, {47, -12}}, textString = "This is a TF coil model."), Rectangle(origin = {-30, -60}, lineThickness = 0.2, extent = {{-34, 6}, {34, -6}})}));
  end TF_Magnet;

  model PF_Magnet "A specialized magnet model for a PF coil system"
    import SI = Modelica.SIunits;
    extends Magnets.BaseMagnet(
      __Rcoil = 1e-32,
      __Rjoint = 1e-9,
      __JpTurn = 0,
      __Rfeeder = 1e-9,
      __Lself = 0.1,
      __numCoils = 1,
      __maxCurrent = 10e3,
      isSuperconCoil = true);
    //
  equation
    //
  protected
    annotation(
      defaultComponentName = "magsys_PFx",
      Diagram(graphics = {Rectangle(origin = {-30, -60}, lineThickness = 0.2, extent = {{-34, 6}, {34, -6}}), Text(origin = {-47, -58}, extent = {{-13, 8}, {47, -12}}, textString = "This is a PF coil model.")}));
  end PF_Magnet;

  model MagnetPower
    Modelica.Blocks.Interfaces.RealOutput cryoHeat_PF(unit = "W") "PF coils heat dissipated in cryo plant" annotation(
      Placement(visible = true, transformation(extent = {{200, 40}, {220, 60}}, rotation = 0), iconTransformation(extent = {{200, 40}, {220, 60}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput Hflow_tot(unit = "g/s") "All coils coolant flow" annotation(
      Placement(visible = true, transformation(extent = {{200, 80}, {220, 100}}, rotation = 0), iconTransformation(extent = {{200, 80}, {220, 100}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput cryoHeat_TF(unit = "W") "TF coils heat dissipated in cryo plant" annotation(
      Placement(visible = true, transformation(extent = {{200, 0}, {220, 20}}, rotation = 0), iconTransformation(extent = {{200, 0}, {220, 20}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealOutput ambHeat(unit = "W") "Heat dissipated to air" annotation(
      Placement(visible = true, transformation(extent = {{200, -40}, {220, -20}}, rotation = 0), iconTransformation(extent = {{200, -40}, {220, -20}}, rotation = 0)));
    //
    // ==================== Defining Structural Parameters =======================
    parameter Boolean useSuperconModel = true "STRUCTURAL_PARAMETER";
    parameter Boolean isPSUeffValue = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetTFSuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetTFSuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF1SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF1SuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF2SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF2SuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF3SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF3SuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF4SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF4SuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF5SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF5SuperconFeeder = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF6SuperconCoil = false "STRUCTURAL_PARAMETER";
    parameter Boolean isMagnetPF6SuperconFeeder = false "STRUCTURAL_PARAMETER";
  //<jinja>{% endraw %}
  /*<jinja>{% for magnet in pf_magnets %}    parameter Boolean isMagnetPF{{magnet.ID}}SuperconCoil = false "STRUCTURAL_PARAMETER";
        parameter Boolean isMagnetPF{{magnet.ID}}SuperconFeeder = false "STRUCTURAL_PARAMETER";{% endfor %}</jinja>*/
  //<jinja>{% raw %}
    //
    // ================= Declare instances of magnet blocks ======================
    TF_Magnet magnetTF(isSuperconCoil = isMagnetTFSuperconCoil, isSuperconFeeder = isMagnetTFSuperconFeeder, __maxCurrent = combiTimeTableTF.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {62, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF1(isSuperconCoil = isMagnetPF1SuperconCoil, isSuperconFeeder = isMagnetPF1SuperconFeeder, __maxCurrent = combiTimeTablePF1.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, 86}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF2(isSuperconCoil = isMagnetPF2SuperconCoil, isSuperconFeeder = isMagnetPF2SuperconFeeder, __maxCurrent = combiTimeTablePF2.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, 52}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF3(isSuperconCoil = isMagnetPF3SuperconCoil, isSuperconFeeder = isMagnetPF3SuperconFeeder, __maxCurrent = combiTimeTablePF3.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF4(isSuperconCoil = isMagnetPF4SuperconCoil, isSuperconFeeder = isMagnetPF4SuperconFeeder, __maxCurrent = combiTimeTablePF4.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, -18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF5(isSuperconCoil = isMagnetPF5SuperconCoil, isSuperconFeeder = isMagnetPF5SuperconFeeder, __maxCurrent = combiTimeTablePF5.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    PF_Magnet magnetPF6(isSuperconCoil = isMagnetPF6SuperconCoil, isSuperconFeeder = isMagnetPF6SuperconFeeder, __maxCurrent = combiTimeTablePF6.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue) annotation(
      Placement(visible = true, transformation(origin = {-50, -78}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  //<jinja>{% endraw %}
  //<jinja>{% for magnet in pf_magnets %}    PF_Magnet magnetPF{{magnet.ID}}(isSuperconCoil = isMagnetPF{{magnet.ID}}SuperconCoil, isSuperconFeeder = isMagnetPF{{magnet.ID}}SuperconFeeder, __maxCurrent = combiTimeTablePF{{magnet.profile_id}}.value_max, useSuperconModel = useSuperconModel, isPSUeffValue = isPSUeffValue);{% endfor %}
  //<jinja>{% raw %}
    //
    // =============== Declare profile inputs for magnet currents ================
    Utilities.CombiTimeTable combiTimeTableCS(fileName = __CurrentDataPathCS, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {30, 20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF6(fileName = __CurrentDataPathPF6, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, -78}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF5(fileName = __CurrentDataPathPF5, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF4(fileName = __CurrentDataPathPF4, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, -18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF3(fileName = __CurrentDataPathPF3, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, 18}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF2(fileName = __CurrentDataPathPF2, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, 52}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTablePF1(fileName = __CurrentDataPathPF1, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {-82, 86}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Utilities.CombiTimeTable combiTimeTableTF(fileName = __CurrentDataPathTF, smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "data", tableOnFile = true) annotation(
      Placement(visible = true, transformation(origin = {30, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    //
    // ==================== Manually defined values ==============================
    parameter String __CurrentDataPathCS = "currentCS.mat";
    parameter String __CurrentDataPathPF6 = "currentPF6.mat";
    parameter String __CurrentDataPathPF5 = "currentPF5.mat";
    parameter String __CurrentDataPathPF4 = "currentPF4.mat";
    parameter String __CurrentDataPathPF3 = "currentPF3.mat";
    parameter String __CurrentDataPathPF2 = "currentPF2.mat";
    parameter String __CurrentDataPathPF1 = "currentPF1.mat";
    parameter String __CurrentDataPathTF = "currentTF.mat";
    Real ElecPowerConsumed(unit = "W") "Total power consumption. Do not change name.";
    //
  equation
    // ======================= Manually defined equations =============================
  //<jinja>{% endraw %}
  //<jinja>{#
    ambHeat = magnetTF.P_amb + magnetPF1.P_amb + magnetPF2.P_amb + magnetPF3.P_amb + magnetPF4.P_amb + magnetPF5.P_amb + magnetPF6.P_amb;
  //</jinja>#}
  //<jinja>    ambHeat = magnetTF.P_amb + magnetPF1.P_amb + magnetPF2.P_amb + magnetPF3.P_amb + magnetPF4.P_amb + magnetPF5.P_amb + magnetPF6.P_amb{% for magnet in pf_magnets %} + magnetPF{{magnet.ID}}.P_amb{% endfor %};
    // ================= Heat dissipated at cryogenic temperature =====================
    cryoHeat_TF = magnetTF.P_cryo;
  //<jinja>{#
    cryoHeat_PF = magnetPF1.P_cryo + magnetPF2.P_cryo + magnetPF3.P_cryo + magnetPF4.P_cryo + magnetPF5.P_cryo + magnetPF6.P_cryo;
    Hflow_tot = magnetTF.Hflow + magnetPF1.Hflow + magnetPF2.Hflow + magnetPF3.Hflow + magnetPF4.Hflow + magnetPF5.Hflow + magnetPF6.Hflow;
    ElecPowerConsumed = magnetTF.P_tot + magnetPF1.P_tot + magnetPF2.P_tot + magnetPF3.P_tot + magnetPF4.P_tot + magnetPF5.P_tot + magnetPF6.P_tot;
  //</jinja>#}
  /*<jinja>cryoHeat_PF = magnetPF1.P_cryo + magnetPF2.P_cryo + magnetPF3.P_cryo + magnetPF4.P_cryo + magnetPF5.P_cryo + magnetPF6.P_cryo{% for magnet in pf_magnets %} + magnetPF{{magnet.ID}}.P_cryo{% endfor %};
    Hflow_tot = magnetTF.Hflow + magnetPF1.Hflow + magnetPF2.Hflow + magnetPF3.Hflow + magnetPF4.Hflow + magnetPF5.Hflow + magnetPF6.Hflow{% for magnet in pf_magnets %} + magnetPF{{magnet.ID}}.Hflow{% endfor %};
    ElecPowerConsumed = magnetTF.P_tot + magnetPF1.P_tot + magnetPF2.P_tot + magnetPF3.P_tot + magnetPF4.P_tot + magnetPF5.P_tot + magnetPF6.P_tot{% for magnet in pf_magnets %} + magnetPF{{magnet.ID}}.P_tot{% endfor %};</jinja>*/
  //<jinja>{% raw %}
    // Defined in Block Diagram
    connect(combiTimeTablePF6.y[1], magnetPF6.i_in) annotation(
      Line(points = {{-70, -78}, {-60, -78}, {-60, -78}, {-60, -78}}, color = {0, 0, 127}));
    connect(combiTimeTablePF5.y[1], magnetPF5.i_in) annotation(
      Line(points = {{-70, -48}, {-62, -48}, {-62, -48}, {-60, -48}}, color = {0, 0, 127}));
    connect(combiTimeTablePF4.y[1], magnetPF4.i_in) annotation(
      Line(points = {{-70, -18}, {-62, -18}, {-62, -18}, {-60, -18}}, color = {0, 0, 127}));
    connect(combiTimeTablePF3.y[1], magnetPF3.i_in) annotation(
      Line(points = {{-70, 18}, {-62, 18}, {-62, 18}, {-60, 18}}, color = {0, 0, 127}));
    connect(combiTimeTablePF2.y[1], magnetPF2.i_in) annotation(
      Line(points = {{-70, 52}, {-62, 52}, {-62, 52}, {-60, 52}}, color = {0, 0, 127}));
    connect(combiTimeTablePF1.y[1], magnetPF1.i_in) annotation(
      Line(points = {{-71, 86}, {-60, 86}}, color = {0, 0, 127}));
    connect(combiTimeTableTF.y[1], magnetTF.i_in) annotation(
      Line(points = {{41, 60}, {51, 60}}, color = {0, 0, 127}));
  //<jinja>{% endraw %}
  //<jinja>{% for magnet in pf_magnets %}    connect(combiTimeTablePF{{magnet.profile_id}}.y[1], magnetPF{{magnet.ID}}.i_in);{% endfor %}
  //<jinja>{% raw %}
    connect(combiTimeTableTF.y[1], magnetTF.i_in) annotation(
      Line(points = {{41, 60}, {51, 60}}, color = {0, 0, 127}));
    //
    // Runtime Assertions for MagnetPower (Ranges are only temporary for testing. USE CORRECT RANGES IN FINAL VERSION!)
    assert(ElecPowerConsumed >= (-2e9) and ElecPowerConsumed <= 2e9, "---> Assertion Error in [MagnetPower], variable [ElecPowerConsumed = " + String(ElecPowerConsumed) + "] outside outside of acceptable range!", level = AssertionLevel.warning);
    assert(ElecPowerConsumed >= (-1e9) and ElecPowerConsumed <= 1e9, "---> Assertion Warning in [MagnetPower], variable [ElecPowerConsumed = " + String(ElecPowerConsumed) + "] outside outside of reasonable range!", level = AssertionLevel.warning);
    assert(ambHeat >= 0, "---> Assertion Error in [MagnetPower], variable [ambHeat = " + String(ambHeat) + "] outside cannot be negative!", level = AssertionLevel.error);
    assert(ambHeat <= 100e6, "---> Assertion Warning in [MagnetPower], variable [ambHeat = " + String(ambHeat) + "] outside outside of reasonable range!", level = AssertionLevel.warning);
    assert(cryoHeat_PF >= 0, "---> Assertion Error in [MagnetPower], variable [cryoHeat_PF = " + String(cryoHeat_PF) + "] outside cannot be negative!", level = AssertionLevel.error);
    assert(cryoHeat_PF <= 1e6, "---> Assertion Warning in [MagnetPower], variable [cryoHeat_PF = " + String(cryoHeat_PF) + "] outside outside of reasonable range!", level = AssertionLevel.warning);
    assert(cryoHeat_TF >= 0, "---> Assertion Error in [MagnetPower], variable [cryoHeat_TF = " + String(cryoHeat_TF) + "] outside cannot be negative!", level = AssertionLevel.error);
    assert(cryoHeat_TF <= 2e6, "---> Assertion Warning in [MagnetPower], variable [cryoHeat_TF = " + String(cryoHeat_TF) + "] outside outside of reasonable range!", level = AssertionLevel.warning);
    assert(Hflow_tot >= 0, "---> Assertion Error in [MagnetPower], variable [Hflow_tot = " + String(Hflow_tot) + "] outside cannot be negative!", level = AssertionLevel.error);
    assert(Hflow_tot <= 3e6, "---> Assertion Warning in [MagnetPower], variable [Hflow_tot = " + String(Hflow_tot) + "] outside outside of reasonable range!", level = AssertionLevel.warning);
    annotation(
      uses(Modelica(version = "3.2.3")),
      Diagram(coordinateSystem(extent = {{-200, -200}, {200, 200}})),
      Icon(coordinateSystem(extent = {{-200, -200}, {200, 200}})));
  end MagnetPower;

  package Superconductor
    class SuperconLayer "A model that can simulate a single superconducting tape or strand"
      //
      // EXTENDS
      import SI = Modelica.SIunits;
      // OUTPUTS
      Modelica.Blocks.Interfaces.RealOutput LossPower(unit = "W");
      // PARAMETERS
      parameter SI.Current I_c "Critical current" annotation(
        choicesAllMatching = true,
        Dialog(group = "I-V Power Law"));
      parameter Real N "Power index" annotation(
        choicesAllMatching = true,
        Dialog(group = "I-V Power Law"));
      parameter SI.ElectricFieldStrength E_0 = 1e-4 "Critical current criterion" annotation(
        choicesAllMatching = true,
        Dialog(group = "I-V Power Law"));
      parameter Magnets.ResistancePerMetre R_n "Normal state resistance/length of the superconductor" annotation(
        choicesAllMatching = true,
        Dialog(group = "I-V Power Law"));
      parameter SI.Length len "Length of sample" annotation(
        choicesAllMatching = true,
        Dialog(group = "I-V Power Law"));
      parameter Magnets.ResistancePerMetre R_bypass "Resistance/length of the matrix/bypass material" annotation(
        choicesAllMatching = true,
        Dialog(group = "Matrix material/bypass material"));
      parameter Real numTapes = 1 "Descaled number of tapes";
      parameter Data.HTS_EverettParameter mat = Data.HTS_EverettParameter() annotation(
        choicesAllMatching = true,
        Dialog(group = "Location of the Everett parameters"));
      //
      Magnets.Superconductor.SuperconResistive powerLaw(I_c = I_c, N = N, E_0 = E_0, len = len, R_n = R_n, numTapes = numTapes) annotation(
        Placement(visible = true, transformation(origin = {-20, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Magnets.Superconductor.ResistorDescaled bypass(R = len * R_bypass) if false annotation(
        Placement(visible = true, transformation(origin = {-20, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Magnets.Superconductor.Hysteresis.PreisachEverett hystPreisach(len = len, mat = mat, numTapes = numTapes) annotation(
        Placement(visible = true, transformation(origin = {20, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      //
      Modelica.Electrical.Analog.Interfaces.PositivePin p annotation(
        Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.NegativePin n annotation(
        Placement(visible = true, transformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      LossPower = hystPreisach.LossPower + powerLaw.LossPower;
      connect(p, powerLaw.p) annotation(
        Line(points = {{-100, 0}, {-50, 0}, {-50, 10}, {-30, 10}}, color = {0, 0, 255}));
      connect(p, bypass.p) annotation(
        Line(points = {{-100, 0}, {-50, 0}, {-50, -10}, {-30, -10}}, color = {0, 0, 255}));
      connect(powerLaw.n, hystPreisach.p) annotation(
        Line(points = {{-10, 10}, {10, 10}}, color = {0, 0, 255}));
      connect(bypass.n, n) annotation(
        Line(points = {{-10, -10}, {40, -10}, {40, 0}, {100, 0}, {100, 0}}, color = {0, 0, 255}));
      connect(hystPreisach.n, n) annotation(
        Line(points = {{30, 10}, {40, 10}, {40, 0}, {100, 0}, {100, 0}}, color = {0, 0, 255}));
    protected
      annotation(
        choicesAllMatching = true,
        Dialog(group = "Hysteresis data location"),
        Icon(graphics = {Rectangle(origin = {-1, 0}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-79, -60}, {81, 60}}), Line(origin = {-73, -1}, points = {{-27, 1}, {-7, 1}}, color = {0, 0, 255}), Line(origin = {70.8834, -1}, points = {{9, 1}, {27, 1}}, color = {0, 0, 255}), Text(origin = {-2, -236}, lineColor = {0, 0, 255}, extent = {{-150, 150}, {150, 110}}, textString = "%name"), Text(origin = {0, 58}, lineColor = {0, 0, 255}, extent = {{40, 0}, {40, -30}}, textString = "PE"), Line(origin = {8.12, 40.31}, points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}}), Polygon(origin = {-10, 40}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}), Line(origin = {-72.1875, -8.75}, points = {{0, -32}, {0, 68}}, color = {192, 192, 192}), Line(origin = {10.9375, 40.3125}, points = {{-84, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}, smooth = Smooth.Bezier), Polygon(origin = {-72, -30}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}), Line(origin = {-1.73, 0}, rotation = 180, points = {{-30, -20}, {-14, -20}, {-6, -16}, {2, 0}, {10, 16}, {18, 20}, {26, 20}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {2.27, 0}, points = {{-30, -20}, {-14, -20}, {-6, -16}, {2, 0}, {10, 16}, {18, 20}, {26, 20}}, color = {0, 0, 255}, smooth = Smooth.Bezier)}, coordinateSystem(initialScale = 0.1)));
    end SuperconLayer;

    class MutualInductor "Implementation of two basic inductors together with a mutual inductance between them"
      //
      // IMPORTS
      import SI = Modelica.SIunits;
      // PARAMETERS
      parameter SI.Inductance L1(start = 1) "Upper inductance";
      parameter SI.Inductance L2(start = 1) "Lower inductance";
      parameter SI.Inductance M(start = 1) "Coupling inductance";
      //
      SI.Voltage v1 "Voltage drop of port 1 (= p1.v - n1.v)";
      SI.Voltage v2 "Voltage drop of port 2 (= p2.v - n2.v)";
      SI.Current i1 "Current flowing from pos. to neg. pin of port 1";
      SI.Current i2 "Current flowing from pos. to neg. pin of port 2";
      Modelica.Electrical.Analog.Interfaces.PositivePin p1 "Positive electrical pin of port 1" annotation(
        Placement(visible = true, transformation(origin = {-100, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.PositivePin p2 "Positive electrical pin of port 2" annotation(
        Placement(visible = true, transformation(origin = {-100, -100}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, -100}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.NegativePin n1 "Negative electrical pin of port 1" annotation(
        Placement(visible = true, transformation(origin = {100, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, 100}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Electrical.Analog.Interfaces.NegativePin n2 "Negative electrical pin of port 2" annotation(
        Placement(visible = true, transformation(origin = {100, -100}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, -100}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      //
    equation
      v1 = L1 * der(i1) + M * der(i2);
      v2 = M * der(i1) + L2 * der(i2);
      // TWO PORT:
      v1 = p1.v - n1.v;
      v2 = p2.v - n2.v;
      0 = p1.i + n1.i;
      0 = p2.i + n2.i;
      i1 = p1.i;
      i2 = p2.i;
      //
      annotation(
        Icon(graphics = {Line(origin = {0.138582, 100.032}, points = {{-30, 0}, {-29, 6}, {-22, 14}, {-8, 14}, {-1, 6}, {0, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.138582, 100.032}, points = {{-60, 0}, {-59, 6}, {-52, 14}, {-38, 14}, {-31, 6}, {-30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.138582, 100.032}, points = {{0, 0}, {1, 6}, {8, 14}, {22, 14}, {29, 6}, {30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.138582, 100.032}, points = {{30, 0}, {31, 6}, {38, 14}, {52, 14}, {59, 6}, {60, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.142555, -99.9402}, points = {{-30, 0}, {-29, 6}, {-22, 14}, {-8, 14}, {-1, 6}, {0, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.142555, -99.9402}, points = {{-60, 0}, {-59, 6}, {-52, 14}, {-38, 14}, {-31, 6}, {-30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.142555, -99.9402}, points = {{0, 0}, {1, 6}, {8, 14}, {22, 14}, {29, 6}, {30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.142555, -99.9402}, points = {{30, 0}, {31, 6}, {38, 14}, {52, 14}, {59, 6}, {60, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Text(origin = {0, 84}, lineColor = {0, 0, 255}, extent = {{-150, 150}, {150, 110}}, textString = "%name"), Text(origin = {0, 212}, extent = {{-150, -40}, {150, -80}}, textString = "L1=%L1"), Text(origin = {0, -74}, extent = {{-150, -40}, {150, -80}}, textString = "L2=%L2"), Text(origin = {0, 62}, extent = {{-150, -40}, {150, -80}}, textString = "M=%M"), Line(origin = {70.7, -98.8}, points = {{-10, 0}, {-10, 0}}, color = {0, 0, 255}), Line(origin = {-80, -100}, points = {{20, 0}, {-20, 0}, {-20, 0}}, color = {0, 0, 255}), Line(origin = {80, -100}, points = {{-20, 0}, {20, 0}}, color = {0, 0, 255}), Line(origin = {-80, 100}, points = {{20, 0}, {-20, 0}}, color = {0, 0, 255}), Line(origin = {80, 100}, points = {{-20, 0}, {20, 0}}, color = {0, 0, 255}), Rectangle(pattern = LinePattern.Dash, extent = {{-180, 180}, {180, -180}})}, coordinateSystem(initialScale = 0.1)));
    end MutualInductor;

    model SuperconResistive "Resistive model of a superconductor's I-V relationship, employing a macroscopic power law."
      //
      // EXTENDS
      import SI = Modelica.SIunits;
      extends Modelica.Electrical.Analog.Interfaces.OnePort;
      // OUTPUTS
      output SI.Power LossPower "Ohmic losses in the component";
      // PARAMETERS
      parameter SI.ElectricFieldStrength E_0 = 1e-4 "Critical current criterion";
      parameter SI.Current I_c "Critical current";
      parameter Real N(unit = "1") "Power exponent";
      parameter Magnets.ResistancePerMetre R_n = 1e8 "Normal state resistance/lenght of the superconductor";
      parameter SI.Length len = 1 "Length of sample";
      parameter Real numTapes = 1 "Descaled number of tapes";
      //
      Magnets.ResistancePerMetre R_sc "Resistance/lenght given by the power law";
      SI.Resistance R "Actual resistance damped by the material's normal resistance";
      SI.Current i_local = i / numTapes "Descaled current";
      //
    equation
      R_sc = E_0 / I_c * abs(i_local / I_c) ^ (N - 1) "The Power Law";
      R = len * (R_sc * R_n / (R_sc + R_n)) "Limit the resistance and multiply by lenght";
      v = R * i "Generate the voltage drop";
      LossPower = i_local ^ 2 * R "Generate the power loss in the component";
      //
      annotation(
        Diagram(coordinateSystem(initialScale = 0.1), graphics = {Line(points = {{-110, 20}, {-85, 20}}, color = {160, 160, 164}), Polygon(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-95, 23}, {-85, 20}, {-95, 17}, {-95, 23}}), Line(points = {{90, 20}, {115, 20}}, color = {160, 160, 164}), Line(points = {{-125, 0}, {-115, 0}}, color = {160, 160, 164}), Line(points = {{-120, -5}, {-120, 5}}, color = {160, 160, 164}), Text(lineColor = {160, 160, 164}, extent = {{-110, 25}, {-90, 45}}, textString = "i"), Polygon(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{105, 23}, {115, 20}, {105, 17}, {105, 23}}), Line(points = {{115, 0}, {125, 0}}, color = {160, 160, 164}), Text(lineColor = {160, 160, 164}, extent = {{90, 45}, {110, 25}}, textString = "i")}),
        uses(Modelica(version = "3.2.3")),
        Icon(graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 90}, {150, 50}}, textString = "%name"), Line(origin = {-85, 0}, points = {{15, 0}, {-15, 0}}, color = {0, 0, 255}), Line(origin = {85, 0}, points = {{15, 0}, {-15, 0}}, color = {0, 0, 255}), Text(origin = {-40, -32}, lineColor = {0, 0, 255}, extent = {{40, 0}, {40, -22}}, textString = "superconductor", fontName = "Calibri"), Rectangle(lineColor = {0, 0, 255}, extent = {{-70, 30}, {70, -30}}), Line(origin = {0.336538, 0}, points = {{0, 0}, {1, 6}, {8, 14}, {22, 14}, {29, 6}, {30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.336538, 0}, points = {{-60, 0}, {-59, 6}, {-52, 14}, {-38, 14}, {-31, 6}, {-30, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.336538, 0}, points = {{30, 0}, {31, 6}, {38, 14}, {52, 14}, {59, 6}, {60, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {0.336538, 0}, points = {{-30, 0}, {-29, 6}, {-22, 14}, {-8, 14}, {-1, 6}, {0, 0}}, color = {0, 0, 255}, smooth = Smooth.Bezier)}, coordinateSystem(initialScale = 0.1)));
    end SuperconResistive;

    model ResistorDescaled
      extends Modelica.Electrical.Analog.Interfaces.OnePort;
      import SI = Modelica.SIunits;
      parameter SI.Resistance R(start = 1) "Resistance";
      parameter Real numTapes = 1 "Descaled number of tapes";
      SI.Current i_local = i / numTapes "Descaled current";
      output SI.Power LossPower;
    equation
      v = R * i_local;
      LossPower = i_local ^ 2 * R;
      annotation(
        Icon(graphics = {Line(points = {{70, 0}, {90, 0}}, color = {0, 0, 255}), Text(extent = {{-150, -40}, {150, -80}}, textString = "R=%R"), Text(lineColor = {0, 0, 255}, extent = {{-150, 90}, {150, 50}}, textString = "%name"), Rectangle(lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-70, 30}, {70, -30}}), Line(visible = false, points = {{0, -100}, {0, -30}}, color = {127, 0, 0}, pattern = LinePattern.Dot), Line(points = {{-90, 0}, {-70, 0}}, color = {0, 0, 255})}));
    end ResistorDescaled;

    package Hysteresis
      extends Modelica.Icons.VariantsPackage;

      model PreisachEverett "Superconductor I-Phi(V) hysteresis based on the Preisach model and Everett function data"
        //
        /*
        BSD 3-Clause License

        Copyright (c) 1998-2020, Modelica Association and contributors
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
        FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
        DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
        OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        */
        //
        // EXTENDS
        extends Modelica.Electrical.Analog.Interfaces.OnePort;
        import Modelica.Constants.eps;
        import SI = Modelica.SIunits;
        import Modelica.Constants.pi;
        // OUTPUTS
        output SI.Power LossPower "Power lost in the hysteresis";
        output SI.Resistance R "Ohmic resistance of the hysteresis";
        output Magnets.MagneticFluxPerMetre Phi "The y-axis of the hysteresis plot, per length";
        // PARAMETERS
        parameter Integer Count = 100 "Length of history array" annotation(
          Dialog(group = "Advanced"));
        parameter SI.Current tol = 1e-5 "Tolerance in Preisach history" annotation(
          Dialog(group = "Advanced"));
        parameter SI.Time t1 = 1e-6 "Initialization time" annotation(
          Dialog(group = "Advanced"));
        parameter Magnets.ResistancePerMetre R_n = 1e8 "Normal state resistance/length of the superconductor";
        parameter SI.Length len = 0.05 "Length of the sample";
        parameter Real numTapes = 1 "Descaled number of tapes";
        parameter Data.HTS_EverettParameter mat = Data.HTS_EverettParameter() annotation(
          choicesAllMatching = true,
          Dialog(group = "Hysteresis data location"));
        SI.Current i_local "Descaled current";
        //
      protected
        final parameter Real mu0 = mat.K * Modelica.Constants.mue_0;
        Magnets.MagneticFluxPerMetre J "Polarisation";
        SI.Current hmax(start = 0, min = 0) "maximum value of h";
        Real MagRel = 0 "Removing this breaks the code";
        SI.Current alpha "Current alpha coordinate of Everett-Function everett(alpha,beta)";
        SI.Current beta "Current beta coordinate of Everett-Function everett(alpha,beta)";
        Boolean asc(start = true, fixed = true) "=asc without chatter";
        Boolean asc2 "i is ascending der(i)>0";
        Boolean delAsc(start = false) "wipeout history vertex at ascending i";
        Boolean delDesc(start = false) "wipeout history vertex at descending i";
        Boolean del(start = false) "delAsc or delDesc";
        Boolean init(start = false, fixed = true) "If init=1 then J runs on the initial magnetization curve";
        Boolean evInit(start = false) "Event init=0 -> init=1";
        Boolean evAsc(start = false) "Event asc=0 -> asc=1";
        Boolean evDesc(start = false) "Event asc=1 -> asc=0";
        SI.Current aSav[Count] "1xCount array of alpha history (vertices on Preisach Plane)";
        SI.Current bSav[Count] "1xCount array of beta history (vertices on Preisach Plane)";
        Magnets.MagneticFluxPerMetre E "Everett function";
        SI.Current H1 "Term for computing the Everett function";
        SI.Current H2 "Term for computing the Everett function";
        SI.Current H3 "Term for computing the Everett function";
        SI.Current H4 "Term for computing the Everett function";
        constant Magnets.MagneticFluxPerMetre unitT = 1 "Utility flux unit";
        Real u(start = 0, fixed = true, final unit = "1");
        Boolean init2(start = false, fixed = true);
        Boolean init3;
        SI.Current x(start = 0) "Variable for initialization of the Preisach model";
        discrete Real aSavI(start = 0, fixed = true);
        discrete Real bSavI(start = 0, fixed = true);
        discrete Real bI(start = 0, fixed = true);
        discrete Real hmaxI(start = 0, fixed = true);
        //
      initial equation
        J = 0.5 * (Utility.everettSupercon(i, -mat.Hsat, mat, false) * (1 - MagRel) - Utility.everettSupercon(mat.Hsat, i_local, mat, false) * (1 + MagRel) + Utility.everettSupercon(mat.Hsat, -mat.Hsat, mat, false) * MagRel);
        //
        J = Utility.initPreisachSupercon(x, i_local, mat);
        aSav = fill(mat.Hsat, Count);
        bSav = fill(-mat.Hsat, Count);
        beta = alpha;
        hmax = mat.Hsat;
        //
      equation
        init2 = time >= 1.5 * t1;
        init3 = edge(init2);
        der(x) = 0;
        when init2 then
          hmaxI = abs(i_local) + abs(x);
          if hmax < tol then
            aSavI = mat.Hsat;
            bSavI = -mat.Hsat;
          elseif asc and x < 0 then
            aSavI = mat.Hsat;
            bSavI = -hmax;
          elseif asc and x > 0 then
            aSavI = hmax;
            bSavI = alpha;
          elseif not asc and x < 0 then
            aSavI = alpha;
            bSavI = -hmax;
          else
            aSavI = hmax;
            bSavI = -mat.Hsat;
          end if;
          bI = if asc then bSav[1] else aSav[1];
        end when;
        //
        alpha = if i_local <= (-mat.Hsat) then -mat.Hsat elseif i_local >= mat.Hsat then mat.Hsat else i_local;
        asc2 = der(i_local) > 0;
        der(u) = if asc2 and u < 1 then 0.5 / t1 elseif not asc2 and u > 0 then -0.5 / t1 else 0;
        asc = u > 0.5;
        evAsc = not pre(asc) and asc;
        evDesc = pre(asc) and not asc;
        der(beta) = if init then -der(alpha) else 0;
        delAsc = alpha > pre(aSav[1]);
        delDesc = alpha < pre(bSav[1]);
        del = delAsc or delDesc or evInit;
        init = abs(alpha) >= pre(hmax) and time >= 2 * t1;
        evInit = init and not pre(init);
        //
        when init3 or change(asc) and pre(init) then
          hmax = if init3 then hmaxI else abs(i_local);
        end when;
        //##### bSav #####
        when {init3, evAsc, del} then
          if init3 then
            bSav = cat(1, {bSavI}, fill(-mat.Hsat, Count - 1));
          elseif evAsc then
            bSav = if alpha - tol > pre(bSav[1]) then cat(1, {alpha}, pre(bSav[1:end - 1])) else pre(bSav);
          elseif del then
            bSav = cat(1, pre(bSav[2:end]), {-mat.Hsat});
          else
            bSav = pre(bSav);
          end if;
        end when;
        //##### REINIT aSav #####
        when {init3, evDesc, del} then
          if init3 then
            aSav = cat(1, {aSavI}, fill(mat.Hsat, Count - 1));
          elseif evDesc then
            aSav = if alpha + tol < pre(aSav[1]) then cat(1, {alpha}, pre(aSav[1:end - 1])) else pre(aSav);
          elseif del then
            aSav = cat(1, pre(aSav[2:end]), {mat.Hsat});
          else
            aSav = pre(aSav);
          end if;
        end when;
        // #### beta ####
        when {init3, change(asc), evInit, del} then
          reinit(beta, if init3 then bI elseif change(asc) then alpha
           elseif evInit then -alpha
           elseif asc then bSav[1] else aSav[1]);
        end when;
        H1 = (-beta) - mat.Hc;
        H2 = alpha - mat.Hc;
        H3 = (-alpha) - mat.Hc;
        H4 = beta - mat.Hc;
        //
        E = unitT * ((mat.M * mat.r * (2 / pi * atan(mat.q * H1) + 1) + 2 * mat.M * (1 - mat.r) / (1 + 1 / 2 * (exp(-mat.p1 * H1) + exp(-mat.p2 * H1)))) * (mat.M * mat.r * (2 / pi * atan(mat.q * H2) + 1) + 2 * mat.M * (1 - mat.r) / (1 + 1 / 2 * (exp(-mat.p1 * H2) + exp(-mat.p2 * H2)))) - (mat.M * mat.r * (2 / pi * atan(mat.q * H3) + 1) + 2 * mat.M * (1 - mat.r) / (1 + 1 / 2 * (exp(-mat.p1 * H3) + exp(-mat.p2 * H3)))) * (mat.M * mat.r * (2 / pi * atan(mat.q * H4) + 1) + 2 * mat.M * (1 - mat.r) / (1 + 1 / 2 * (exp(-mat.p1 * H4) + exp(-mat.p2 * H4)))));
        //
        der(J) = (if init then 0.5 else 1) * der(E);
        Phi = J;
        // + mu0 * i;
        v = der(len * Phi);
        // DEFINE OUTPUTS
        R = abs(v / (i_local + eps)) * (R_n * len) / (abs(v / (i_local + eps)) + R_n * len);
        LossPower = i_local ^ 2 * R;
        //
        i_local = i / numTapes;
        annotation(
          choicesAllMatching = true,
          Dialog(group = "Hysteresis"),
          Icon(graphics = {Rectangle(lineColor = {0, 0, 255}, extent = {{-70, 30}, {70, -30}}), Line(origin = {-85, 0}, points = {{15, 0}, {-15, 0}}, color = {0, 0, 255}), Line(origin = {85, 0}, points = {{15, 0}, {-15, 0}}, color = {0, 0, 255}), Text(lineColor = {0, 0, 255}, extent = {{-150, 90}, {150, 50}}, textString = "%name"), Line(origin = {2.27, 0}, points = {{-30, -20}, {-14, -20}, {-6, -16}, {2, 0}, {10, 16}, {18, 20}, {26, 20}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Line(origin = {-1.73, 0}, rotation = 180, points = {{-30, -20}, {-14, -20}, {-6, -16}, {2, 0}, {10, 16}, {18, 20}, {26, 20}}, color = {0, 0, 255}, smooth = Smooth.Bezier), Text(origin = {0, 4}, lineColor = {0, 0, 255}, extent = {{40, 0}, {40, -30}}, textString = "PE"), Text(origin = {-40, -32}, lineColor = {0, 0, 255}, extent = {{40, 0}, {40, -22}}, textString = "superconductor", fontName = "Calibri")}, coordinateSystem(initialScale = 0.1)),
          Diagram,
          experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-06, Interval = 0.002),
          __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian,newInst",
          __OpenModelica_simulationFlags(lv = "LOG_STATS", outputFormat = "mat", s = "dassl"));
      end PreisachEverett;
      annotation(
        Icon);
    end Hysteresis;

    package Data
      extends Modelica.Icons.MaterialPropertiesPackage;

      record HTS_EverettParameter
        extends Modelica.Icons.Record;
        import SI = Modelica.SIunits;
        parameter SI.Current Hsat = 35 "Hysteresis region between -Hsat .. Hsat";
        parameter Real M(final unit = "1") = 0.00077 "Related to saturation value of magnetization";
        parameter Real r(final unit = "1") = 0 "Proportion of the straight region in the vicinity of Hc";
        parameter Real q(final unit = "1/A") = 0.1 "Slope of the straight region in the vicinity of Hc";
        parameter Real p1(final unit = "1/A") = 0.22 "Sharpness of major loop near saturation";
        parameter Real p2(final unit = "1/A") = 0.3 "Sharpness of major loop near saturation";
        parameter SI.Current Hc = 11.3 "Major loop coercivity";
        parameter Real K(final unit = "1") = 1 "Slope in saturation region mue_0*K";
        parameter SI.Conductivity sigma = 1 "Electrical conductivity of material";
      end HTS_EverettParameter;
    end Data;

    model Utility
      extends Modelica.Icons.UtilitiesPackage;

      function initPreisachSupercon "Function used for the initialization of the Preisach hysteresis model GenericHystPreisachEverett"
        //
        /*
        BSD 3-Clause License

        Copyright (c) 1998-2020, Modelica Association and contributors
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
        FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
        DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
        OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        */
        //
        extends Modelica.Icons.Function;
        import SI = Modelica.SIunits;
        import mu_0 = Modelica.Constants.mue_0;
        input SI.Current x;
        input SI.Current i;
        input Data.HTS_EverettParameter p;
        // Create object containing the Everett parameters
        output Magnets.MagneticFluxPerMetre Phi;
      protected
        SI.Current imax;
        SI.Current i_l;
      algorithm
        i_l := if i <= (-p.Hsat) then -p.Hsat elseif i >= p.Hsat then p.Hsat else i;
        // if current smaller than negative saturation, then select negative saturation
        // if current larger than positive saturation, then select positive saturation
        // else select actual current value
        imax := abs(i) + abs(x);
        Phi := if x < 0 then (-0.5 * everettSupercon(imax, -imax, p, false)) + everettSupercon(i_l, -imax, p, false) + p.K * mu_0 * i else 0.5 * everettSupercon(imax, -imax, p, false) - everettSupercon(imax, i_l, p, false) + p.K * mu_0 * i;
        // if initial current value negative then initiate negative, otherwise initiate positive
      end initPreisachSupercon;

      function everettSupercon
        //
        /*
        BSD 3-Clause License

        Copyright (c) 1998-2020, Modelica Association and contributors
        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions are met:

        * Redistributions of source code must retain the above copyright notice, this
          list of conditions and the following disclaimer.

        * Redistributions in binary form must reproduce the above copyright notice,
          this list of conditions and the following disclaimer in the documentation
          and/or other materials provided with the distribution.

        * Neither the name of the copyright holder nor the names of its
          contributors may be used to endorse or promote products derived from
          this software without specific prior written permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
        AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
        IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
        DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
        FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
        DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
        SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
        CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
        OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        */
        //
        extends Modelica.Icons.Function;
        import Modelica.Constants.pi;
        import SI = Modelica.SIunits;
        input SI.Current a_;
        input SI.Current b_;
        input Data.HTS_EverettParameter p;
        input Boolean mirror "If true then J(a,b)=-J(b,a) else J(a,b)=0 for a<b";
        output Magnets.MagneticFluxPerMetre J "Magnetic polarisation";
      protected
        SI.Current a;
        SI.Current b;
        SI.Current h1;
        SI.Current h2;
        SI.Current h3;
        SI.Current h4;
        constant Magnets.MagneticFluxPerMetre unitT = 1;
      algorithm
        if a_ >= b_ or mirror then
          a := if a_ > p.Hsat then p.Hsat elseif a_ < (-p.Hsat) then -p.Hsat else a_;
          b := if b_ > p.Hsat then p.Hsat elseif b_ < (-p.Hsat) then -p.Hsat else b_;
          h1 := (-b) - p.Hc;
          h2 := a - p.Hc;
          h3 := (-a) - p.Hc;
          h4 := b - p.Hc;
          J := unitT * ((p.M * p.r * (2 / pi * atan(p.q * h1) + 1) + 2 * p.M * (1 - p.r) / (1 + 1 / 2 * (exp(-p.p1 * h1) + exp(-p.p2 * h1)))) * (p.M * p.r * (2 / pi * atan(p.q * h2) + 1) + 2 * p.M * (1 - p.r) / (1 + 1 / 2 * (exp(-p.p1 * h2) + exp(-p.p2 * h2)))) - (p.M * p.r * (2 / pi * atan(p.q * h3) + 1) + 2 * p.M * (1 - p.r) / (1 + 1 / 2 * (exp(-p.p1 * h3) + exp(-p.p2 * h3)))) * (p.M * p.r * (2 / pi * atan(p.q * h4) + 1) + 2 * p.M * (1 - p.r) / (1 + 1 / 2 * (exp(-p.p1 * h4) + exp(-p.p2 * h4)))));
        else
          J := 0;
        end if;
        // if a_ is larger than positive saturation then b is the positive saturation
        // if a_ is smaller than negative saturation then b is the negative saturation
        // otherwise take a_ as inputted
        //
        // if b_ is larger than positive saturation then b is the positive saturation
        // if b_ is smaller than negative saturation then b is the negative saturation
        // otherwise take b_ as inputted
        //
        //
      end everettSupercon;
    equation

    end Utility;
    annotation(
      uses(Modelica(version = "3.2.3")));
  end Superconductor;

  type ResistancePerMetre = Real(final quantity = "Resistance Per Metre", final unit = "Ohm/m");
  type MagneticFluxPerMetre = Real(final quantity = "Magnetic Flux Per Metre", final unit = "Wb/m");

  model Divertor_PF_Magnet "This model reflects the engineering of the magnets required for control of the plasma near the divertor region."
    extends Magnets.BaseMagnet;
  equation

  end Divertor_PF_Magnet;

  model VS_Magnet "This model reflects the engineering of the magnets required for Vertical Stability."
    extends Magnets.BaseMagnet;
  equation

  end VS_Magnet;

  model EFCC_Magnet "This model reflects the engineering of the magnets required for Error Field Correction."
    extends Magnets.BaseMagnet;
  equation

  end EFCC_Magnet;

  model ELM_Magnet "This model reflects the engineering of the magnets required for Edge Localized Mode."
    extends Magnets.BaseMagnet;
  equation

  end ELM_Magnet;

  model RWM_Magnet "This model reflects the engineering of the magnets required for Resistive Wall Mode."
    extends Magnets.BaseMagnet;
  equation

  end RWM_Magnet;

  model CS_Magnet "This model reflects the engineering required for a Central Solenoid."
    extends Magnets.BaseMagnet;
  equation

  end CS_Magnet;
  annotation(
    Diagram(coordinateSystem(initialScale = 0.1)),
    uses(Modelica(version = "3.2.3")));
//<jinja>{% endraw %}
end Magnets;