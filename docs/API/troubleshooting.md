# Troubleshooting

## Numpy dependency

You may encounter issues with `numpy` as a dependency, this can
usually fixed by installing it manually beforehand:
```bash
pip install numpy
```
if you are using UV make sure to run this command within the virtual environment:
```bash
uv pip install numpy
```

## PyTables build
Releases of PyTables for the latest version of Python are often not yet available. When an existing build is not downloadable `pip` will attempt to build the module locally. If required libraries are unavailable this build will likely fail and prevent installation. To fix this you should find a `pytables` wheels file appropriate to your system and Python installation [here](https://www.lfd.uci.edu/~gohlke/pythonlibs/#pytables). Install this file by running:
```bash
pip install <path-to-wheels-file>
```
or if using UV:
```bash
uv pip install <path-to-wheels-file>
```

## Command `uv` is not recognised
If you are using UV and the command `uv` is not recognised after installation make sure the location of your UV installation is added to the PATH environment variable. To find your local installation run:
```bash
python -m uv run which uv

```
and note the location given during the initialisation.

For example in the case of the prefix `C:\Users\<user>\AppData\Local\` on Windows, UV was found in `C:\Users\<user>\AppData\Local\Packages\PythonSoftwareFoundation.<python_version_string>\LocalCache\local-packages\Python<version-num>\Scripts` and this location is added to the PATH variable as described [here](https://helpdeskgeek.com/windows-10/add-windows-path-environment-variable/) or temporarily by running:
```bash
set "PATH=%PATH%;<location-of-uv.exe>"
```

## Command `powerbalance` is not recognised
If the command `powerbalance` is not recognised an alternative method for running Power Balance Models is to run the Python script:
```bash
python <path-to-clone-repo>/power_balance/cli/__init__.py
```
