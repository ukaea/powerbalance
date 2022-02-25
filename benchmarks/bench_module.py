"""
Benchmarks related to module wide processes
"""


class ImportPowerBalance:
    pretty_name = "PowerBalance Module Import"

    def timeraw_import_powerbalance(self):
        return """
        import power_balance
        """
