"""
Generating SBOM of runtime dependencies, it collects dependencies of Helm Charts
and ansible galaxy collections.

Args:
    -a, --ansible <file>: file path to the ansible galaxy requirement file
    -n, --nix-helm <dir>: directory path to the nix files which declare helm charts

Returns:
    Generates a SBOM as a json file.
"""

import argparse
import datetime
import json
import os
import re
from uuid import uuid4

import yaml

# CLI Arguments
parser = argparse.ArgumentParser(description="Generating SBOM for runtime dependencies")
parser.add_argument("-a", "--ansible", help="Path of the ansible requirement file")
parser.add_argument("-n", "--nix-helm", help="Path of the nix helm file")
parser.add_argument("-o", "--output", help="Path of the requirement file")
args = parser.parse_args()


def getRequirementsAnsible(path):
    """returns map with dependencies of ansible"""

    ret = []

    with open(path, "r") as file:
        docs = yaml.safe_load_all(file)
        for doc in docs:
            ret = doc.get("collections", [])

    return ret


def getRequirementsHelmNix(path):
    """returns map with dependencies of helm charts declared by nix"""

    ret = []

    namePattern = re.compile(
        r"#\s*renovate:\s*datasource=helm\s+depName=(\S+)\s+registryUrl=(\S+)"
    )

    versionPattern = re.compile(r'(?:default|defaultChartVersion)\s*=\s*"v?([^"]+)"')

    for f in os.scandir(path):
        if f.is_file():
            with open(f, "r") as file:
                lines = file.readlines()
                for i, line in enumerate(lines):
                    match = re.search(namePattern, line)
                    if not match:
                        continue
                    component = {"name": match.group(1), "repo": match.group(2)}
                    for next_line in lines[i + 1:i + 8]:
                        match = re.search(versionPattern, next_line)
                        if not match:
                            continue
                        component["version"] = match.group(1)

                    ret.append(component)

    return ret


def generateComponents():
    """write a component"""

    components = []

    if args.ansible:
        col = getRequirementsAnsible(args.ansible)
        for comp in col:
            tmpDict = {
                "type": "application",
                "bom-ref": str(uuid4()),
                "name": comp["name"],
                "version": comp["version"],
                "scope": "required",
                "purl": f"pkg:ansible/{comp['name']}@{comp['version']}",
            }
            components.append(tmpDict)

    if args.nix_helm:
        col = getRequirementsHelmNix(args.nix_helm)
        for comp in col:
            tmpDict = {
                "type": "application",
                "bom-ref": str(uuid4()),
                "name": comp["name"],
                "version": comp["version"],
                "scope": "required",
                "purl": f"pkg:helm/{comp['name']}@{comp['version']}?"
                f"repository_url={comp['repo']}",
            }
            components.append(tmpDict)

    return components


def writeSBOM(path):
    """write the whole sbom"""

    comps = generateComponents()

    sbomContent = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.7",
        "serialNumber": f"urn:uuid:{str(uuid4())}",
        "version": 1,
        "metadata": {
            "timestamp": datetime.datetime.now().strftime("%Y-%m-%dT%XZ"),
            "authors": [
                {
                    "email": "test@cloudandheat.com",
                },
            ],
            "component": {
                "type": "application",
                "name": "tarook-ansible",
                "version": "",
                "scope": "required",
            },
        },
        "components": comps,
    }

    with open(path, "w") as file:
        json.dump(sbomContent, file, indent=4)


if __name__ == "__main__":
    writeSBOM(args.output)
