# Change Log

## v1.1.0 - 2022-03-09

* Added support for Windows.
* Use context manager to ensure removal of temporary files.
* Compatible with PyDelica v0.4.2

## v1.0.0 - 2022-02-09

* First full version of Power Balance ready for open sourcing.
* Fixed bug in Modelica file parsing.
* Refactor of code and addressing some minor issues.

## v0.15.0-alpha - 2022-01-25

* Separation of plugins completely from CLI to be used as optional extensions.
* The main Modelica file has been split into constituent physics models, improving the development process and version
  control.
* Users can now control the plasma scenario (profile generation) timings, allowing a setup of a more realistic
  simulation.
* Steady-state values (average from plasma flat-top) now visible under the "Steady-State" tab of the HTML viewer (
  previously called "Efficiencies").
* Cleaned up leftover HTML documentation code.
* Cleaned up coolant detritiation model code and cryogenics model code.
* Added efficiency calculations for RF and NBI systems (to the "Steady-State" tab of the viewer).
* Heating and Current Drive profile modified in line with the suggestion by Mark Henderson.
* Proper RF (gyrotron) model implemented.
* Documentation bugfixes.
* Added (preliminary) assertions within the Modelica code to assist with finding errors, and associated unit tests.
* Enabled the selection of so-called 'structural parameters' from outside of Modelica.
* Removed the obsolete CoolingMagnets, meaning neutronic heating is now inserted manually.
* Certain input parameters can be used to create profiles, from which the maximum value can be extracted inside
  Modelica.
* The wallplug efficiency of HCD, the power supply efficiency of the magnets, and the power generation conversion
  efficiency can now be set using a constant value.
* The superconducting model can now be turned off and instead a simple '(near) zero-resistance' model can be used.

## v0.13.8-alpha - 2021-06-28

* Removed dependency on OMPython in favour of a serverless alternative PyDelica.
* Added power generation models to power consumption calculation.
* Improved support for running within an interactive Python session.
* Uses only Jinja templates for HTML page generation.
* Added input profiles to browser display.
* Profiles (magnet currents, HCD, plasma thermal) are now generated more realistically, with the plasma scenario in
  mind.
* Process engineering models received a major code overhaul.
* Modelica code was made to be uniform (e.g. parameter naming, formatting).
* Fixed a bug where the thermal power profile was not created properly.
* Fixed a bug where some detrit models would produce less power incorrectly.
* Fixes to bootstrap HTML and tidy up of tables.
* Added efficiencies tab in browser output.
* All documentation migrated from Modelica to GitLab Pages.
* Running the API in interactive mode within a Python enviornment is enabled.

## v0.11.2-alpha - 2021-03-09

* Switch to Poetry for development of module.
* Added Python API for running of models via OMPython.
* Reading of inputs from configuration and parameter files.
* Parameter sweeps where multiple values per parameter specified.
* Power consumption from feeders added.
* Addition of NINI model.
* Separation of heat profiles for NBI and RF.
* Move from Tk window for plot display to browser window.
* Use HDF5 as data output file type storing data frames from power outputs.

## pre-api - 2021-01-13

* Creation of `Tokamak.Interdependencies` Modelica model with components for Magnets, Cryogenics and Detritation.
