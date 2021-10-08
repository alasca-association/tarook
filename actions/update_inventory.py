#!/usr/bin/python3

import pathlib
import toml
import yaml
import os
import collections
import typing
import errno

from helpers import terraform_helper
from helpers import pass_helper
from helpers import wireguard_helper
from helpers import legacy_converter

# Path to the main configuration
CONFIG_PATH = pathlib.Path("config/config.toml")
# Path to the configuration template
CONFIG_TEMPLATE_PATH = pathlib.Path(
    "managed-k8s/templates/config.template.toml")
# Path to the generic Ansible variables
GENERIC_VARS_FILE = pathlib.Path(
    "managed-k8s/ansible/group_vars/all/config.yaml")
# Base path to the Ansible inventory
ANSIBLE_INVENTORY_BASEPATH = pathlib.Path("inventory")
# List of top level sections which we do accept in the main config
ALLOWED_TOP_LEVEL_SECTIONS = (
    "load-balancing",
    "ch-k8s-lbaas",
    "kubernetes",
    "node-scheduling",
    "k8s-service-layer",
    "testing",
    "passwordstore",
    "terraform",
    "wireguard",
    "ipsec",
    "cah-users",
    "miscellaneous",
)
# Mapping stages to their common names
ANSIBLE_STAGES = {
    "stage2": "02_trampoline",
    "stage3": "03_k8s_base",
    "stage4": "04_k8s_service_layer",
    "stage5": "05_k8s_managed_service"
}
# The k8s managed services layer is special because it requires only
# a subset of variables of services / sections. This Map defines which
# variable keys have to be exported for the k8s managed services layer
K8S_MANAGED_SERVICES_VAR_MAP = {
    "ch-k8s-lbaas": [
        "enabled",
        "agent_port"
    ],
    "node-scheduling": [
        "scheduling_key_prefix"
    ],
    "k8s-service-layer": {
        "rook": [
            "enabled"
        ],
        "prometheus": [
            # We probably wanna split up the monitoring variables
            # in the near future
        ]
    },
    # "kubernetes": [                       # now exported by a
    #     "use_podsecuritypolicies",        # workaround ...
    #     "version"
    # ]
}
# This maps defines the prefix that is assigned to each
# variable of a section
SECTION_VARIABLE_PREFIX_MAP = {
    "ch-k8s-lbaas": "ch_k8s_lbaas",
    "kubernetes": "k8s",
    "passwordstore": "passwordstore",
    "wireguard": "wg",
    "ipsec": "ipsec",
    "cah-users": "cah_users",
    "rook": "rook",
    "prometheus": "monitoring",
}


def cleanup_ansible_inventory(
    ansible_inventory_path: pathlib.Path = ANSIBLE_INVENTORY_BASEPATH
):
    """
    Cleaning up the inventory. Excluding directories and files we need to keep
    because they are generated by a third party.
    """
    exclude_file_prefixes = [
        "terraform_"
    ]
    exclude_files = [
        "hosts"
    ]
    exclude_dirs = [
        ".etc"
    ]

    # We need to traverse from the root to the leaves so that we can ignore
    # directories and their subdirectories. However, this makes removing empty
    # folders more complicated. Therefore, for the cleanup of empty
    # directories, we simply walk again over the directory tree starting from
    # the bottom.
    for dirpath, dirnames, filenames in os.walk(ansible_inventory_path,
                                                topdown=True):
        # do not process excluded directories
        dirnames[:] = [d for d in dirnames if d not in exclude_dirs]

        for inventory_file in filenames:
            remove_file = True
            for prefix in exclude_file_prefixes:
                if inventory_file.startswith(prefix):
                    remove_file = False
            if inventory_file in exclude_files:
                remove_file = False
            if not remove_file:
                continue
            full_path = pathlib.PurePath(dirpath, inventory_file)
            os.remove(full_path)

    # To cleanup empty directories we need to walk other again starting from
    # the leaves/bottom.
    for dirpath, dirnames, filenames in os.walk(ansible_inventory_path,
                                                topdown=False):
        # check if the folder is empty and delete it if so
        try:
            os.rmdir(dirpath)
        except OSError as exc:
            if exc.errno != errno.ENOTEMPTY:
                raise


