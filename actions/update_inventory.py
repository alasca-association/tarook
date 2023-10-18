#!/usr/bin/env python3

import pathlib
import toml
import yaml
import os
import collections
import typing
import errno
import re
from mergedeep import merge

from helpers import terraform_helper
from helpers import wireguard_helper

CONFIG_BASE_PATH = pathlib.Path("config")
# Path to the main configuration
CONFIG_PATH = pathlib.Path(CONFIG_BASE_PATH / "config.toml")
# Path to the configuration template
CONFIG_TEMPLATE_PATH = pathlib.Path(
    "managed-k8s/templates/config.template.toml")
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
    "terraform",
    "wireguard",
    "ipsec",
    "cah-users",
    "etcd-backup",
    "custom",
    "vault",
    "miscellaneous",
    "nvidia",
)
# Mapping stages to their common names
ANSIBLE_STAGES = {
    "install-node": "00_install_node",
    "yaook-k8s": "yaook-k8s",
    "custom": "k8s-custom",
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
        ],
        "fluxcd": [
        ]
    },
}
# This maps defines the prefix that is assigned to each
# variable of a section
SECTION_VARIABLE_PREFIX_MAP = {
    "ch-k8s-lbaas": "ch_k8s_lbaas",
    "kubernetes": "k8s",
    "wireguard": "wg",
    "ipsec": "ipsec",
    "cah-users": "cah_users",
    "rook": "rook",
    "prometheus": "monitoring",
    "cert-manager": "k8s_cert_manager",
    "ingress": "k8s_ingress",
    "fluxcd": "fluxcd",
    "etcd-backup": "etcd_backup",
    "vault": "yaook_vault",
    "nvidia": "nvidia",
    "vault_backend": "vault",
    "testing": "testing",
}


def prune(
    dictionary: typing.MutableMapping
) -> typing.MutableMapping:
    """
    # Strip down a dictionary. This function removes all empty "branches"
    # of a "dictionary tree", but keeps branches containing information
    """
    new_dictionary = {}
    for key, value in dictionary.items():
        if isinstance(value, dict):
            value = prune(value)
        if value not in (u'', None, {}):
            new_dictionary[key] = value
    return new_dictionary


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
    exclude_dirs = []

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


def cleanup_obsolete_config(
    config_path: pathlib.Path = CONFIG_BASE_PATH
):
    deprecated_files = [
        "pass_users.toml"
    ]

    for deprecated_file in deprecated_files:
        full_path = pathlib.PurePath(config_path / deprecated_file)
        try:
            os.remove(full_path)
        except FileNotFoundError:
            pass


