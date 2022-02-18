#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Simulation Options Config Validation
====================================

Validation of simulations options passed to OpenModelica itself.

Contents
========

Validator classes
-----------------
    Solver          - list of allowed/recognised OM solvers
    SimOpsModel     - validates OM simulation options provided
    PlasmaScenario  - validates plasma scenario options

"""

__date__ = "2021-06-08"

import enum
import typing

import pydantic

import power_balance.validation as pbm_check


class Solver(str, enum.Enum):
    DASSL = "dassl"
    IDA = "ida"
    CVODE = "cvode"
    IMPEULER = "impeuler"
    TRAPEZOID = "trapezoid"
    IMPRUNGEKUTTA = "imprungekutta"
    EULER = "euler"
    HEUN = "heun"
    RUNGEKUTTA = "rungekutta"
    RUNGEKUTTASSC = "rungekuttaSsc"
    IRKSCO = "irksco"
    SYMSOLVER = "symSolver"
    SYMSOLVERSSC = "symSolverSsc"
    QSS = "qss"


class FromUnityInt(pydantic.ConstrainedInt):
    ge = 1
    strict = True


class FromZeroInt(pydantic.ConstrainedInt):
    ge = 0
    strict = True


class SmallestFloat(pydantic.ConstrainedFloat):
    ge = 1e-36
    strict = True


class SimOptsModel(pydantic.BaseModel):
    stopTime: FromUnityInt = pydantic.Field(
        ..., title="stopTime", description="Simulation end time"
    )
    startTime: FromZeroInt = pydantic.Field(
        ..., title="startTime", description="Simulation start time"
    )
    stepSize: typing.Union[SmallestFloat, FromUnityInt] = pydantic.Field(
        ..., title="stepSize", description="Simulation time intervale"
    )
    solver: Solver = pydantic.Field(
        Solver.DASSL, title="Solver", description="Solver to use during OM simulation"
    )
    tolerance: SmallestFloat = pydantic.Field(
        ..., title="Tolerance", description="Tolerance for solutions in OM simulation"
    )

    @pydantic.root_validator(skip_on_failure=True)
    def check_time_vals(cls, values: typing.Dict):
        _start: int = values["startTime"]
        _stop: int = values["stopTime"]
        _step: float = values["stepSize"]

        if _start > _stop:
            raise AssertionError(
                f"Start time must be before stop time: {_start} !< {_stop}"
            )
        if _step > _stop:
            raise AssertionError(
                f"Step size must be less than stop time : {_step} !< {_stop}"
            )

        return values

    class Config(pbm_check.ModelConfig):
        pass


class PlasmaScenario(pydantic.BaseModel):
    plasma_ramp_up_start: FromZeroInt = pydantic.Field(
        ...,
        title="Plasma Ramp-Up Start",
    )
    plasma_flat_top_start: FromZeroInt = pydantic.Field(
        ..., title="Plasma Flat-Top Start"
    )
    plasma_flat_top_end: FromZeroInt = pydantic.Field(..., title="Plasma Flat-Top End")
    plasma_ramp_down_end: FromZeroInt = pydantic.Field(
        ..., title="Plasma Ramp-Down End"
    )

    @pydantic.root_validator(skip_on_failure=True)
    def check_profile_vals(cls, values: typing.Dict):
        _prus: float = values["plasma_ramp_up_start"]
        _pfts: float = values["plasma_flat_top_start"]
        _pfte: float = values["plasma_flat_top_end"]
        _prde: float = values["plasma_ramp_down_end"]

        _conditions = [_prus < _pfts, _pfts < _pfte, _pfte < _prde]

        if not all(_conditions):
            raise AssertionError(
                "Profile time values are misordered, "
                f"got times {_prus}, {_pfts}, {_pfte}, {_prde}"
            )

        return values

    class Config(pbm_check.ModelConfig):
        pass