def flatten_config(
    config: typing.MutableMapping,
    parent_key: str = "",
    sep: str = "_"
) -> typing.MutableMapping:
    """
    Flatten a dictionary/configuration. This is necessary if a key
    belongs to a higher level section like e.g. the "network" variables
    in the "kubernetes" section. This function flattens the keys and
    applies the section name as prefix to the key.
    Example: "plugin" in "kubernetes.network" --> "network_plugin"
    """
    items = dict()
    for key, value in config.items():
        new_key = (parent_key + sep + key) if parent_key else key
        if isinstance(value, collections.abc.MutableMapping):
            items.update(flatten_config(value, new_key, sep=sep).items())
        else:
            items.update({new_key: value})
    return dict(items)


def dump_to_ansible_inventory(
    config: typing.MutableMapping,
    ansible_inventory_path: pathlib.Path,
    key_prefix: str
):
    # Ensure config is not empty
    if not config:
        return

    # Ensure the respective inventory directory is existing
    ansible_inventory_path.parent.mkdir(exist_ok=True, mode=0o750,
                                        parents=True)
    # Flatten the config
    flat_config = flatten_config(config)

    # Apply key prefix
    if key_prefix:
        final_config = {}
        for key, value in flat_config.items():
            new_key = F'{key_prefix}_{key}'
            final_config[new_key] = value
    else:
        final_config = flat_config

    # Dump the variables as YAML
    with ansible_inventory_path.open("w") as fout:
        yaml.safe_dump(final_config, fout)


def print_process_state(
    section: str
):
    # Put into a function because it is used several times
    print(
        # "\N{gear} "
        "Section in process: "F"{section}")


