package WasteHeatDB "Package to estimate the total waste heat and the Parasitic Load needed to cool the waste heat, using cooling water and HVAC"
  //
  //

  model HVACPower "Model to estimate the parasitic load of the HVAC chiller"
    //
    //imported parameters
    import SI = Modelica.SIunits;
    Real ThermalPower(unit = "GW");
    //
    //Parameters
    parameter Real s = 0.3 "General scaling figure for HVAC system based on chiller power consumption";
    parameter Real SF1 = 0.25 "Scaling factor one";
    parameter Real SF2 = 0.75 "Scaling factor two";
    //Parameters for HVAC Pumping Calc
    parameter Real dT(unit = "oC") = 8 "Temperature change";
    parameter Real CpWater(unit = "kJ/(kgK)") = 4.18 "Specific heat capacity of water";
    parameter Real DensityWater(unit = "kg/m3") = 1000;
    parameter Real Velocity(unit = "m/s") = 1.5;
    parameter Real Viscosity(unit = "Pa.s") = 0.00117 "viscosity of water";
    parameter Real FittingConstant = 70;
    parameter Real ElevationLosses(unit = "m") = 3;
    parameter Real PumpEfficiency = 0.8;
    //Pipe Sizing
    parameter Real Length(unit = "m") = 500;
    parameter Real Diameter(unit = "m") = 0.78;
    //
    //Waste Heat inputs for HVAC cooling, organised by contamination zones
    //CH
    parameter Real ElecPowerSupply(unit = "MW") = 8.55 "Electrical power supply/conertor for all magnets";
    parameter Real HX(unit = "MW") = 1.286 "Heat loss from heat exchangers";
    parameter Real PipeHeatLoss(unit = "MW") = 2 "Heat lost from pipes to env.";
    //CL
    parameter Real ElecCub(unit = "MW") = 5.73 "Electrical cublicles";
    parameter Real DistBoards(unit = "MW") = 2.547 "Distribution boards";
    parameter Real CompAirSupply(unit = "MW") = 0.05 "Compressed air supply";
    parameter Real RF(unit = "MW") = 3.8205 "RF heating and current drive";
    //
    //variables
    Real TotalHVACPower(unit = "MW") "HVAC chiller power consumption + Pumping Power. i.e. The parasitic load of the HVAC system";
    Real HVACWasteHeat(unit = "MW") "Total waste heat to be cooled by HVAC (before scaling)";
    Real HVACLoad(unit = "MW") "Total waste heat to be cooled by HVAC, scaled based on the total thermal power";
    Real Fraction;
    //Variables for pumping power
    Real MassFlowRate(unit = "kg/s");
    Real VolFlowRate(unit = "m3/s") "Volumetric flow rate";
    Real VolFlowRateHr(unit = "m3/hr") " Same as variable above but different units";
    Real ReynoldsNo;
    Real TFF "Tubulent Friction Factor";
    Real VelocityHead(unit = "m");
    Real FittingLosses(unit = "m");
    Real FrictionLosses(unit = "m");
    Real TotalHead(unit = "m");
    Real HVACPumpingPower(unit = "MW");
    //
  equation
//HVAC total waste heat before scaling
    HVACWasteHeat = ElecPowerSupply + HX + PipeHeatLoss + ElecCub + DistBoards + CompAirSupply + RF;
//Fraction to scale figures based of the GW basis
    Fraction = (SF1 * ThermalPower) + SF2;
//HVAC total waste heat after scaling
    HVACLoad = Fraction * HVACWasteHeat;
//HVAC Pumping power
//Mass flow rate needed (Q=mcpdT)
    MassFlowRate = HVACLoad / (dT * CpWater) * 1000 "to convert from t/s to kg/s";
//Volumetric Flow Rate
    VolFlowRate = MassFlowRate / DensityWater;
//Reynolds Number
    ReynoldsNo = DensityWater * Velocity * Diameter / Viscosity;
