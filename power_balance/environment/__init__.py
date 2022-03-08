import os.path

import toml

MODELICA_ENVIRONMENT = toml.load(
    open(os.path.join(os.path.dirname(__file__), "modelica.toml"))
).values()