def main():
    """
    * Cleanup
    * Load main config.toml
    * Validate top level sections of config
    * Process each section
    """

    print(
        "---\n"
        # "\N{airplane departure} "
        "Inventory-Helper: "
        "Start to process the configuration\n"
        "---"
    )

    # Load the main config.toml
    with CONFIG_PATH.open("r") as fin:
        config = toml.load(fin)

    # Check whether the config is in the legacy format
    legacy_sections = ["ansible", "terraform", "secrets"]
    if (set(config.keys()) == set(legacy_sections)):
        print(
            # "\N{older adult} "
            "Looks like your config is past prime. "
            "Taking care of the elderly now. Trying to rejuvenate it.")
        # Start to process the legacy config
        config = legacy_converter.convert_legacy_config(
            config,
            CONFIG_PATH,
            CONFIG_TEMPLATE_PATH
        )

    # Check that the config contains only valid top sections
    unallowed_keys = set(config.keys()) - set(ALLOWED_TOP_LEVEL_SECTIONS)
    if unallowed_keys:
        raise ValueError(
            "{} are unknown sections. Currently supported are {}".format(
                unallowed_keys,
                ALLOWED_TOP_LEVEL_SECTIONS)
        )

    # Config looks good on first sight, be brave and cleanup the inventory
    print(
        # "\N{broom} "
        "Cleaning up the inventory...")
    cleanup_ansible_inventory()

    # START PROCESSING THE TOP SECTIONS
    # ---
    # TERRAFORM
    # ---
    if (os.getenv('TF_USAGE', 'true') == 'true'):
        print_process_state("Terraform")
        terraform_helper.deploy_terraform_config(config.get("terraform"))

    # ---
    # WIREGUARD
    # ---
    # only if wireguard is desired
    if (os.getenv('WG_USAGE', 'true') == 'true'):
        print_process_state("Wireguard")
        wg_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage2"] /
            "group_vars" / "gateways" / "wireguard.yaml"
        )
        dump_to_ansible_inventory(
            wireguard_helper.generate_wireguard_config(
                config.get("wireguard")),
            wg_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("wireguard", "")
        )

    # ---
    # PASSWORD STORE
    # ---
    print_process_state("Password store")
    for stage in [ANSIBLE_STAGES["stage2"], ANSIBLE_STAGES["stage3"]]:
        pass_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage / "group_vars" / "all" /
            "passwordstore-users.yaml"
        )
        dump_to_ansible_inventory(
            pass_helper.generate_passwordstore_config(config["passwordstore"]),
            pass_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("passwordstore", "")
        )

    # ---
    # IPSEC
    # ---
    print_process_state("IPSec")
    ipsec_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage2"] /
        "group_vars" / "gateways" / "ipsec.yaml"
    )
    dump_to_ansible_inventory(
        config.get("ipsec"),
        ipsec_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("ipsec", "")
    )

    # ---
    # KUBERNETES
    # ---
    print_process_state("Kubernetes")
    kubernetes_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage3"] /
        "group_vars" / "all" / "kubernetes.yaml"
    )
    dump_to_ansible_inventory(
        config.get("kubernetes"),
        kubernetes_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("kubernetes", "")
    )
    # WORKAROUND: k8s_version, k8s_use_podsecurity_policies,
    # and k8s_is_gpu_cluster
    # are also needed in stage4 and stage5 ...
    del config["kubernetes"]["network"]
    for stage in [ANSIBLE_STAGES["stage4"], ANSIBLE_STAGES["stage5"]]:
        kubernetes_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "kubernetes.yaml"
        )
        dump_to_ansible_inventory(
            config.get("kubernetes"),
            kubernetes_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("kubernetes", "")
        )

    # ---
    # KUBERNETES SERVICE LAYER
    # ---
    # KUBERNETES SERVICE LAYER: ROOK
    print_process_state("KSL - ROOK")
    kubernetes_service_storage_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage4"] /
        "rook.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("rook"),
        kubernetes_service_storage_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("rook", "")
    )
    # KUBERNETES SERVICE LAYER: PROMETHEUS
    print_process_state("KSL - PROMETHEUS")
    #
    for stage in [ANSIBLE_STAGES["stage4"], ANSIBLE_STAGES["stage5"]]:
        kubernetes_service_monitoring_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "prometheus.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("prometheus"),
            kubernetes_service_monitoring_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("prometheus", "")
        )

    # ---
    # C&H KUBERNETES LBaaS
    # ---
    print_process_state("CH-k8s-LBaaS")
    ch_k8s_lbaas_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage3"] /
        "group_vars" / "all" / "ch-k8s-lbaas.yaml"
    )
    dump_to_ansible_inventory(
        config.get("ch-k8s-lbaas"),
        ch_k8s_lbaas_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("ch-k8s-lbaas", "")
    )

    # ---
    # MISCELLANEOUS
    # ---
    # Including both stage2 and stage3 because at least `journald_storage` is
    # used in both.
    print_process_state("Miscellaneous")
    for stage in [ANSIBLE_STAGES["stage2"], ANSIBLE_STAGES["stage3"]]:
        misc_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "miscellaneous.yaml"
        )
        dump_to_ansible_inventory(
            config.get("miscellaneous"),
            misc_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("miscellaneous", "")
        )

    # ---
    # NODE SCHEDULING
    # ---
    # Process labels and taints for each node
    print_process_state("Node Scheduling")
    node_scheduling_config = dict()
    node_scheduling_config["node_labels_and_taints"] = list()
    for node in list(
        set(
            list(
                config["node-scheduling"]["labels"].keys())
            + list(config["node-scheduling"]["taints"].keys()
                   )
        )
    ):
        node_specific_labels_taints = dict()
        node_specific_labels_taints["k8s_node"] = node
        node_specific_labels_taints["k8s_node_labels"] = \
            config["node-scheduling"]["labels"].get(node, [])
        node_specific_labels_taints["k8s_node_taints"] = \
            config["node-scheduling"]["taints"].get(node, [])
        node_scheduling_config["node_labels_and_taints"].append(
            node_specific_labels_taints
        )
    # Remove labels after they have been processed so that they
    # are not contained in the upper section anymore
    del config["node-scheduling"]["labels"]
    # Remove taints after they have been processed so that they
    # are not contained in the upper section anymore
    del config["node-scheduling"]["taints"]

    label_taint_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage4"] /
        "node-scheduling.yaml"
    )
    dump_to_ansible_inventory(
        {**config.get("node-scheduling"), **node_scheduling_config},
        label_taint_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("node-scheduling", "")
    )

    # ---
    # TESTING
    # ---
    print_process_state("Testing")
    test_node_map = {"test_worker_nodes": []}
    for node in config["testing"]["test-nodes"].keys():
        test_node_map["test_worker_nodes"].append({
            "worker": node,
            "name": config["testing"]["test-nodes"][node]
        })
    test_node_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage3"] /
        "group_vars" / "all" / "test-nodes.yaml"
    )
    dump_to_ansible_inventory(
        test_node_map,
        test_node_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("testing", "")
    )

    # ---
    # LOAD-BALANCING
    # ---
    print_process_state("Load-Balancing")
    # Process priorities
    for host in config.get("load-balancing", {}).get("priorities", {}).keys():
        print(
            "WARNING: ignoring deprecated host-based priority override for "
            "host {}".format(host)
        )

    # Remove priorities after they have been processed so that they
    # are not contained in the upper section anymore
    config.get("load-balancing", dict()).pop("priorities", dict())
    load_balancing_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage2"] /
        "group_vars" / "gateways" / "load-balancing.yaml"
    )
    dump_to_ansible_inventory(
        config.get("load-balancing", dict()),
        load_balancing_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("load-balancing", "")
    )

    # ---
    # CAH USERS
    # ---
    print_process_state("C&H-Users")
    for stage in [ANSIBLE_STAGES["stage2"], ANSIBLE_STAGES["stage3"]]:
        cah_users_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage / "group_vars" / "all" /
            "cah-users.yaml"
        )
        dump_to_ansible_inventory(
            config.get("cah-users", dict()),
            cah_users_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("cah-users", "")
        )

    # ---
    # KUBERNETES MANAGED SERVICES
    # ---
    # This layer is special as it requires only a subset of variables
    # from the previous layers. We are storing these variables into one file.
    print_process_state("Kubernetes: Managed Services")
    k8s_ms_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["stage5"] /
        "kms.yaml"
    )
    kms_config = dict()
    # I should probably describe what is happening here...
    for section, section_data in K8S_MANAGED_SERVICES_VAR_MAP.items():
        # (rook, monitoring) are part of "k8s-service-layer"
        if section == "k8s-service-layer" \
                and isinstance(section_data, dict):
            for service, service_data in section_data.items():
                if not isinstance(service_data, list):
                    raise ValueError("Expected a list of variable keys")
                for var_name in service_data:
                    if config.get(
                        section, {}).get(
                            service, {}).get(
                                var_name, ""):
                        if SECTION_VARIABLE_PREFIX_MAP.get(service, ""):
                            concrete_variable_key = \
                                SECTION_VARIABLE_PREFIX_MAP.get(service, "") \
                                + '_' + var_name
                        else:
                            concrete_variable_key = var_name
                        kms_config[concrete_variable_key] = \
                            config.get(section).get(service).get(var_name)
                    else:
                        continue
        elif not isinstance(section_data, list):
            raise ValueError("Expected a list of variable keys")
        else:
            for var_name in section_data:
                if config.get(section, {}).get(var_name, ""):
                    if SECTION_VARIABLE_PREFIX_MAP.get(section, ""):
                        concrete_variable_key = \
                            SECTION_VARIABLE_PREFIX_MAP.get(section, "") \
                            + '_' + var_name
                    else:
                        concrete_variable_key = var_name
                    kms_config[concrete_variable_key] = \
                        config.get(section).get(var_name)
                else:
                    continue
    dump_to_ansible_inventory(
        kms_config,
        k8s_ms_ansible_inventory_path,
        ""  # no prefix, we already applied them
    )

    print(
        "---\n"
        # "\N{sparkles} "
        "Inventory-Helper: "
        "Successfully processed the configuration\n"
        "---"
    )


if __name__ == "__main__":
    import sys
    sys.exit(main() or 0)

# Define map of prefixes