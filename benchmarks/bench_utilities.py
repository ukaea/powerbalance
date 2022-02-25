"""
Benchmarks of Power Balance Utility methods
"""

import power_balance.utilities as pbm_util


class ValueConversion:
    pretty_name = "String to value conversion"
    params = ["3.815", "4", "3i+5", "False"]

    def time_value_conversion(self, n):
        pbm_util.convert_to_value(n)


class DictionaryFlatten:
    pretty_name = "Dictionary flattening"
    params = [
        {
            "A": "B",
            "C": {
                "D": "E",
                "F": {"G": "H"},
            },
            "I": {"J": "K", "L": ["M", "N"]},
        }
    ]

    def time_dictionary_flatten(self, n):
        pbm_util.flatten_dictionary(n)


class DictionaryExpand:
    pretty_name = "Dictionary expansion"
    params = [{"A": "B", "C.D": "E", "C.F.G": "H", "I.J": "K", "I.L": ["M", "N"]}]

    def time_dictionary_flatten(self, n):
        pbm_util.expand_dictionary(n)