//Friction Factor
    TFF = 0.079 / ReynoldsNo ^ 0.25;
//Total Head
    VelocityHead = Velocity ^ 2 / (2 * 9.81);
    FittingLosses = FittingConstant * VelocityHead;
    FrictionLosses = TFF * (Length / Diameter) * (Velocity ^ 2 / (2 * 9.81));
    TotalHead = VelocityHead + FittingLosses + FrictionLosses + ElevationLosses;
//Pumping power
    VolFlowRateHr = VolFlowRate * 60 * 60;
    HVACPumpingPower = VolFlowRateHr * DensityWater * 9.81 * TotalHead / (3.6 * 10 ^ 6) / PumpEfficiency * 0.001;
//HVAC chiller power consumption calculation plus pumping power
    TotalHVACPower = HVACLoad * s + HVACPumpingPower;
  end HVACPower;

  //
  //

  model PumpingPower "Model to estimate the pumping parastic load for water cooled waste heat"
    //
    import SI = Modelica.SIunits;
    //
    //Inputs for connecting to other models
    //imported Parameters
    Real ThermalPower(unit = "GW");
    //
    //
    //Parameters
    parameter Real g(unit = "m2/s") = 9.81 "Gravitational constant";
    parameter Real Length(unit = "m") = 1000 "Length of the cooling water pipe (total rough estimate)";
    parameter Real Diameter(unit = "m") = 1.49 "diameter of cooling water pipe";
    parameter Real v(unit = "m/s") = 1.9 "Velocity of water in cooling pipe";
    parameter Real WaterDensity(unit = "kg/m3") = 1023 "density of water";
    parameter Real Viscosity(unit = "Pa.s") = 0.00117 "Viscosity of water";
    parameter Real FF = 0.003 "Friction Factor";
    parameter Real PumpEfficiency = 0.8;
    parameter Real InducedTowerScale = 0.0087;
    parameter Real FlowRateScale = 0.0159 "Scale used to change flowrate based on waste heat load; Comes from Q=mcdT";
    parameter Real SF1 = 0.25 "scaling factor one based on thermal power";
    parameter Real SF2 = 0.75 "scaling factor two based on thermal power";
    //
    //Inputs for water cooled waste heat
    //Parameters(Water cooled waste heat figures organised by contamination zones)
    //CX
    parameter Real VacVessel(unit = "MW") = 6.3675 "Vacuum vessel";
    parameter Real VSCMagnets(unit = "MW") = 0.1432 "Vertical stabalisation control magnets";
    parameter Real RWMMagnets(unit = "MW") = 0.5731 "Resistive Wall Mode control magnets";
    parameter Real ERCMagnets(unit = "MW") = 0.5731 "Error field correction magnets";
    parameter Real ELMMagnets(unit = "MW") = 0.02865 "ELM control magnets";
    Real Magnets(unit = "MW") = VSCMagnets + RWMMagnets + ERCMagnets + ELMMagnets;
    //CH
    parameter Real PrimPumping(unit = "MW") = 2.547 "Primary coolant pumping";
    //CM
    parameter Real AGDetrit(unit = "MW") = 0.5094 "Air/Gas detrit";
    parameter Real WDetrit(unit = "MW") = 0.5463 "Water detrit";
    parameter Real VacTurbo(unit = "MW") = 0.12735 "Vacuum, turbo";
    parameter Real VacRoughCG(unit = "MW") = 0.12735 "Vacuum roughing pumping system compressed gas";
    parameter Real VacMotor(unit = "MW") = 0.12735 "Vacuum pump roughing moter";
    parameter Real ASU(unit = "MW") = 0.2547 "Air separation unit for nitrogen utility";
    //CL
    Real CryoPlant(unit = "MW") = 80 "Cryoplant";
    parameter Real RPC(unit = "MW") = 6.3675 "Reactive Power Compensation";
    Real RF(unit = "MW") = 115 "RF water cooling system for components";
    parameter Real SCPump(unit = "MW") = 2.547 "Secondary coolant pumping";
    parameter Real Generator(unit = "MW") = 12.735 "Generator(hydrogen cooled)";
    parameter Real TurbineWasteHeat(unit = "MW") = 3;
    //
    //Variables
    Real TotalPumpingPower(unit = "MW");
    Real FlowRate(unit = "m3/s");
    Real WaterWasteHeat(unit = "MW") "total waste heat; sum of all the inputs";
    Real WaterCoolingLoad(unit = "MW") "total waste heat scaled based on thermal power";
    //"Reynolds number"
    Real VelocityHead(unit = "m");
    Real FittingLosses(unit = "m");
    Real FrictionalLosses(unit = "m");
    Real PumpingPower(unit = "kW");
    Real DynamicHead(unit = "m");
    Real Fraction "used to scale waste heat figures based on thermal power";
    Real InducedDraughtReqs(unit = "MW");
    //
    //
  equation
