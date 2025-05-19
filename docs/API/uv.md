## Using UV
The easiest method for developing PBM is to use the tool [`uv`](https://docs.astral.sh/uv/) which combines handling of python dependencies, virtual environment, deployment and versioning.

### Installing PBM with uv
uv can be installed using `pip`:

```bash
pip install --user uv
```
you can now install the development version of PBM by running:

```bash
uv venv
```
within the repository directory. This will create a virtual environment containing all Python modules required to run the project as defined within the `pyproject.toml` file.

Any changes made within the repository will be picked up by `uv` whenever the code is run.

### Running PBM with uv
Run the `powerbalance` command from within the virtual environment by executing:

```bash
uv run powerbalance
```


## Troubleshooting
#### Troubleshooting
- If you encounter issues with `numpy` as a dependency, this can
usually fixed by installing it manually beforehand:
```bash
uv pip install numpy
```
- Another problem encountered on Windows systems is with the installation of PyTables, the error usually states that HDF5 libraries could not be located and is due to there being no built wheels in the PyPi database for the user's Python version and system architecture (when this is the case Python attempts to build the module itself). A working solution is to download the relevant `pytables` wheels for Windows from [here](https://www.lfd.uci.edu/~gohlke/pythonlibs/#pytables),
then install them with pip:
```
uv pip install <path-to-wheels-file>
```
- If you are using uv and the command `uv` is not recognised after it has been installed, make sure the location of your uv installation is added to PATH, to find the installation try running
```bash
python -m uv run which uv
```
and noting the address given during the initialisation. For example for the case of a prefix of `C:\Users\<user>\AppData\Local\`, uv was found in `C:\Users\<user>\AppData\Local\Packages\PythonSoftwareFoundation.<python_version_string>\LocalCache\local-packages\Python<version-num>\Scripts`.
This location is then added to the PATH variable as described [here](https://helpdeskgeek.com/windows-10/add-windows-path-environment-variable/) or temporarily

    In the case of Windows:
```bash
set "PATH=%PATH%;<location-of-uv.exe>"
```
for Linux/macOS:
```bash
export PATH=<location-of-uv>:$PATH
```

- If the command `powerbalance` is not available after install, you can also run the program via Python as normal:
```bash
uv run python <path-to-cloned-repo>/power_balance/cli/__init__.py
```
