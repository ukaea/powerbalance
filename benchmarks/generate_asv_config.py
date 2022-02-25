#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Airspeed Velocity Config File Generation
========================================

This script generates a new configuration file which can be specified
when running Airspeed Velocity for benchmarking.

"""

__date__ = "2021-06-14"
import json
import os
import pathlib
import subprocess

import click


@click.command()
@click.option(
    "--repo-dir",
    help="Repository root directory",
    default=pathlib.Path(__file__).parents[1],
)
@click.option(
    "--project-site",
    help="Project website URL",
    default="https://ukaea.github.io/powerbalance/",
)
@click.option(
    "--benchmarks-dir",
    help="Location of Benchmark tests",
    default=os.path.dirname(__file__),
)
@click.option(
    "-o",
    "--output",
    help="Output file name",
    default=os.path.join(os.path.dirname(__file__), "asv_config.json"),
)
@click.option(
    "-w",
    "--html-output-dir",
    help="Location of HTML site output files",
    default=os.getcwd(),
)
@click.option(
    "-r",
    "--results-output-dir",
    help="Location of benchmark test results",
    default=os.path.join(os.path.dirname(__file__), "results"),
)
@click.option("-b", "--branches", help="branch names comma separated", default="main")
@click.option(
    "-n",
    "--name",
    help="project name, defaults to parent directory",
    default="powerbalance",
)
@click.option(
    "--url", help="Repository URL", default="https://github.com/ukaea/powerbalance"
)
@click.option(
    "-e",
    "--env",
    help="Virtual environment option for ASV",
    default="virtualenv",
)
@click.option(
    "-v", "--config-version", help="Version for this configuration", default=1
)
@click.option(
    "-E",
    "--env-dir",
    help="Location to place generated virtual environments",
    default=os.getcwd(),
)
def generate_asv_config(
    repo_dir: str,
    name: str,
    project_site: str,
    benchmarks_dir: str,
    output: str,
    results_output_dir: str,
    html_output_dir: str,
    env_dir: str,
    branches: str,
    url: str,
    env: str,
    config_version: str,
) -> None:
    """
    Generate the ASV configuration file used during the benchmarking

    Arguments
    ---------
    repo_dir      path to the locally cloned copy of repitory, this is
                        used during the publication stage.

    project_site_url    URL for the GitLab pages hosted site.

    benchmarks_dir      location of benchmark tests.


    Optional Arguments
    ------------------
    output              name of the output JSON file to generate.
                        default is 'asv_config.json'.

    name                name of the project, defaults to parent directory.

    results_output_dir  output location for the benchmark test results, this
                        is usually itself a git repository.
                        default is current working directory.

    html_output_dir     output location for the generated HTML site.
                        default is current working directory.

    env_dir             place in which generated virtual environments are
                        kept. default is current working directory.

    branches            names of branch to get results from.
                        default is 'develop' (e.g. 'develop,master').

    url                 project repository URL.

    env                 virtual environment option for ASV.
                        default is 'virtualenv' (i.e. ASV will create
                        temporary environments with this tool).

    config_version      config version number for ASV config type.
                        default is 1.

    """
    _commit_base_url = os.path.join(url or project_site, "commit/")
    _branches = branches.split(",")

    _py_script = """
import shutil
import os

shutil.move('dist', os.path.join('{build_dir}', 'dist'))"""

    _build_cmds = [
        "python -mpip install poetry",
        "PIP_NO_BUILD_ISOLATION=false poetry build",
        f'python -c "{_py_script}"',
    ]

    _uninstall_cmds = ["return-code=any python -mpip uninstall -y power_balance"]
    _install_cmds = [
        "in-dir={build_dir} python -mpip install --find-links=dist/ power_balance"
    ]

    _req_file_candidate = os.path.join(repo_dir, "requirements.txt")

    if os.path.exists(_req_file_candidate):
        try:
            subprocess.run(
                ["git", "ls-files", "--error-unmatch", "requirements.txt"],
                check=True,
                shell=False,
            )
            _install_cmds += [
                "in-dir={env_dir} python -mpip install"
                f" -r {os.path.join('{build_dir}', 'requirements.txt')}"
            ]
        except subprocess.CalledProcessError:
            click.echo(
                "Warning: File 'requirements.txt' is not tracked, and so will not be picked up by ASV"
            )

    _intro_str = f"""
===============================================================================

                     Airspeed Velocity Config Generator

                            K. Zarebski, UKAEA


    Specified
    ---------
    Project Name                :       {name}
    Output File                 :       {output}
    Project Directory           :       {repo_dir}
    Project URL                 :       {url}
    GitLab Pages Site URL       :       {project_site}
    Branches                    :       {_branches}
    Environment Manager         :       {env}
    Benchmarks Directory        :       {benchmarks_dir}
    Environments Directory      :       {env_dir}
    HTML Output Directory       :       {html_output_dir}
    Results Output Directory    :       {results_output_dir}
    Config Syntax Version       :       {config_version}

    Assumed
    -------
    Commit Base URL             :       {_commit_base_url}
    DVCS                        :       Git
    Build Commands              :       {"[" + f'{71 * " "}'.join(_build_cmds) + "]"}
    Install Commands            :       {"[" + f'{71 * " "}'.join(_install_cmds) + "]"}
    Uninstall Commands          :       {"[" + f'{71 * " "}'.join(_uninstall_cmds) + "]"}

===============================================================================
    """

    print(_intro_str)

    # ASV Config uses relative paths

    _rel_repo_path = os.path.relpath(repo_dir, pathlib.Path(output).parent)

    _rel_benchmark_path = os.path.relpath(benchmarks_dir, pathlib.Path(output).parent)

    _rel_html_path = os.path.relpath(html_output_dir, pathlib.Path(output).parent)

    _config_dict = {
        "version": int(config_version),
        "project": name or os.path.basename(repo_dir),
        "repo": _rel_repo_path,
        "project_url": project_site,
        "install_command": _install_cmds,
        "build_command": _build_cmds,
        "uninstall_command": _uninstall_cmds,
        "branches": _branches,
        "show_commit_url": _commit_base_url,
        "benchmark_dir": _rel_benchmark_path,
        "dvcs": "git",
        "environment_type": env,
        "env_dir": env_dir,
        "results_dir": results_output_dir,
        "html_dir": _rel_html_path,
    }

    with open(output, "w") as f:
        json.dump(_config_dict, f, indent=4)


if __name__ in "__main__":
    generate_asv_config()
