import os
import pathlib

import yaml

DOCS_ROOT = os.path.join(os.path.dirname(__file__))


def append_markdown_docs(mkdocs_config: str, md_directory: str):
    """Add Markdown files to mkdocs.yml

    Parameters
    ----------
    mkdocs_config : str
        location of mkdocs config file
    md_directory : str
        directory containing markdown to import
    """
    if not os.path.exists(mkdocs_config):
        raise FileNotFoundError(f"Could not open '{mkdocs_config}', file not found")

    if not os.path.exists(md_directory):
        raise FileNotFoundError(
            f"Could not load markdown files from '{md_directory}', "
            "no such directory."
        )

    _mkdocs_config = yaml.load(open(mkdocs_config), Loader=yaml.UnsafeLoader)

    _nav_section = _mkdocs_config["nav"].copy()

    def has_x(check_list, x):
        _index_api = [
            i
            for i, _ in enumerate(check_list)
            if list(check_list[i].keys())[0].lower() == x.lower()
        ]
        if not _index_api:
            return None
        return _index_api[0]

    _api_content = _nav_section[has_x(_nav_section, "API")]["API"]

    _md_full_paths = list(pathlib.Path(md_directory).rglob("*.md"))
    _md_files = [os.path.relpath(i, start=DOCS_ROOT) for i in _md_full_paths]

    # Currently the API does not have python files below file depth 2
    _md_files = [
        i
        for i in _md_files
        if os.path.relpath(i, "Reference/power_balance").count(os.path.sep) < 2
    ]

    _addition = {"Reference": []}

    for f, path in zip(_md_files, _md_full_paths):
        _lines = open(path).readlines()
        _n_header = [i for i in _lines if "#" in i]
        if len(_n_header) < 2:
            continue
        if os.path.sep not in os.path.relpath(f, start="Reference/power_balance"):
            _label = os.path.splitext(os.path.basename(f))[0]
            if os.path.sep in _label:
                continue
            if _label == "index":
                continue
            _addition["Reference"].append({_label: f})
        elif (
            len([i for i in _md_files if os.path.basename(os.path.dirname(f)) in i]) < 2
        ):
            _label = os.path.basename(os.path.dirname(f))
            _addition["Reference"].append({_label: f})
        else:
            _label = os.path.dirname(
                os.path.relpath(f, start="Reference/power_balance")
            )
            _sub_label = os.path.basename(
                os.path.relpath(f, start="Reference/power_balance")
            )
            _sub_label = os.path.splitext(_sub_label)[0]

            if os.path.sep in _sub_label or os.path.sep in _label:
                continue

            if _sub_label == "index":
                _sub_label = _label

            if not has_x(_addition["Reference"], _label):
                _addition["Reference"].append({_label: [{_sub_label: f}]})
            else:
                _index = has_x(_addition["Reference"], _label)
                _addition["Reference"][_index][_label].append({_sub_label: f})

    _api_content.append(_addition)

    _mkdocs_config["nav"][has_x(_nav_section, "API")]["API"] = _api_content

    with open(mkdocs_config, "w") as f:
        yaml.dump(_mkdocs_config, f)


if __name__ in "__main__":
    append_markdown_docs(
        os.path.join(pathlib.Path(DOCS_ROOT).parent, "mkdocs.yml"),
        os.path.join(DOCS_ROOT, "Reference"),
    )
