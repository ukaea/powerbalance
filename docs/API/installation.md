## Supported Environments
Power Balance Models (PBM) has been confirmed to work on:

- Ubuntu 20.04 - 21.10
- Windows 7 SP1*
- Windows 10*

\* using Python for Windows and CMD.

The PBM is not tested on Mac systems.
The software requires:

- Python `>= 3.8.6`. Recommended version is `3.9.9`, which you can download from the bottom of the page [here](https://www.python.org/downloads/release/python-399/));
- OpenModelica `>= 1.14.4`. Recommended version is `1.17.0`, which you can download from [here (Windows)](https://build.openmodelica.org/omc/builds/windows/releases/1.17/0/) or [here (Unix)](https://build.openmodelica.org/omc/builds/linux/releases/1.17.0/) (instructions in https://www.openmodelica.org/download/download-linux). Installation on Mac (not stable) can be found [here](https://www.openmodelica.org/download/download-mac);

It is recommended you run the software from within a virtual environment system such as [PyEnv](https://github.com/pyenv/pyenv) or the built-in `venv` module, this ensures there is no interference with your system python installation. Alternatively you can install it under the current user.

## Installation for UNIX and Windows
Downloads are available [here](https://github.com/ukaea/powerbalance/releases). You can install the package using `pip` on the wheels file:

```bash
pip install power_balance-<version>-py3-none-any.whl
```

To install this package you will firstly need to install OpenModelica to your system. The module works by either finding the location of an `omc` installation (in the case of UNIX) or using the environment variable `%OPENMODELICAHOME%` in the case of Windows.

!!! warning "Modelica Standard Library version"
    The Power Balance Models API is not compatible with Modelica Standard Library `>=4.0.0`.
    Significant changes have been implemented in these versions. Latest known working environment
    is OpenModelica `1.18.0` with MSL `3.2.3`.

Installation on Mac is not tested and not supported by the Power Balance team, primarily because of the difficulty associated with installing OpenModelica on Mac.

## Testing
You can verify your install is working correctly by either running the default configuration using the `powerbalance` command, or by running the included tests using `pytest`:

```bash
pytest -s tests/
```