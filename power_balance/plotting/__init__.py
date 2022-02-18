"""
Plotting of PBM Session results
===============================

This module contains all methods for the visual display of PBM session results.

Contents
========

Functions
---------

    launch_viewer - launch plot browser

Submodules
----------

    browser - contains browser creation methods
    common - common plotting methods
    image - methods relating to plot image creation
    profile_plotting - methods relating to creation of input profile plotting
    result_plotting - methods relating to model run output plot creation

"""

__date__ = "2021-06-10"

import os
import webbrowser


def launch_viewer(results_directory: str):
    """Launch the browser window with the plot webpage

    Parameters
    ----------
    results_directory : str
        directory containing output files
    """
    _html_file = os.path.join(results_directory, "html", "viewer.html")
    if not os.path.exists(_html_file):
        raise FileNotFoundError(
            f"Cannot open viewer for directory '{results_directory}', "
            "folder does not contain valid results"
        )

    webbrowser.open(_html_file)
