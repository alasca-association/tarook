import argparse
import datetime
import json
from uuid import uuid4

import yaml

# CLI Arguments
parser = argparse.ArgumentParser(
    description="Generating SBOM of the Ansible collections"
)
parser.add_argument("-i", "--input", help="Path of the requirement file")
parser.add_argument("-o", "--output", help="Path of the requirement file")
args = parser.parse_args()


def getRequirements(path):
    """load the requirements"""

    ret = []

    with open(path, "r") as file:
        docs = yaml.safe_load_all(file)
        for doc in docs:
            ret = doc.get("collections", [])

    return ret


def generateComponents():
    """write a component"""

    components = []
    col = getRequirements(args.input)
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
        json.dump(sbomContent, file)


if __name__ == "__main__":
    writeSBOM(args.output)
