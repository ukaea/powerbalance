"""
ASV Benchmarks for Models
"""
import os
import pathlib

import pydelica

from power_balance.environment import MODELICA_ENVIRONMENT

MODELS_DIR = os.path.join(pathlib.Path(__file__).parents[1], "power_balance", "models")

MODELS = [
    file_name
    for file_name in os.listdir(MODELS_DIR)
    if ".mo" in file_name and file_name != "Tokamak.mo"
]


class ModelBuild:
    pretty_name = "Modelica Model Building"
    params = [
        "WasteHeat.WasteHeatPower",
        "CryogenicPlant.CryogenicPower",
        "PowerGenEquations.PowerGenCaseByCase",
        "CoolantDetrit.CoolantDetritCaseByCase",
        "BlanketDetrit.Power_CarrierBreeder",
        "HCDSystemPkg.HCDSystem",
        "Magnets.TF_Magnet",
        "Magnets.PF_Magnet",
        "Tokamak.Interdependencies",
    ]
    param_names = ["model"]

    def setup(self, model):
        self.session = pydelica.Session()
        self.session.use_libraries(MODELICA_ENVIRONMENT)

    def time_model_build(self, model):
        _model_path = os.path.join(MODELS_DIR, f"{model.split('.')[0]}.mo")
        if "Tokamak" in model:
            self.session.build_model(_model_path, model, extra_models=MODELS)
        else:
            self.session.build_model(_model_path, model)

    def teardown(self, model):
        self.session._compiler.clear_cache()
