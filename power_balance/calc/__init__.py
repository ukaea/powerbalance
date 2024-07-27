#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Calculations
============

Handles calculation of required values

Contents
========

Submodules
----------

    efficiency - model efficiency calculations

Classes
-------

    Efficiency - object to represent efficiencies and construct HTML string


"""

import typing

import numpy as np


class Efficiency:
    def __init__(
        self,
        name: str,
        numerator_name: str,
        denominator_name: str,
        description: str = "",
    ) -> None:
        """Initialise a new efficiency object

        Parameters
        ----------
        name : str
            label for the efficiency
        numerator_name : str
            numerator label
        denominator_name : str
            denominator label
        description : str, optional
            description of efficiency
        """
        self._name = name
        self._num_label = numerator_name
        self._denom_label = denominator_name
        self._nums: typing.List[float] = [0, 0]
        self._desc = description
        self._efficiency: typing.Optional[float] = None

    def calculate(
        self,
        numerator: typing.Union[float, np.ndarray],
        denominator: typing.Union[float, np.ndarray],
    ) -> float:
        """Calculate an efficiency from the given values and save it

        If the specified arguments are arrays the average of each is used.

        Parameters
        ----------
        numerator : float or numpy.ndarray
            numerator value
        denominator : float or numpy.ndarray
            denominator value

        Returns
        -------
        float
            efficiency value
        """
        _num: float = (
            numerator if isinstance(numerator, float) else np.average(numerator)
        )
        _denom: float = (
            denominator if isinstance(denominator, float) else np.average(denominator)
        )

        self._nums = [_num, _denom]

        self._efficiency = _num / _denom

        return self._efficiency

    def value(self):
        """Retrieve Efficiency value"""
        return self._efficiency

    def construct_html_form(self) -> str:
        if not self._efficiency:
            if self._efficiency == 0:
                raise ValueError(
                    "Efficiency value equals 0, object name: " f"{self._name}"
                )

            else:
                raise AssertionError(
                    "Cannot construct HTML for empty efficiency object,"
                    f" object name: {self._name}"
                )

        _frac = (
            "\\frac{" + f"{self._nums[0]:,.0f}" + "}{" + f"{self._nums[1]:,.0f}" + "}"
        )

        _index = int(np.ceil(np.log10(self._efficiency))) - 1

        if abs(_index) > 1:
            _base = self._efficiency / pow(10, _index)
            _out_num = f"{_base:.4f}\\times10^" + "{" + str(_index) + "}"
        else:
            _out_num = f"{self._efficiency:.2f}"

        _eff_sym = "\\epsilon_{\\mathrm{" + self._name + "}}"
        _str_frac = (
            "\\frac{\\mathrm{"
            + self._num_label.replace(" ", "\\ ").title()
            + "}}{\\mathrm{"
            + self._denom_label.replace(" ", "\\ ").title()
            + "}}"
        )
        return f"""
{'<br>' + self._desc + '<br>' if self._desc else ''}

\\[ {_eff_sym} = {_str_frac} = {_frac} = {_out_num} \\]
"""