//Total waste heat to be water cooled before scaling
    WaterWasteHeat = VacVessel + Magnets + PrimPumping + AGDetrit + WDetrit + VacTurbo + VacRoughCG + VacMotor + ASU + CryoPlant + RPC + RF + SCPump + Generator + TurbineWasteHeat;
//Fraction used to scale figures based of the GW basis
    Fraction = (SF1 * ThermalPower) + SF2;
//Total water cooling load after scaling
    WaterCoolingLoad = Fraction * WaterWasteHeat;
//Find the flowrate
    FlowRate = FlowRateScale * WaterCoolingLoad * 1.025 / 0.00103 / WaterDensity "Unit conversion from tonnes of cooling water to m3/s. Flowrate changes with Waste Heat load";
//Find the total head
    VelocityHead = v ^ 2 / (2 * g);
    FittingLosses = VelocityHead * 100 "100 is the assumed fitting constant";
    FrictionalLosses = FF * (Length / Diameter) * (v ^ 2 / (2 * g));
    DynamicHead = FrictionalLosses + FittingLosses;
//Find Pumping Power (Based on frictional losses)
    PumpingPower = FlowRate * 60 * 60 * WaterDensity * g * DynamicHead / 3600000 "pumping power with unit chnage into kW";
//
//Find power reqs for cooling towers and elevation head
    InducedDraughtReqs = InducedTowerScale * WaterCoolingLoad;
//
//Total cooling water parasitc Load
    TotalPumpingPower = InducedDraughtReqs + PumpingPower / 1000 "Unit change from kW to MW";
//
  end PumpingPower;

  model TotalParasitcLoadWH
    //
    //Instantiating models
    HVACPower hVACPower(ThermalPower = ThermalPower);
    PumpingPower pumpingPower(ThermalPower = ThermalPower, RF = HCDheat / 1e6, Magnets = Magnetheat / 1e6, CryoPlant = Cryoheat / 1e6);
    //
    Modelica.Blocks.Interfaces.RealInput HCDheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
      Placement(visible = true, transformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 0}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealInput Magnetheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
      Placement(visible = true, transformation(origin = {-110, 60}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, 60}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    Modelica.Blocks.Interfaces.RealInput Cryoheat(unit = "W") "Heat dissipated by magnets at cryo temp" annotation(
      Placement(visible = true, transformation(origin = {-110, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180), iconTransformation(origin = {-110, -60}, extent = {{10, -10}, {-10, 10}}, rotation = 180)));
    //
    //Variables
    Real ElecPowerConsumed(unit = "W");
    Real ThermalPower(unit = "GW");
    //
  equation
    ElecPowerConsumed = (hVACPower.TotalHVACPower + pumpingPower.TotalPumpingPower) * 1e6;
  end TotalParasitcLoadWH;
end WasteHeatDB;
