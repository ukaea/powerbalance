#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Browser webpage templates
=========================

HTML templates to aid in generation of the PBM browser via Jinja

Contents
========

Module variables
----------------

    carousel - plot carousel template
    config_table - configuration table template
    plot_scroller - plot scroller template
    browser_display_page - full plot page template


Functions
---------

    render_parameter_table - generates HTML table of parameters

"""

__date__ = "2021-06-08"

import os

import jinja2


def _load_html_template(template_file: str) -> jinja2.Template:
    """Generate a template from a given Jinja template file

    Parameters
    ----------
    template_file : str
        jinja template file

    Returns
    -------
    jinja2.Template
        Jinja template object representing the loaded HTML template
    """
    _template_file = os.path.join(os.path.dirname(__file__), template_file)
    return jinja2.Template(open(_template_file).read())


def jinja_func_is_dict(obj):
    return isinstance(obj, dict)


def jinja_func_dict_items(dictionary):
    return dictionary.items()


def jinja_group_header(group_label):
    _header = group_label if "." not in group_label else group_label.split(".")[-1]
    return _header.replace("_", "   ").title()


def render_parameter_table(parameter_set) -> str:
    """Create the HTML for the parameter set table

    Parameters
    ----------
    parameter_set
        parameter set object to be displayed

    Returns
    -------
    str
        HTML for tabular representation
    """
    _model_table = _load_html_template("parameter_table.jinja")
    return _model_table.render(
        is_dict=jinja_func_is_dict,
        items=jinja_func_dict_items,
        header=jinja_group_header,
        parameter_set=parameter_set,
    )


config_table = _load_html_template("config_table.jinja")
plot_scroller = _load_html_template("plot_scroller.jinja")
browser_display_page = _load_html_template("browser.jinja")
steady_state_tab = _load_html_template("steady_state_tab.jinja")
