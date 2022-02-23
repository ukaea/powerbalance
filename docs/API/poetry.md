## Using Poetry
The easiest method for developing PBM is to use the tool `poetry` which combines handling of python dependencies, virtual environment, deployment and versioning.

### Installing PBM with Poetry
Poetry can be installed using `pip`:

```bash
pip install --user poetry
```
you can now install the development version of PBM by running:

```bash
poetry install
```
within the repository directory. This will create a virtual environment containing all Python modules required to run the project as defined within the `pyproject.toml` file.

Any changes made within the repository will be picked up by `poetry` whenever the code is run.

### Running PBM with Poetry
There are two ways in which you can run the included `powerbalance` command. Either open a new shall within the created virtual environment:

```bash
poetry shell
```

then run:

```bash
powerbalance
```

or if you do not wish to leave the current shell prefix any command you want to run within the virtual environment with `poetry run`:

```bash
poetry run powerbalance
```

## Troubleshooting
#### Troubleshooting
- If you encounter issues with `numpy` as a dependency, this can
usually fixed by installing it manually beforehand:
```bash
poetry run pip install numpy
```
- Another problem encountered on Windows systems is with the installation of PyTables, the error usually states that HDF5 libraries could not be located and is due to there being no built wheels in the PyPi database for the user's Python version and system architecture (when this is the case Python attempts to build the module itself). A working solution is to download the relevant `pytables` wheels for Windows from [here](https://www.lfd.uci.edu/~gohlke/pythonlibs/#pytables),
then install them with pip:
```
poetry run pip install <path-to-wheels-file>
```
- If you are using Poetry and the command `poetry` is not recognised after it has been installed, make sure the location of your poetry installation is added to PATH, to find the installation try running
```bash
python -m poetry shell
```
and noting the address given during the initialisation. For example for the case of a prefix of `C:\Users\<user>\AppData\Local\pypoetry`, poetry was found in `C:\Users\<user>\AppData\Local\Packages\PythonSoftwareFoundation.<python_version_string>\LocalCache\local-packages\Python<version-num>\Scripts`.
This location is then added to the PATH variable as described [here](https://helpdeskgeek.com/windows-10/add-windows-path-environment-variable/) or temporarily

    In the case of Windows:
```bash
set "PATH=%PATH%;<location-of-poetry.exe>"
```
for Linux/macOS:
```bash
export PATH=<location-of-poetry>:$PATH
```

- If the command `powerbalance` is not available after install, you can also run the program via Python as normal:
```bash
python <path-to-cloned-repo>/power_balance/cli/__init__.py
```
