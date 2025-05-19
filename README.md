<p align="center">
<img
    style="display: block;
           margin-left: auto;
           margin-right: auto;
           width: 30%;"
    src="https://raw.githubusercontent.com/ukaea/powerbalance/main/docs/images/pbm_logo.svg"
    alt="Power Balance Models logo">
</img>
</p>

# Power Balance Models

[![DOI](https://zenodo.org/badge/450553622.svg)](https://zenodo.org/badge/latestdoi/450553622) [![Power Balance Models Ubuntu](https://github.com/ukaea/powerbalance/actions/workflows/build_run_linux.yml/badge.svg)](https://github.com/ukaea/powerbalance/actions/workflows/build_run_linux.yml) [![security: bandit](https://img.shields.io/badge/security-bandit-yellow.svg)](https://github.com/PyCQA/bandit) [![Python Versions](https://img.shields.io/badge/python-3.10%20|%203.11%20|%203.12-blue|%203.13-blue)]() [![Code style: ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)

A power balance model which combines power consumption and power generation data to assess the net power production of different designs for a tokamak power plant.

This code implements the PyDelica module to interface with Open Modelica models neatly summing together and displaying key results in a web browser.
It implements a power balance model to bring together power consumption and power generation data for assessing the net power produced by fusion power plant designs.

DISCLAIMER: Parameter values (particularly the ones in the input toml files) do not represent a suitable design point, and may or may not make physical sense. It is up to the user to verify that all parameters are correct.

## Quick Start

It is recommended that Power Balance Models (PBM) be run within a Python virtual environment, you can create one using the pre-installed `venv` python module:

```sh
python -m venv my_venv
source venv/bin/activate
```

then install PBM using `pip` over git:

```sh
pip install git+https://github.com/ukaea/powerbalance.git
```

By default the parameters contained within the models have no physical significance, it is recommended that these be modified to match the scenario for analysis. To do this create a new project folder:

```sh
powerbalance new my_project
```

and modify the parameter files within the directory. You can then execute a run using this directory:

```sh
powerbalance run --param-dir my_project
```

## Updating

Note, if updating your version of `powerbalance` it is strongly recommended that you re-generate the model profiles in case changes have been made which affect them:

```sh
powerbalance generate-profiles
```

## Acknowledgements

**NINI model** - This model is based on the in-house UKAEA work of D B King and E Surrey, referred to in the following publication:

Negative ion research at the Culham Centre for Fusion Energy (CCFE), R McAdams, A J T Holmes, D B King, E Surrey, I Turner and J Zacks, New Journal of Physics, Volume 18, December 2016, doi: <https://doi.org/10.1088/1367-2630/aa4fa1>
(R McAdams et al 2016 New J. Phys. 18 125013)

**RF (ECCD) model** - This model is based on the Masters Thesis of Samuel Stewart:

Modelling of Radio Frequency Heating and Current Drive Systems for Nuclear Fusion, Samuel Stewart, Integrated Engineering BEng Thesis, University of Cardiff, April 2021

**Power generation model** - the efficiency values used in the power generation model are derived from a separate Excel model produced by UKAEA. This Excel model built on a body of work produced by the Nuclear Advanced Manufacturing Research Centre and EGB Engineering for UKAEA:

"UKAEA STEP WP11: FEASIBILITY STUDY OF MODULAR REACTOR DESIGNS (LOT 2): FEASIBILITY OF ADVANCED NUCLEAR TECHNOLOGIES BALANCE OF PLANT (BOP)"
