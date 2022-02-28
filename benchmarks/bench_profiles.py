"""
ASV Benchmarks for Model Profile Input Generation
"""
import glob
import os.path
import re
import tempfile

import power_balance.profiles as pbm_prof


class ProfileGeneration:
    pretty_name = "Profile Generation"
    params = [
        re.findall(r"gen_([A-Z0-9\_]+)_profile", i, re.IGNORECASE)[0]
        for i in pbm_prof.__dict__.keys()
        if "gen_" in i
    ]
    param_names = ["profile"]

    def time_profile_generation(self, profile):
        getattr(pbm_prof, f"gen_{profile}_profile")()


class ProfileToDataframe:
    pretty_name = "Profile2DataFrame"
    prof_dir = tempfile.TemporaryDirectory()

    def setup(self):
        pbm_prof.generate_all(self.prof_dir.name)
        self.example_prof = list(glob.glob(os.path.join(self.prof_dir.name, "*.mat")))[
            0
        ]

    def time_profile_to_dataframe(self):
        pbm_prof.read_profile_to_df(self.example_prof)
