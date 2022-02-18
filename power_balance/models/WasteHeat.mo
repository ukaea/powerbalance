package WasteHeat "Package containing the waste heat Management system object (WasteHeatSystem) and model for the power load of waste heat management of Magnets, H&CD, Cryo and WaterDetrit (WasteHeatPower)

DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model WasteHeatSystem "Model of the power loads of the Waste Heat Management (formerly HVAC) system - takes in waste heat from other models and performs cooling with dehumidification calculation"
    //
    import SI = Modelica.SIunits;
    //
    // Declare Media Packages
    package Medium = Modelica.Media.Air.MoistAir "Used medium package";
    //
    // Inputs for connecting to other models
    Modelica.Blocks.Interfaces.RealInput WastePower(unit = "W") "Real Waste Power Input" annotation(
      Placement(visible = true, transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealOutput ConsumedPower(unit = "W") "Real Power Output" annotation(
      Placement(visible = true, transformation(origin = {110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    //
    // Parameters
    parameter SI.Pressure roomPressure = 1e5 "Pressure of Room";
    parameter SI.Temperature ambientTemperature = 298 "Ambient Temperature";
    parameter SI.CoefficientOfHeatTransfer U = 25 "W/(m^2*K), heat transfer coefficent";
    parameter SI.Length __Height = 3 "Height of room";
    parameter SI.Length __Length = 150 "Length of room";
    parameter SI.Length __Width = 30 "Width of room";
    parameter Real __SystemEfficiency = 0.8 "Efficiency of HVAC system";
    parameter Real __StopTime = 60 "Simulation stop time";
    //
    // Variables
    SI.Temperature roomTemperature "Temperature of Room";
    SI.Area surfaceArea "Exposed surface SI.Area of room";
    SI.SpecificEnergy enthalpyIn "Enthalpy into system";
    SI.SpecificEnergy enthalpyOut "Enthalpy out of system";
    SI.SpecificEnergy enthalpyWater "Enthalpy of water";
    SI.Pressure vapourPressure "Partial SI.Pressure of water vapour";
    SI.MassFlowRate airMassFlow "mass flow rate of air";
    SI.MassFlowRate waterMassFlow "mass flow rate of water";
    SI.Power Qout "Rate of heat transfer out";
    Real specificHumidity "Specific humidity kg h2O/kg dry air";
    //
  initial equation
    //Input Parameter Assertions
    assert(__Height >= 0,"---> Assertion Error in [WasteHeatSystem], input parameter [Height = "+String(__Height)+"] cannot be negative!",level = AssertionLevel.error);
    assert(__Height >= 2 and __Height <= 50,"---> Assertion Warning in [WasteHeatSystem], input parameter [Height = "+String(__Height)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(__Length >= 0,"---> Assertion Error in [WasteHeatSystem], input parameter [Length = "+String(__Length)+"] cannot be negative!",level = AssertionLevel.error);
    assert(__Length >= 2 and __Length <= 200,"---> Assertion Warning in [WasteHeatSystem], input parameter [Length = "+String(__Length)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(__Width >= 0,"---> Assertion Error in [WasteHeatSystem], input parameter [Width = "+String(__Width)+"] cannot be negative!",level = AssertionLevel.error);
    assert(__Width >= 2 and __Width <= 200,"---> Assertion Warning in [WasteHeatSystem], input parameter [Width = "+String(__Width)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(__SystemEfficiency > 0 and __SystemEfficiency <= 1,"---> Assertion Error in [WasteHeatSystem], input parameter [SystemEfficiency = "+String(__SystemEfficiency)+"] cannot be negative!",level = AssertionLevel.error);
    assert(__SystemEfficiency >= 0.5 and __SystemEfficiency <= 0.9,"---> Assertion Warning in [WasteHeatSystem], input parameter [SystemEfficiency = "+String(__SystemEfficiency)+"] outside of reasonable range!",level = AssertionLevel.warning);
    //
  equation
    // Find inlet temperature
    surfaceArea = 2 * __Height * __Length + 2 * __Height * __Width + __Width * __Length;
    roomTemperature = (U * surfaceArea * ambientTemperature + WastePower) / (U * surfaceArea);
    // Find enthalphy using Moist air Function - dry air and steam
    enthalpyIn = Medium.enthalpyOfNonCondensingGas(roomTemperature);
    enthalpyOut = Medium.enthalpyOfNonCondensingGas(ambientTemperature);
    enthalpyWater = 104.928e3;
    // From steam tables
    // Calculate mass flow rate of air (1.225 is density of air)
    airMassFlow = __Height * __Width * __Length * 1.225 / (60 * 12) "Full air change completed 5 times an hour";
    // Calculate mass flow rate of water
    // Relative humidity of 75% (Psat @ 25 C = 3.169e3 Pa)
    vapourPressure = 0.75 * 3.169e3;
    specificHumidity = 0.622 * vapourPressure / (roomPressure - vapourPressure);
    waterMassFlow = specificHumidity * airMassFlow;
    // Calculate heat transfer rate out
    Qout = if WastePower >= 5000 then airMassFlow * (enthalpyIn - enthalpyOut) - waterMassFlow * enthalpyWater else airMassFlow * (enthalpyIn - enthalpyOut);
    //
    ConsumedPower = Qout / __SystemEfficiency;
    //
    //Runtime Assertions
    assert(surfaceArea >= 0,"---> Assertion Error in [WasteHeatSystem], variable [surfaceArea = "+String(surfaceArea)+"] cannot be negative!",level = AssertionLevel.error);
    assert(surfaceArea <= 1e5,"---> Assertion Warning in [WasteHeatSystem], variable [surfaceArea = "+String(surfaceArea)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(roomTemperature >= 0,"---> Assertion Error in [WasteHeatSystem], variable [roomTemperature = "+String(roomTemperature)+"] outside of acceptable range!",level = AssertionLevel.error);
    assert(roomTemperature <= 35,"---> Assertion Warning in [WasteHeatSystem], variable [roomTemperature = "+String(roomTemperature)+"] outside of reasonable range!",level = AssertionLevel.warning); 
    assert(enthalpyIn >= 0,"---> Assertion Error in [WasteHeatSystem], variable [enthalpyIn = "+String(enthalpyIn)+"] cannot be negative!",level = AssertionLevel.error);
    assert(enthalpyIn <= 100,"---> Assertion Warning in [WasteHeatSystem], variable [enthalpyIn = "+String(enthalpyIn)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(enthalpyOut >= 0,"---> Assertion Error in [WasteHeatSystem], variable [enthalpyOut = "+String(enthalpyOut)+"] cannot be negative!",level = AssertionLevel.error);
    assert(enthalpyOut <= 100,"---> Assertion Warning in [WasteHeatSystem], variable [enthalpyOut = "+String(enthalpyOut)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(enthalpyWater >= 0,"---> Assertion Error in [WasteHeatSystem], variable [enthalpyWater = "+String(enthalpyWater)+"] cannot be negative!",level = AssertionLevel.error);
    assert(enthalpyWater <= 430,"---> Assertion Warning in [WasteHeatSystem], variable [enthalpyWater = "+String(enthalpyWater)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(airMassFlow >= 0,"---> Assertion Error in [WasteHeatSystem], variable [airMassFlow = "+String(airMassFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(airMassFlow <= 1e6,"---> Assertion Warning in [WasteHeatSystem], variable [airMassFlow = "+String(airMassFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(vapourPressure >= 0 and vapourPressure <= 1e5 ,"---> Assertion Error in [WasteHeatSystem], variable [vapourPressure = "+String(vapourPressure)+"] cannot be negative!",level = AssertionLevel.error);
    assert(vapourPressure <= 5e4,"---> Assertion Warning in [WasteHeatSystem], variable [vapourPressure = "+String(vapourPressure)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(specificHumidity >= 0,"---> Assertion Error in [WasteHeatSystem], variable [specificHumidity = "+String(specificHumidity)+"] cannot be negative!",level = AssertionLevel.error);
    assert(specificHumidity <= 0.03,"---> Assertion Warning in [specificHumidity], variable [specificHumidity = "+String(specificHumidity)+"] outside of reasonable range!",level = AssertionLevel.warning);
    assert(waterMassFlow >= 0,"---> Assertion Error in [WasteHeatSystem], variable [waterMassFlow = "+String(waterMassFlow)+"] cannot be negative!",level = AssertionLevel.error);
    assert(waterMassFlow <= 5,"---> Assertion Warning in [waterMassFlow], variable [waterMassFlow = "+String(waterMassFlow)+"] outside of reasonable range!",level = AssertionLevel.warning);
    //
    annotation(
      Diagram(coordinateSystem(initialScale = 0.1)),
      uses(Modelica(version = "3.2.3")));
  end WasteHeatSystem;

model WasteHeatPower "Model of all the rooms with a Waste Heat Management (formerly HVAC) system and the total power consumed by the system"
  //
  Real ElecPowerConsumed(unit = "W") "Total power consumption";
  // Room Blocks
  WasteHeat.WasteHeatSystem wasteHeatMagnets(__Height = 3, __Length = 150, __Width = 30) annotation(
    Placement(visible = true, transformation(origin = {40, 60}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  WasteHeat.WasteHeatSystem wasteHeatHCD(__Height = 70, __Length = 120, __Width = 100) annotation(
    Placement(visible = true, transformation(origin = {40, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  WasteHeat.WasteHeatSystem wasteHeatCryo(__Height = 3, __Length = 120, __Width = 45) annotation(
    Placement(visible = true, transformation(origin = {40, -60}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
  // Waste Power Value blocks (k is in Watts) - constant for now
  Modelica.Blocks.Interfaces.RealInput HCDheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
    Placement(visible = true, transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
  Modelica.Blocks.Interfaces.RealInput Magnetheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
    Placement(visible = true, transformation(origin = {-110, 60}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 60}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
  Modelica.Blocks.Interfaces.RealInput Cryoheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
    Placement(visible = true, transformation(origin = {-110, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
  //
  equation
  // Sum all the power used by rooms together
  ElecPowerConsumed = wasteHeatMagnets.ConsumedPower + wasteHeatHCD.ConsumedPower + wasteHeatCryo.ConsumedPower;
  // Connectors
  connect(Magnetheat, wasteHeatMagnets.WastePower) annotation(
    Line(points = {{-110, 60}, {18, 60}}, color = {0, 0, 127}));
  connect(HCDheat, wasteHeatHCD.WastePower) annotation(
    Line(points = {{-110, 0}, {18, 0}}, color = {0, 0, 127}));
  connect(Cryoheat, wasteHeatCryo.WastePower) annotation(
    Line(points = {{-110, -60}, {18, -60}}, color = {0, 0, 127}));
  //
  //Runtime Assertions
  assert(ElecPowerConsumed >= 0, "---> Assertion Error in [WasteHeatPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] cannot be negative!", level = AssertionLevel.error);
  assert(ElecPowerConsumed <= 1e8, "---> Assertion Warning in [WasteHeatPower], variable [ElecPowerConsumed = "+String(ElecPowerConsumed)+"] outside of reasonable range!", level = AssertionLevel.warning);
end WasteHeatPower;
  annotation(
    Diagram(coordinateSystem(initialScale = 0.1)),
    uses(Modelica(version = "3.2.3")));
end WasteHeat;
