# Getting Started
Power Balance Models (PBM) can be run via a command line interface (CLI) or by constructing scripts to access the API. Whichever case is chosen runs can be customised by the user as much (or as little) as required.

## Example run
As there are existing configurations within the API you can run PBM 'out the box' using the available CLI command:

```bash
powerbalance run
```

after the run is completed a new timestamped directory will be produced containing not only the results but a preserved copy of the configuration set to achieve them. This is useful for recreating runs.

In addition your chosen browser should be launched to show a webpage displaying the power data plots as dynamic widgets which can be interacted with.

## Viewing existing plots
A new plot browser window can be opened on any results directory using the `view-results` command:

```sh
powerbalance view-results <pbm_results_dir>
```

## Viewing the data
Data is written to a HDF5 file, with each model's output being written to the file as a single dataframe the key for which is the model name in lower case with any `.` being replaced with `_`.

The recommended method for accessing the data is using the Pandas module. In the case of the `Tokamak.Interdependencies` model:

```python
import pandas as pd
import glob
import os
import argparse

# Create a parser so we can select the result directory
# we which to view from the command line
parser = argparse.ArgumentParser()
parser.add_argument('result_dir')
args = parser.parse_args()

# Use glob to lazily find the HDF5 file
hdf5_file = glob.glob(
    os.path.join(args.result_dir, 'data', '*.hdf5')
)[0]

# Accessing the dataframe using the key within the file
data_frame = pd.read_hdf(hdf5_file, key='tokamak_interdependencies')

print(data_frame)
```
data frames are very powerful objects, you can apply cuts to them and perform operations on subsets, see the [Pandas documentation](https://pandas.pydata.org/docs/) for details.

## Creating your own scripts
The main class used to initialise and run a simulation via the OpenModelica backend within PBM is the `PowerBalance` class.

```python
from power_balance.core import PowerBalance

# Initialise the PBM class fetching parameters
# and models from the default locations
pbm_instance = PowerBalance()

# Run the simulation with the configuration
pbm_instance.run_simulation()

# Open the plots in the browser window
pbm_instance.launch_browser()
```