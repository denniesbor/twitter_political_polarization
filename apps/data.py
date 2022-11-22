"""
Data to be renderd from the app

"""
import json

# read json file c
with open("./notebooks/data.json") as json_file:
    all_options = json.load(json_file)


"""plotly dashboards templates"""

templates = [
    "bootstrap",
    "crulean",
    "cosmo",
    "darkly",
    "flatly",
    "journal",
    "litera",
    "lumen",
    "lux",
    "materia",
    "minty",
    "morph",
    "pulse",
    "quartz",
    "sandstone",
    "simplex",
    "sketchy",
    "slate",
    "solar",
    "spacelab",
    "superhero",
    "vapor",
    "yeti",
    "zephyr",
]

# logo
PLOTLY_LOGO = "https://images.plot.ly/logo/new-branding/plotly-logomark.png"
