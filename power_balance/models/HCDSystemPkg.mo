package HCDSystemPkg "DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, 
and may or may not make physical sense. It is up to the user to verify that all parameters are correct."
  model HCDSystem "Model of the power consumption of a Heading and Current Drive System, taking in the thermal power supplied to the plasma and calculating the electrical power required using wall plug efficiencies"
    //
    Modelica.Blocks.Interfaces.RealOutput P_amb(unit = "W") "Heat dissipated to air" annotation(
      Placement(visible = true, transformation(extent = {{100, 8}, {120, 28}}, rotation = 0), iconTransformation(extent = {{100, 8}, {120, 28}}, rotation = 0)));
    import SI = Modelica.SIunits;
    //
    // Parameters
    parameter String __RFPowerDataPath = "RF_Heat.mat" "Input profile of thermal power contained within plasma over time. Full data path required for running inside OMEdit";
    parameter String __NBIPowerDataPath = "NBI_Heat.mat" "input profile of thermal power contained within plasma over time. Must use full data path if running inside OMEdit";
    parameter Boolean __useEffValue = false "Set to true to use an efficiency value, set to false to use the existing models";
    parameter Real __effNINI = 0.9 "Efficiency of the NBI system (dimensionless)";
    parameter Real __effRF = 0.9 "Efficiency of the RF system (dimensionless)";
    //
    // Variables
    SI.Power RFElectricalPowerIn "Power consumed by RF systems";
    SI.Power NBIElectricalPowerIn "Power consumed by NBI systems";
    SI.Power ElecPowerConsumed "Total electrical power consumed by heating and current drive systems";
    NINI negativeIonNeutralInjector(dataPath = __NBIPowerDataPath);
    RF.GyrotronSystem gyrotronSystem(dataPath = __RFPowerDataPath);
    //
  initial equation
    // Input Parameter Asssertions
    assert(__effNINI >= 0 and __effNINI <= 1, "---> Assertion Error in [HCDSystem], input parameter [effNINI = " + String(__effNINI) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(__effRF >= 0 and __effRF <= 1, "---> Assertion Error in [HCDSystem], input parameter [effRF = " + String(__effRF) + "] outside of acceptable range", level = AssertionLevel.error);
    //
  equation
    P_amb = if __useEffValue then (ElecPowerConsumed - negativeIonNeutralInjector.NBIThermalPower - gyrotronSystem.RFThermalPower) else (ElecPowerConsumed - gyrotronSystem.RFThermalPower - negativeIonNeutralInjector.NBIThermalPower);
    NBIElectricalPowerIn = if __useEffValue then negativeIonNeutralInjector.NBIThermalPower / __effNINI else negativeIonNeutralInjector.powerIn;
    RFElectricalPowerIn = if __useEffValue then gyrotronSystem.RFThermalPower / __effRF else gyrotronSystem.powerIn;
    ElecPowerConsumed = RFElectricalPowerIn + NBIElectricalPowerIn "Calculates the total electrical power required for H&CD";
    //
    // Runtime Asssertions
    assert(ElecPowerConsumed >= 0, "---> Assertion Error in [HCDSystem], variable [ElecPowerConsumed = " + String(ElecPowerConsumed) + "] cannot be negative!", level = AssertionLevel.error);
    assert(ElecPowerConsumed <= 3e8, "---> Assertion Warning in [HCDSystem], variable [ElecPowerConsumed = " + String(ElecPowerConsumed) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(RFElectricalPowerIn >= 0, "---> Assertion Error in [HCDSystem], variable [RFElectricalPowerIn = " + String(RFElectricalPowerIn) + "] cannot be negative!", level = AssertionLevel.error);
    assert(RFElectricalPowerIn <= 3e8, "---> Assertion Warning in [HCDSystem], variable [RFElectricalPowerIn = " + String(RFElectricalPowerIn) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(NBIElectricalPowerIn >= 0, "---> Assertion Error in [HCDSystem], variable [NBIElectricalPowerIn = " + String(NBIElectricalPowerIn) + "] cannot be negative!", level = AssertionLevel.error);
    assert(NBIElectricalPowerIn <= 3e8, "---> Assertion Warning in [HCDSystem], variable [NBIElectricalPowerIn = " + String(NBIElectricalPowerIn) + "] outside of reasonable range!", level = AssertionLevel.warning);
    assert(P_amb >= 0, "---> Assertion Error in [HCDSystem], variable [P_amb = " + String(P_amb) + "] cannot be negative!", level = AssertionLevel.error);
    assert(P_amb <= 5e7, "---> Assertion Warning in [HCDSystem], variable [P_amb = " + String(P_amb) + "] outside of reasonable range!", level = AssertionLevel.warning);
    annotation(
      Diagram(coordinateSystem(initialScale = 0.1)),
      Icon(coordinateSystem(extent = {{-200, -200}, {200, 200}})),
      uses(Modelica(version = "3.2.3")));
  end HCDSystem;

  model NINI "This model is based on the in-house UKAEA work of D B King and E Surrey, referred to in the following publication:
    
    Negative ion research at the Culham Centre for Fusion Energy (CCFE), R McAdams, A J T Holmes, D B King, E Surrey, I Turner and J Zacks, 
    New Journal of Physics, Volume 18, December 2016, doi: https://doi.org/10.1088/1367-2630/aa4fa1
    (R McAdams et al 2016 New J. Phys. 18 125013)
    
    "
    import SI = Modelica.SIunits;
    //
    parameter String dataPath "Input profile of thermal power contained within plasma over time. Must use full data path if running inside OMEdit";
    parameter Real __beamEnergy(unit = "MV") = 1 "NBI accelerator grid voltage (MV)";
    parameter Real __efficiencyNeutralization = 0.58 "neutralisation efficiency of NINI";
    parameter Real __NBIThermalPowerMaxMW(unit = "MW") = 104.24 "maximum NBI thermal power over the duration of a pulse";
    //
    // Parameters from ENBI.pro code
    parameter Real coreDivergence(unit = "mrad") = 5 "Core divergence, units mrad";
    parameter Real haloDivergence(unit = "mrad") = 15 "Halo divergence, units mrad";
    parameter SI.Length beamlineLength = 23 "Beamline length, units m";
    parameter SI.Area gridArea = 0.75 "Grid area, units m^2";
    parameter SI.Area exitArea = 0.197 "Exit area, units m^2";
    parameter Real electronRatio = 1 "Electron per D- ion ratio";
    parameter SI.CurrentDensity maxJ = 300 "Maximum current density, units Am^-2";
    // parameter Real numInj_PerLine=1 "Number of injectors per beamline";
    // parameter Real numBeamlines=5;
    parameter Real extractionVolt(unit = "kV") = 10 "Extraction volts, units kV";
    parameter SI.Voltage suppressionVolt = 15 "Suppression volts, units V";
    parameter SI.Voltage filterVolt = 5 "Filter field, units V";
    parameter SI.Current filterCurrent = 6000 "Filter current, units A, '6kA from DDD, less if permanent magnets used'- E. Surrey";
    parameter Real stripFraction_Laser_Scaled = 0.24 "Strip fraction with laser, 'scaled from 29% in ITER using sig-1,0 and 0.8 gas for photneut'- E. Surrey; DUPLICATE?";
    parameter SI.Voltage stripVolt = 100 "Units kV";
    parameter Real stripCollected(unit = "1") = 0.5 "strip percent collected";
    parameter SI.Power powerRF = 800000 "RF power output per beamline";
    parameter Real efficiencyDC = 0.9 "DC efficiency; CHECK THIS - DOUBLE ACCOUNTING??";
    parameter Real efficiencyRF = 0.9 "RF efficiency";
    parameter Boolean laser = true "Is a laser neutralizer used?; STRUCTURAL_PARAMETER";
    parameter Real efficiencyLaser = 0.25 "Laser efficiency";
    parameter SI.Length widthNeutrChannel = 0.105 "Neutralizer channel width, units m";
    parameter Real numChannels = 4;
    parameter Real efficiencyNeutr_Laser = 0.58 "Neutralizer efficiency with laser";
    parameter Real efficiencyNeutr = 0.58 "Neutralizer efficiency without laser";
    parameter Real negVolt(unit = "kV") = 25 "Units kV";
    parameter Real negFraction = 0.9;
    parameter Real posVolt = 0.95 "units MV";
    parameter Real posFraction = 0;
    parameter Real pos_RI_fracL = 0;
    // parameter Real neg_RI_frac=0;
    // parameter Real pos_RI_frac=0;
    parameter Real efficiencyPosConverter = 0;
    parameter SI.Power laserIncidentals = 4400000 "incidentals with laser; unit?";
    parameter Real stripFraction_Laser = 0.29 "strip fraction with laser; DUPLICATE?";
    // parameter Real plasma_n_p = 0 "???";
    // NOT USED!!
    
    // parameter Real p_to_p		109.767
    //
    // Data Import - Required funtion to import .mat file containing NBI thermal power profile
    import Modelica.Blocks.Sources.CombiTimeTable;
    Modelica.Blocks.Sources.CombiTimeTable combiTimeTable1D(fileName = dataPath, tableOnFile = true, tableName = "data");
    // Variables
    SI.Power NBIThermalPower = combiTimeTable1D.y[1] "Total plasma thermal power supplied by external heating varying with time";
    SI.Power powerIn "Electrical power consumed by NBI systems";
    SI.Current maxDeuteriumCurrent_TotalPulse "maximum total deuterium current over the duration of a pulse";
    Real stripFraction "strip fraction";
    Real di_loss_NH "???";
    Real di_loss_H "???";
    Real di_loss "???";
    //
    Real lossReionisation_Laser(unit = "percent") "Reionisation losses with laser (percent)";
    Real lossReionisation_NoLaser(unit = "percent") "Reionisation losses without laser (percent)";
    Real lossReionisation(unit = "percent") "Reionisation losses (percent)";
    Real lossTransmission(unit = "percent") "Total transmission losses (percent)";
    SI.Current DeuteriumCurrent_PerLine "Deuterium current per beamline";
    SI.Current electronCurrent_PerLine "Electron current per beamline";
    Integer numBeamlines "Number of beamlines";
    SI.Current DeuteriumCurrent_PerLine_total "Total deuterium current";
    SI.CurrentDensity J "Current density";
    SI.Current currentHVPSU "HVPSU current";
    SI.Power powerHVPSU "HVPSU power";
    SI.Current suppressionCurrent "Suppression current (A)";
    Real extractionPower(unit = "MW") "Extraction power (MW)";
    Real suppressionPower_PerLine(unit = "MW") "Supression power per beamline (MW)";
    Real filterPower_PerLine(unit = "MW") "Filter power per beamline (MW)";
    Real stripPower_PerLine(unit = "MW") "Stripping grid power per beamline (MW)";
    Real tot_HVP(unit = "MW") "HV deck power drain per beamline (MW)";
    SI.Power RFInputPower_PerLine "RF power input per beamline";
    SI.Power tot_inj_P "???";
    SI.Power neg_rec_p "???";
    SI.Power pos_rec_p "???";
    SI.Power laser_P "???";
    Real neg_RI_frac "???";
    Real pos_RI_frac "???";
    Real efficiency "Wall plug efficiency";
    Real efficiencyNeutralization "Neutralization efficiency";
    SI.Power powerIncidentals "Incidentals (W)";
    SI.Power powerIn_PerInj "Electrical power consumed per injector";
    SI.Power powerOut_PerInj "Electrical power delivered to plasma per beamline";
    Integer numInj_PerLine "Number of injectors per beamline";
    Integer numInjectors "Number of injectors";
    // extract maximum power as a parameter!! need this to set numBeamlines
    //
  initial equation 
    // Input parameter assertions
    assert(__beamEnergy > 0, "---> Assertion Error in [HCDSystem], input parameter [beamEnergy = " + String(__beamEnergy) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(__beamEnergy <= 1e5, "---> Assertion Warning in [HCDSystem], input parameter [beamEnergy = " + String(__beamEnergy) + "] outside of reasonable range", level = AssertionLevel.warning);
    assert(__efficiencyNeutralization >= 0 and __efficiencyNeutralization <= 1, "---> Assertion Error in [HCDSystem], input parameter [efficiencyNeutralization = " + String(__efficiencyNeutralization) + "] outside of acceptable range", level = AssertionLevel.error);
    assert(__efficiencyNeutralization >= 0.4 and __efficiencyNeutralization <= 0.75, "---> Assertion Warning in [HCDSystem], input parameter [efficiencyNeutralization = " + String(__efficiencyNeutralization) + "] outside of reasonable range", level = AssertionLevel.warning);
    assert(__NBIThermalPowerMaxMW > 0, "---> Assertion Error in [HCDSystem], input parameter [NBIThermalPowerMaxMW = " + String(__NBIThermalPowerMaxMW) + "] cannot be negative!", level = AssertionLevel.warning);
    assert(__NBIThermalPowerMaxMW >= 10 and __NBIThermalPowerMaxMW <= 500, "---> Assertion Warning in [HCDSystem], input parameter [NBIThermalPowerMaxMW = " + String(__NBIThermalPowerMaxMW) + "] outside of reasonable range", level = AssertionLevel.warning);
    //
  equation
    // neg_RI_frac = 0;
    // pos_RI_frac = 0;
    stripFraction = if not laser then stripFraction_Laser * exitArea / 0.197 else stripFraction_Laser_Scaled * exitArea / 0.197;
    //
    neg_RI_frac = if not laser then 0.21 else 1 - efficiencyNeutr_Laser;
    pos_RI_frac = if not laser then 0.21 else pos_RI_fracL;
    //
    efficiencyNeutralization = if not laser then __efficiencyNeutralization else efficiencyNeutr_Laser;
    //
    powerIncidentals = if not laser then 6000000 else laserIncidentals;
    //
    di_loss_NH = 0.0122 * coreDivergence ^ 2.0 - 0.0708 * coreDivergence + 0.1029;
    di_loss_H = 0.0102 * coreDivergence ^ 2.0 - 0.0496 * coreDivergence + 0.0711;
    di_loss = if integer(ceil(haloDivergence)) == 0 then di_loss_NH else di_loss_H;
    // ceil function used to only give equality when the real number is 0
    lossReionisation_Laser = 0.01 * (exitArea / 0.2) * (beamlineLength / 23.0) * (2.0 / 3.0) * numInj_PerLine;
    lossReionisation_NoLaser = 0.05 * (exitArea / 0.2) * (beamlineLength / 23.0) * (2.0 / 3.0) * numInj_PerLine;
    lossReionisation = if not laser then lossReionisation_NoLaser else lossReionisation_Laser;
    lossTransmission = lossReionisation + di_loss;
    maxDeuteriumCurrent_TotalPulse = __NBIThermalPowerMaxMW * 1000000 / (1000000 * __beamEnergy * (1 - stripFraction) * efficiencyNeutralization);  
    // Calculating maximum total current. Note that this is a liberal estimate as transmission losses (lossTransmission) have been removed so an analytical solution can be reached. Otherwise iterations must be done (this results in an innacurate value for lossTransmission).
    numInjectors = ceil(maxDeuteriumCurrent_TotalPulse / (exitArea * maxJ));
    numInjectors = numBeamlines * numInj_PerLine;
    numBeamlines = integer(ceil(numInjectors / 10));
    DeuteriumCurrent_PerLine_total = NBIThermalPower / (1000000 * __beamEnergy * (1 - stripFraction) * (1 - lossTransmission) * efficiencyNeutralization);
    // continuously varying value
    DeuteriumCurrent_PerLine = DeuteriumCurrent_PerLine_total / (numBeamlines * numInj_PerLine);
    J = DeuteriumCurrent_PerLine / exitArea;
    electronCurrent_PerLine = DeuteriumCurrent_PerLine * electronRatio;
    currentHVPSU = DeuteriumCurrent_PerLine * (1 - stripCollected * stripFraction - negFraction * neg_RI_frac * (1 - stripFraction));
    powerHVPSU = currentHVPSU * 1000000 * __beamEnergy;
    suppressionCurrent = J * (gridArea - exitArea);
    //
    extractionPower = extractionVolt * 1000 * electronCurrent_PerLine / efficiencyDC;
    suppressionPower_PerLine = suppressionCurrent * suppressionVolt / efficiencyDC;
    filterPower_PerLine = filterVolt * filterCurrent / efficiencyDC;
    stripPower_PerLine = stripFraction * stripCollected * stripVolt * 1000 * DeuteriumCurrent_PerLine;
    tot_HVP = (powerHVPSU + extractionPower + suppressionPower_PerLine + filterPower_PerLine + stripPower_PerLine) / efficiencyDC;
    //
    RFInputPower_PerLine = powerRF / efficiencyRF;
    tot_inj_P = tot_HVP + RFInputPower_PerLine;
    neg_rec_p = neg_RI_frac * DeuteriumCurrent_PerLine * (1 - stripFraction) * negFraction * negVolt * 1000 / efficiencyDC;
    pos_rec_p = pos_RI_frac * DeuteriumCurrent_PerLine * (1 - stripFraction) * posFraction * posVolt * 1000000 * efficiencyPosConverter;
    //
    laser_P = if not laser then 0 else -55.39 * 9788 * (1000000 * __beamEnergy) ^ 0.5 * log(1 - efficiencyNeutralization) * widthNeutrChannel * numChannels / (500.0 * efficiencyLaser);
    //
    powerIn_PerInj = tot_inj_P + laser_P + neg_rec_p + powerIncidentals - pos_rec_p;
    powerOut_PerInj = NBIThermalPower / numInjectors;
    powerIn = numInjectors * (tot_inj_P + laser_P + neg_rec_p + powerIncidentals - pos_rec_p);
    efficiency = NBIThermalPower / powerIn;
  end NINI;

  package RF "This model is based on the Masters Thesis of Samuel Stewart:
  
  Modelling of Radio Frequency Heating and Current Drive Systems for Nuclear Fusion, Samuel Stewart, 
  Integrated Engineering BEng Thesis, University of Cardiff, April 2021
  
  "
    model GyrotronSystem "Model of Heating and Current Drive using a gyrotron"
      import SI = Modelica.SIunits;
      RF.PSU_ACDC psu_ACDC annotation(
        Placement(visible = true, transformation(origin = {-65, 7}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      RF.Gyrotron gyrotron(Cryo_temp(displayUnit = "K"), Room_temp(displayUnit = "K"), Temp(displayUnit = "K")) annotation(
        Placement(visible = true, transformation(origin = {-4.44089e-16, 8}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      RF.WaveGuide waveGuide(dataPath = dataPath) annotation(
        Placement(visible = true, transformation(origin = {62, 8}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      //
      parameter String dataPath;
      SI.Power powerIn = psu_ACDC.pfcon1.p;
      SI.Power RFThermalPower = waveGuide.P_plasma;
      //
    equation
      connect(psu_ACDC.pfcon2, gyrotron.pfcon1) annotation(
        Line(points = {{-48, 8}, {-18, 8}, {-18, 8}, {-18, 8}}));
      connect(gyrotron.pfcon2, waveGuide.pfcon1) annotation(
        Line(points = {{18, 8}, {46, 8}, {46, 8}, {44, 8}}));
      //
    protected
      annotation(
        Icon);
    end GyrotronSystem;

    model PSU_ACDC
      import SI = Modelica.SIunits;
      RF.pfcon pfcon1 annotation(
        Placement(visible = true, transformation(origin = {-92, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      RF.pfcon pfcon2 annotation(
        Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      //
      parameter Real eff_psu(unit = "1") = 0.95494 "Efficiency of the AC-DC power converters for the gyrotron system";
      //
    equation
      pfcon1.p = pfcon2.p / eff_psu;
      //
      // Runtime Asssertions
      assert(pfcon1.p >= 0, "---> Assertion Error in [PSU_ACDC], variable [pfcon1.p = " + String(pfcon1.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon1.p <= 1e9, "---> Assertion Warning in [PSU_ACDC], variable [pfcon1.p = " + String(pfcon1.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(pfcon2.p >= 0, "---> Assertion Error in [PSU_ACDC], variable [pfcon2.p = " + String(pfcon2.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon2.p <= 1e9, "---> Assertion Warning in [PSU_ACDC], variable [pfcon2.p = " + String(pfcon2.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      //
      annotation(
        Icon(graphics = {Rectangle(origin = {0, -2}, lineThickness = 0.5, extent = {{-100, 52}, {100, -46}}), Text(origin = {0, -1}, extent = {{-30, 15}, {30, -15}}, textString = "PSU")}));
    end PSU_ACDC;

    model Gyrotron "Model to estimate the Efficieny of Gyrotron. Based on the default values for voltage (V_k), radius(r_k), cathode-anode spacing(d_ak), cathode pitch angle (theta_k) and annular thickness (t) obtained from the design of 170GHz 1.5MW gyrotron by Kalaria Kartikeyan"
      import SI = Modelica.SIunits;
      import MATH = Modelica.Math;
      RF.pfcon pfcon1 annotation(
        Placement(visible = true, transformation(origin = {-94, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      RF.pfcon pfcon2 annotation(
        Placement(visible = true, transformation(origin = {84, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      //
      // a. Magnetron Injection Gun [MIG]
      //
      Real e_charge(unit = "C") = 1.6021766e-19 "Charge of electron (C)";
      Real k(unit = "J/K") = 1.38064852e-23 "Boltzmann constant (J/K)";
      parameter Real theta_k(unit = "deg") = 32.05 "Cathode pitch angle (deg)";
      parameter Real A_0(unit = "A/(m2.K2)") = 0.6e6 "Richardson constant for Tungsten cathode material (A/(m^2*K^2)";
      parameter Real W_func(unit = "eV") = 4.5 "Work function for Tungsten cathode (eV)";
      Real pi = 2 * MATH.asin(1.0) "pi = 3.14159265358979";
      SI.PermittivityOfVacuum eps_0 = 8.8541878e-12 "Permitivity of free space (F/m)";
      parameter SI.Voltage V_k = 80e3 "Cathode voltage (V)";
      parameter SI.Radius r_k = 0.06786 "Cathode radius (m)";
      parameter SI.Length d_ak = 0.011159 "Cathode-anode spacing (m)";
      parameter SI.Length t = 0.00218 "Annular thickness (m)";
      parameter SI.Temp_K Temp = 2470 "Min temperature for emission (K)";
      //
      SI.Length r "Distance from conical tip to emitting surface (m)";
      SI.ElectricFieldStrength E_k "Electric field strength at cathode surface (V/m)";
      SI.Area A "Area of annular emitting surface (m^2)";
      SI.Current I_MIG "Beam current (A)";
      // I_MIG = Current density * Area
      SI.Power P_MIG "Beam Power (W)";
      //
      // b. Beam Model
      // The main magnetic coil accelerates the electron beam thereby increasing rotational energy.
      //
      parameter Real detune = 0.6 "Detuning factor to represent inefficiencies of interaction cavity";
      SI.MassOfElectron m_e = 9.1093837e-31 "Rest mass of electron (kg)";
      parameter SI.MagneticFluxDensity B_k = 0.25 "Axial magnetic flux density at cathode (T)";
      parameter SI.MagneticFluxDensity B_0 = 7 "Flux density at cavity (T)";
      //
      // Adiabatic interaction
      SI.Velocity c = 3e8 "Velocity of light in vacuum (m/s)";
      //
      // Variables
      Real m_corr "Correction factor";
      SI.Velocity V_t0 "Perpendicular velocity at interaction cavity (m/s)";
      SI.Energy E_t0 "Tangential energy per electron (J)";
      SI.Power P_RF "RF power output (W)";
      //
      // c. Coil Model
      // Model for the acceleration coil and MIG coil which are high field superconducting magnet coils
      //
      parameter Real N_turn_Acc = 27000 "Number of turns in RF accelerating coil";
      parameter Real N_turn_MIG = 1400 "Number of turns in MIG coil";
      SI.PermeabilityOfVacuum mu_0 = 1.25663706e-6 "Permeability of free space (H/m)";
      parameter SI.Resistance R_joint = 2.5e-9 "Joint resistance (Ohm)";
      parameter SI.Length l_coil_Acc = 0.434 "Accelerating coil length (m)";
      parameter SI.Length l_coil_MIG = 0.025 "MIG coil length (m)";
      parameter SI.Temp_K Cryo_temp = 4.5 "Cryogenics temperature (K)";
      parameter SI.Temp_K Room_temp = 300 "Room temperature (K)";
      parameter Real Cryo_FOM = 0.4 "Figure of merit for thermal power estimation";
      //
      SI.Current I_Coil_Acc "Accelerating coil current (A)";
      SI.Current I_Coil_MIG "MIG coil current (A)";
      SI.Power P_Coil_Acc "Accelerating coil power (W)";
      SI.Power P_Coil_MIG "MIG coil power (W)";
      SI.Power P_elec "MIG & accelerating coil power (W)";
      SI.Power P_Coils "Electrical power factoring power dissipated in cryo (W)";
      //
      Real Eff_RFGen(unit = "1") "RF gyrotron efficiency (fraction)";
      //
    equation
      //
      // a. Magnetron Injection Gun [MIG] model
      r = r_k / cos(theta_k * pi / 180);
      E_k = V_k / (r * log((r + d_ak) / r));
      A = pi * ((r + t) ^ 2 - r ^ 2);
      I_MIG = A * A_0 * Temp ^ 2 * exp((-e_charge / (k * Temp)) * (W_func - sqrt(e_charge * E_k / (4 * pi * eps_0))));
      P_MIG = I_MIG * V_k;
      //
      // a. Runtime Asssertions
      assert(r >= 0, "---> Assertion Error in [Gyrotron], variable [r = " + String(r) + "] cannot be negative!", level = AssertionLevel.error);
      assert(r <= 1, "---> Assertion Warning in [Gyrotron], variable [r = " + String(r) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(E_k >= 0, "---> Assertion Error in [Gyrotron], variable [E_k = " + String(E_k) + "] cannot be negative!", level = AssertionLevel.error);
      assert(E_k <= 10e6, "---> Assertion Warning in [Gyrotron], variable [E_k = " + String(E_k) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(A >= 0, "---> Assertion Error in [Gyrotron], variable [A = " + String(A) + "] cannot be negative!", level = AssertionLevel.error);
      assert(A <= 1, "---> Assertion Warning in [Gyrotron], variable [A = " + String(A) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(I_MIG >= 0, "---> Assertion Error in [Gyrotron], variable [I_MIG = " + String(I_MIG) + "] cannot be negative!", level = AssertionLevel.error);
      assert(I_MIG <= 10, "---> Assertion Warning in [Gyrotron], variable [I_MIG = " + String(I_MIG) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_MIG >= 0, "---> Assertion Error in [Gyrotron], variable [P_MIG = " + String(P_MIG) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_MIG <= 1e6, "---> Assertion Warning in [Gyrotron], variable [P_MIG = " + String(P_MIG) + "] outside of reasonable range!", level = AssertionLevel.warning);
      ////
      // b. Beam model
      V_t0 = E_k * cos(theta_k * pi / 180) / B_k * sqrt(B_0 / B_k);
      m_corr = 1 / sqrt(1 - (V_t0 / c) ^ 2);
      E_t0 = 0.5 * m_e * m_corr * V_t0 ^ 2;
      P_RF = detune * E_t0 * I_MIG / e_charge;
      //
      // b. Runtime Asssertions
      assert(m_corr >= 1, "---> Assertion Error in [Gyrotron], variable [m_corr = " + String(m_corr) + "] outside of acceptable range!", level = AssertionLevel.error);
      assert(m_corr <= 2, "---> Assertion Warning in [Gyrotron], variable [m_corr = " + String(m_corr) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(V_t0 >= 0, "---> Assertion Error in [Gyrotron], variable [V_t0 = " + String(V_t0) + "] cannot be negative!", level = AssertionLevel.error);
      assert(V_t0 <= 10e8, "---> Assertion Warning in [Gyrotron], variable [V_t0 = " + String(V_t0) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(E_t0 >= 0, "---> Assertion Error in [Gyrotron], variable [E_t0 = " + String(E_t0) + "] cannot be negative!", level = AssertionLevel.error);
      assert(E_t0 <= 1e-14, "---> Assertion Warning in [Gyrotron], variable [E_t0 = " + String(E_t0) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_RF >= 0, "---> Assertion Error in [Gyrotron], variable [P_RF = " + String(P_RF) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_RF <= 1e6, "---> Assertion Warning in [Gyrotron], variable [P_RF = " + String(P_RF) + "] outside of reasonable range!", level = AssertionLevel.warning);
      //
      // c. RF coil model
      I_Coil_Acc = l_coil_Acc * B_0 / (mu_0 * N_turn_Acc);
      P_Coil_Acc = 2 * R_joint * I_Coil_Acc ^ 2;
      I_Coil_MIG = l_coil_MIG * B_k / (mu_0 * N_turn_MIG);
      P_Coil_MIG = 2 * R_joint * I_Coil_MIG ^ 2;
      P_elec = P_Coil_Acc + P_Coil_MIG;
      P_Coils = P_elec + P_elec * (1 / Cryo_FOM) * (Room_temp - Cryo_temp) / Cryo_temp;
      ////
      // c. Runtime Asssertions
      assert(I_Coil_Acc >= 0, "---> Assertion Error in [Gyrotron], variable [I_Coil_Acc = " + String(I_Coil_Acc) + "] cannot be negative!", level = AssertionLevel.error);
      assert(I_Coil_Acc <= 100, "---> Assertion Warning in [Gyrotron], variable [I_Coil_Acc = " + String(I_Coil_Acc) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(l_coil_MIG >= 0, "---> Assertion Error in [Gyrotron], variable [l_coil_MIG = " + String(l_coil_MIG) + "] cannot be negative!", level = AssertionLevel.error);
      assert(l_coil_MIG <= 10, "---> Assertion Warning in [Gyrotron], variable [l_coil_MIG = " + String(l_coil_MIG) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_Coil_Acc >= 0, "---> Assertion Error in [Gyrotron], variable [P_Coil_Acc = " + String(P_Coil_Acc) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_Coil_Acc <= 1e-2, "---> Assertion Warning in [Gyrotron], variable [P_Coil_Acc = " + String(P_Coil_Acc) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_Coil_MIG >= 0, "---> Assertion Error in [Gyrotron], variable [P_Coil_MIG = " + String(P_Coil_MIG) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_Coil_MIG <= 1e-5, "---> Assertion Warning in [Gyrotron], variable [P_Coil_MIG = " + String(P_Coil_MIG) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_elec >= 0, "---> Assertion Error in [Gyrotron], variable [P_elec = " + String(P_elec) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_elec <= 1e-2, "---> Assertion Warning in [Gyrotron], variable [P_elec = " + String(P_elec) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(P_Coils >= 0, "---> Assertion Error in [Gyrotron], variable [P_Coils = " + String(P_Coils) + "] cannot be negative!", level = AssertionLevel.error);
      assert(P_Coils <= 1, "---> Assertion Warning in [Gyrotron], variable [P_Coils = " + String(P_Coils) + "] outside of reasonable range!", level = AssertionLevel.warning);   
      //
      // d. Efficiency of gyrotron
      Eff_RFGen = P_RF / (P_MIG + P_Coils);
      //
      // d. Runtime Asssertions
      assert(Eff_RFGen >= 0 and Eff_RFGen <= 1, "---> Assertion Error in [Gyrotron], variable [Eff_RFGen = " + String(Eff_RFGen) + "] outside of acceptable range!", level = AssertionLevel.error);
      //
      // e. Power input based on calculated efficiency
      pfcon1.p = pfcon2.p / Eff_RFGen;  
      //
      // e. Runtime Assertions
      assert(pfcon1.p >= 0, "---> Assertion Error in [Gyrotron], variable [pfcon1.p = " + String(pfcon1.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon1.p <= 1e9, "---> Assertion Warning in [Gyrotron], variable [pfcon1.p = " + String(pfcon1.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(pfcon2.p >= 0, "---> Assertion Error in [Gyrotron], variable [pfcon2.p = " + String(pfcon2.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon2.p <= 1e9, "---> Assertion Warning in [Gyrotron], variable [pfcon2.p = " + String(pfcon2.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      annotation(
        Icon(graphics = {Rectangle(origin = {0, -1}, lineThickness = 0.5, extent = {{-100, 47}, {100, -47}}), Text(origin = {0, -1}, extent = {{-26, 13}, {26, -13}}, textString = "Gyrotron")}));
    end Gyrotron;

    model WaveGuide "Model for the efficiency of Waveguide network where the RF power will pass through quasi-optical, mirror-based mitre joints, chemical vapour deopsition windows (CVD). The RF power travelling to the plasma will experience wall losses in the tokamak. Mode converter converts from hybrid mode to gaussian mode which is fed to the launcher. Losses in each stage are estimated to calculate the Waveguide efficiency."
      // Custom model validation for Waveguide WG45 using default values 7mitre bends, 100m length, 45mm diamter and 110GHz frequency
      import SI = Modelica.SIunits;
      import MATH = Modelica.Math;
      pfcon pfcon1 annotation(
        Placement(visible = true, transformation(origin = {-92, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      pfcon pfcon2 annotation(
        Placement(visible = true, transformation(origin = {92, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {90, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      //
      // Data Import - Required funtion to import .mat file containing RF thermal power profile
      import Modelica.Blocks.Sources.CombiTimeTable;
      parameter String dataPath;
      Modelica.Blocks.Sources.CombiTimeTable combiTimeTable1D(fileName = dataPath, tableOnFile = true, tableName = "data");
      SI.Power P_plasma = combiTimeTable1D.y[1] "Thermal power output into plasma from WG (W) /old value 1.58e6/";
      //
      parameter Real in_coupling(unit = "percent") = 1.9 "Waveguide input coupling inefficiency (losses)in percent";
      parameter Real out_coupling(unit = "percent") = 1.9 "Waveguide output coupling inefficiency (losses) in percent";
      parameter Real CVD_Eff(unit = "percent") = 0.3 "CVD reflections in percent";
      parameter Real Launch_Eff(unit = "percent") = 1.0 "Launcher inefficiency (losses) in percent";
      parameter Real Num_mitre = 7.0 "Mitre bends";
      Real pi = 2 * MATH.asin(1.0) "pi = 3.14159265358979";
      SI.PermeabilityOfVacuum mu_0 = 1.25663706e-6 "Permeability of free space (H/m)";
      SI.Resistivity r_c = 17e-19 "Resistivity of Copper (Ohm.m)";
      SI.RelativePermeability mu_c = 0.999994 "Relative permeability of Copper";
      SI.Impedance Z_0 = 377 "Impedance of free space (Ohm)";
      parameter SI.Diameter D = 0.063 "Diameter of waveguide (m)";
      parameter SI.Length L = 100 "Length of waveguide (m)";
      parameter SI.Frequency freq = 110e9 "Frequency (Hz)";
      parameter SI.Velocity c = 3e8 "Velocity of light in vacuum (m/s)";
      //
      Real Mitre_Eff(unit = "percent") "Mitre bends inefficiency";
      Real k(unit = "1") "Propagation constant of free space";
      Real Rs(unit = "1/Ohm") "Sheet resistance (1/Ohm)";
      //Rs = r_c/skin depth
      Real a_Np "Attenuation in Np";
      Real Trans_Eff(unit = "percent") "Attenuation efficiency (losses) in percent";
      Real Tot_Loss(unit = "percent") "Sum of losses (inefficiencies) in percent";
      Real WG_Eff(unit = "percent") "Efficiency of waveguide in percent";
      //
    equation
      Mitre_Eff = 100 * Num_mitre * 0.55 * (c / freq / D) ^ 1.5;
      k = 2 * pi * freq / c;
      Rs = r_c / sqrt(r_c / (pi * freq * mu_c * mu_0));
      a_Np = Rs / Z_0 * 3.832 ^ 2 / ((D / 2) ^ 3 * k ^ 2);
      Trans_Eff = 100 * (1 - 1 / exp(L * 0.69 * a_Np));
      Tot_Loss = in_coupling + out_coupling + CVD_Eff + Mitre_Eff + Trans_Eff + Launch_Eff;
      WG_Eff = 100 - Tot_Loss;
      //
      pfcon2.p = P_plasma;
      pfcon1.p = pfcon2.p * (100 / WG_Eff) "Waveguide input power calculation";
      //
      //Runtime Assertions
      assert(Mitre_Eff >= 0, "---> Assertion Error in [WaveGuide], variable [Mitre_Eff = " + String(Mitre_Eff) + "] cannot be negative!", level = AssertionLevel.error);
      assert(Mitre_Eff <= 100, "---> Assertion Warning in [WaveGuide], variable [Mitre_Eff = " + String(Mitre_Eff) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(k >= 0, "---> Assertion Error in [WaveGuide], variable [k = " + String(k) + "] cannot be negative!", level = AssertionLevel.error);
      assert(k <= 1e4, "---> Assertion Warning in [WaveGuide], variable [k = " + String(k) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(Rs >= 0, "---> Assertion Error in [WaveGuide], variable [Rs = " + String(Rs) + "] cannot be negative!", level = AssertionLevel.error);
      assert(Rs <= 1e-5, "---> Assertion Warning in [WaveGuide], variable [Rs = " + String(Rs) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(a_Np >= 0, "---> Assertion Error in [WaveGuide], variable [a_Np = " + String(a_Np) + "] cannot be negative!", level = AssertionLevel.error);
      assert(a_Np <= 1e-5, "---> Assertion Warning in [WaveGuide], variable [a_Np = " + String(a_Np) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(Trans_Eff >= 0 and Trans_Eff <= 100, "---> Assertion Error in [WaveGuide], variable [Trans_Eff = " + String(Trans_Eff) + "] outside of acceptable range!", level = AssertionLevel.error);
      assert(Trans_Eff <= 1e-3, "---> Assertion Warning in [WaveGuide], variable [Trans_Eff = " + String(Trans_Eff) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(Tot_Loss >= 0, "---> Assertion Error in [WaveGuide], variable [Tot_Loss = " + String(Tot_Loss) + "] cannot be negative!", level = AssertionLevel.error);
      assert(Tot_Loss <= 20, "---> Assertion Warning in [WaveGuide], variable [Tot_Loss = " + String(Tot_Loss) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(WG_Eff >= 0 and WG_Eff <= 100, "---> Assertion Error in [WaveGuide], variable [WG_Eff = " + String(WG_Eff) + "] outside of acceptable range!", level = AssertionLevel.error);
      assert(WG_Eff <= 50, "---> Assertion Warning in [WaveGuide], variable [WG_Eff = " + String(WG_Eff) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(pfcon1.p >= 0, "---> Assertion Error in [WaveGuide], variable [pfcon1.p = " + String(pfcon1.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon1.p <= 1e9, "---> Assertion Warning in [WaveGuide], variable [pfcon1.p = " + String(pfcon1.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      assert(pfcon2.p >= 0, "---> Assertion Error in [WaveGuide], variable [pfcon2.p = " + String(pfcon2.p) + "] cannot be negative!", level = AssertionLevel.error);
      assert(pfcon2.p <= 1e9, "---> Assertion Warning in [WaveGuide], variable [pfcon2.p = " + String(pfcon2.p) + "] outside of reasonable range!", level = AssertionLevel.warning);
      //
      annotation(
        Icon(graphics = {Text(origin = {0, -1}, extent = {{-30, 15}, {30, -15}}, textString = "Wave Guide"), Rectangle(origin = {0, -2}, lineThickness = 0.5, extent = {{-100, 52}, {100, -46}})}));
    end WaveGuide;

    connector pfcon
      import SI = Modelica.SIunits;
      SI.Power p;
      //
      annotation(
        Icon(graphics = {Rectangle(origin = {0, -1}, fillColor = {76, 76, 76}, fillPattern = FillPattern.Solid, extent = {{-100, 99}, {100, -99}})}));
    end pfcon;
    annotation(
      uses(Modelica(version = "3.2.3")));
  end RF;
end HCDSystemPkg;