def flatten_config(
    config: typing.MutableMapping,
    unflat_keys: typing.List[str],
    parent_key: str = "",
    sep: str = "_",
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
        if key in unflat_keys:
            items.update({key: value})
            continue
        new_key = (parent_key + sep + key) if parent_key else key
        if isinstance(value, collections.abc.MutableMapping):
            items.update(flatten_config(value, unflat_keys, new_key, sep=sep).items())
        else:
            items.update({new_key: value})
    return dict(items)


def apply_prefix(
    config: typing.Mapping,
    key_prefix: str
) -> typing.MutableMapping:
    final_config = {}
    for key, value in config.items():
        new_key = F'{key_prefix}_{key}'
        final_config[new_key] = value
    return final_config


def write_to_inventory(
    config: typing.Mapping,
    ansible_inventory_path: pathlib.Path,
):
    # Ensure config is not empty
    if not config:
        return

    # Ensure the respective inventory directory is existing
    ansible_inventory_path.parent.mkdir(exist_ok=True, mode=0o750,
                                        parents=True)

    # Dump the variables as YAML
    with ansible_inventory_path.open("w") as fout:
        yaml.safe_dump(config, fout)


def dump_to_ansible_inventory(
    config: typing.MutableMapping,
    ansible_inventory_path: pathlib.Path,
    key_prefix: str,
    unflat_keys: typing.List[str] = []
):
    # Ensure config is not empty
    if not config:
        return

    # Flatten the config
    final_config = flatten_config(config, unflat_keys)

    # Apply key prefix
    if key_prefix:
        final_config = apply_prefix(final_config, key_prefix)

    # Dump the variables as YAML
    write_to_inventory(final_config, ansible_inventory_path)


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

    # Load the template config.template.toml
    with CONFIG_TEMPLATE_PATH.open("r") as fin:
        config_template = toml.load(fin)

    # Check that the config contains only valid top sections
    unallowed_keys = set(config.keys()) - set(ALLOWED_TOP_LEVEL_SECTIONS)
    if unallowed_keys:
        raise ValueError(
            "{} are unknown sections. Currently supported are {}".format(
                unallowed_keys,
                ALLOWED_TOP_LEVEL_SECTIONS)
        )

    config = merge(config_template, config)

    # Config looks good on first sight, be brave and cleanup the inventory
    print(
        # "\N{broom} "
        "Cleaning up the inventory...")
    cleanup_ansible_inventory()
    print("Cleaning up deprecated config files...")
    cleanup_obsolete_config()

    # START PROCESSING THE TOP SECTIONS
    # ---
    # TERRAFORM
    # ---
    if (os.getenv('TF_USAGE', 'true') == 'true'):
        print_process_state("Terraform")
        tf_config = config.get("terraform")
        # If we want to use thanos, then the user can decide if terraform should create
        # an object storage container. These variables are set in an upper stage
        # and cannot be made available easily to tf except for making the user
        # provide an additional variable. Therefore we're picking them here and
        # insert them ourselves.
        prom_config = config["k8s-service-layer"].get("prometheus")
        use_thanos = prom_config.get("use_thanos", False)
        manage_thanos_bucket = prom_config.get("manage_thanos_bucket", True)
        conf_file = prom_config.get("thanos_objectstorage_config_file", False)
        if use_thanos and not (manage_thanos_bucket or conf_file):
            raise ValueError(
                "You enabled thanos (`use_thanos=true`) and you told terraform to not"
                "create a bucket for you (`manage_thanos_bucket=false`)\n"
                "but you didn't provide a config file to an external bucket"
                "(`thanos_objectstorage_config_file=''`) either.\n"
                "Where is thanos supposed to write its metrics to? ;-(\n"
            )
        tf_config["monitoring_manage_thanos_bucket"] = use_thanos and \
            manage_thanos_bucket

        if 'gitlab_backend' in tf_config and tf_config['gitlab_backend'] is True:
            for var in ('TF_HTTP_USERNAME', 'TF_HTTP_PASSWORD'):
                if var not in os.environ:
                    raise ValueError(f"gitlab_backend is true, but {var} unset")

            for var in ('gitlab_base_url', 'gitlab_project_id', 'gitlab_state_name'):
                if var not in tf_config:
                    raise ValueError(f"gitlab_backend is true, but {var} unset")

            if not re.match(r"https?:\/\/.*[^\/]$", tf_config['gitlab_base_url']):
                raise ValueError("Provided gitlab_base_url is misformed.")

        terraform_helper.deploy_terraform_config(tf_config)
        # Pass the cluster name to inventory
        for stage in ["yaook-k8s"]:
            tf_ansible_inventory_path = (
                ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES[stage] /
                "group_vars" / "all" / "cluster.yaml"
            )
            dump_to_ansible_inventory(
                {'cluster_name': tf_config.get("cluster_name", "managed-k8s")},
                tf_ansible_inventory_path,
                ""
            )

    # ---
    # VAULT
    # ---
    print_process_state("Vault Backend")
    for stage in ["yaook-k8s"]:
        vault_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES[stage] /
            "group_vars" / "all" / "vault-backend.yaml"
        )
        dump_to_ansible_inventory(
            config["vault"],
            vault_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("vault_backend", "")
        )

    # ---
    # WIREGUARD
    # ---
    # only if wireguard is desired
    if (os.getenv('WG_USAGE', 'true') == 'true'):
        print_process_state("Wireguard")
        wg_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
            "group_vars" / "gateways" / "wireguard.yaml"
        )
        dump_to_ansible_inventory(
            wireguard_helper.generate_wireguard_config(
                config.get("wireguard")),
            wg_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("wireguard", "")
        )

    # ---
    # IPSEC
    # ---
    print_process_state("IPSec")
    ipsec_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
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
    for stage in ["yaook-k8s"]:
        kubernetes_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "kubernetes.yaml"
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
    print_process_state("ROOK")
    for stage in ["yaook-k8s"]:
        kubernetes_service_storage_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "rook.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("rook"),
            kubernetes_service_storage_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("rook", "")
        )

    # KUBERNETES SERVICE LAYER: PROMETHEUS
    print_process_state("PROMETHEUS")
    for stage in ["yaook-k8s"]:
        kubernetes_service_monitoring_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "prometheus.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("prometheus"),
            kubernetes_service_monitoring_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("prometheus", ""),
            ["common_labels"]
        )

    # ---
    # KUBERNETES SERVICE LAYER
    # ---
    # KUBERNETES SERVICE LAYER: CERT MANAGER
    print_process_state("CERT MANAGER")
    for stage in ["yaook-k8s"]:
        kubernetes_service_cm_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "cert-manager.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("cert-manager"),
            kubernetes_service_cm_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("cert-manager", "")
        )

    # KUBERNETES SERVICE LAYER: INGRESS
    print_process_state("INGRESS")
    for stage in ["yaook-k8s"]:
        kubernetes_service_ingress_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "ingress.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("ingress"),
            kubernetes_service_ingress_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("ingress", "")
        )

    # KUBERNETES SERVICE LAYER: VAULT
    print_process_state("VAULT SERVICE")
    for stage in ["yaook-k8s"]:
        kubernetes_service_vault_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "vault-svc.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("vault"),
            kubernetes_service_vault_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("vault", "")
        )

    # KUBERNETES SERVICE LAYER: ETCD-BACKUP
    print_process_state("KSL - ETCD-BACKUP")
    for stage in ["yaook-k8s"]:
        kubernetes_service_storage_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "etcd-backup.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("etcd-backup"),
            kubernetes_service_storage_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("etcd-backup", "")
        )

    # KUBERNETES SERVICE LAYER: FLUXCD
    print_process_state("KSL - FLUXCD")
    for stage in ["yaook-k8s"]:
        kubernetes_service_storage_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "fluxcd.yaml"
        )
        dump_to_ansible_inventory(
            config["k8s-service-layer"].get("fluxcd"),
            kubernetes_service_storage_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("fluxcd", "")
        )

    # ---
    # C&H KUBERNETES LBaaS
    # ---
    print_process_state("CH-k8s-LBaaS")
    ch_k8s_lbaas_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
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

    misc_stages = [ANSIBLE_STAGES["yaook-k8s"]]
    if os.getenv('K8S_INSTALL_NODE_USAGE', 'false') == 'true':
        misc_stages.append(ANSIBLE_STAGES["install-node"])

    for stage in misc_stages:
        misc_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "miscellaneous.yaml"
        )

        # the toml package is unable to parse the 'container_mirrors' list
        # properly and passes a class to the yaml.safe_dump function, which
        # fails. That is why we need to unpack the whole list with it's
        # embedded dict and rebuild it.
        new_misc_dict = {}
        for key, value in config.get("miscellaneous").items():
            if isinstance(value, list) and key == 'container_mirrors':
                new_misc_dict[key] = [dict(val.items()) for val in value]
            else:
                new_misc_dict[key] = value

        dump_to_ansible_inventory(
            new_misc_dict,
            misc_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("miscellaneous", "")
        )

    # ---
    # NVIDIA VGPU
    # ---
    print_process_state("NVIDIA - vGPU")
    nvidia_vgpu_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
            "group_vars" / "all" / "nvidia.yaml"
    )
    dump_to_ansible_inventory(
        config.get("nvidia"),
        nvidia_vgpu_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("nvidia", "")
    )

    # ---
    # NODE SCHEDULING
    # ---
    # Process labels and taints for each node
    print_process_state("Node Scheduling")
    node_scheduling_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
        "group_vars" / "all" / "node-scheduling.yaml"
    )
    node_scheduling_config = {
        # We use pop here to only apply the prefix to labels + taints
        "k8s_node_labels": config.get("node-scheduling", {}).pop("labels", {}),
        "k8s_node_taints": config.get("node-scheduling", {}).pop("taints", {}),
    }
    node_scheduling_config.update(config.get("node-scheduling", {}))
    write_to_inventory(
        node_scheduling_config,
        node_scheduling_inventory_path,
    )

    # ---
    # TESTING
    # ---
    print_process_state("Testing")
    test_node_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
        "group_vars" / "all" / "test-nodes.yaml"
    )
    dump_to_ansible_inventory(
        config.get("testing", dict()),
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
    for stage in ["yaook-k8s"]:
        load_balancing_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "load-balancing"
        )
        dump_to_ansible_inventory(
            config.get("load-balancing", dict()),
            load_balancing_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("load-balancing", "")
        )

    # ---
    # CAH USERS
    # ---
    print_process_state("C&H-Users")
    for stage in ["yaook-k8s"]:
        cah_users_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "cah-users.yaml"
        )
        dump_to_ansible_inventory(
            config.get("cah-users", dict()),
            cah_users_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("cah-users", "")
        )

    # ---
    # CUSTOM
    # ---
    # only if custom stage is used
    if (os.getenv('K8S_CUSTOM_STAGE_USAGE', 'false') == 'true'):
        print_process_state("CUSTOM")
        stage = ANSIBLE_STAGES["custom"]
        custom_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / stage /
            "group_vars" / "all" / "custom.yaml"
        )
        dump_to_ansible_inventory(
            config.get("custom", dict()),
            custom_ansible_inventory_path,
            ""  # don't append prefix, we don't use vars from other sections
        )

    # ---
    # KUBERNETES MANAGED SERVICES
    # ---
    # This layer is special as it requires only a subset of variables
    # from the previous layers. We are storing these variables into one file.
    print_process_state("Kubernetes: Managed Services")
    k8s_ms_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / ANSIBLE_STAGES["yaook-k8s"] /
        "group_vars" / "all" / "kms.yaml"
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
