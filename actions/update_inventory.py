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
CONFIG_TEMPLATE_PATH = pathlib.Path("managed-k8s/templates/config.template.toml")
# Root of the Ansible inventory
ANSIBLE_INVENTORY_ROOTPATH = pathlib.Path("inventory")
# Base path to the Ansible inventory. Files will get written here.
ANSIBLE_INVENTORY_BASEPATH = pathlib.Path("inventory/yaook-k8s/group_vars")
# List of top level sections which we do accept in the main config
ALLOWED_TOP_LEVEL_SECTIONS = (
    "k8s-service-layer",
    "wireguard",
    "etcd-backup",
)
# This maps defines the prefix that is assigned to each
# variable of a section
SECTION_VARIABLE_PREFIX_MAP = {
    "rook": "rook",
    "prometheus": "monitoring",
    "cert-manager": "k8s_cert_manager",
    "ingress": "k8s_ingress",
    "fluxcd": "fluxcd",
    "etcd-backup": "etcd_backup",
    "vault": "yaook_vault",
}


def prune(dictionary: typing.MutableMapping) -> typing.MutableMapping:
    """
    # Strip down a dictionary. This function removes all empty "branches"
    # of a "dictionary tree", but keeps branches containing information
    """
    new_dictionary = {}
    for key, value in dictionary.items():
        if isinstance(value, dict):
            value = prune(value)
        if value not in ("", None, {}):
            new_dictionary[key] = value
    return new_dictionary


def cleanup_ansible_inventory(
    ansible_inventory_path: pathlib.Path = ANSIBLE_INVENTORY_ROOTPATH,
):
    """
    Cleaning up the inventory. Excluding directories and files we need to keep
    because they are generated by a third party.
    """
    exclude_file_prefixes = ["terraform_"]
    exclude_files = ["hosts"]
    exclude_dirs = []

    # We need to traverse from the root to the leaves so that we can ignore
    # directories and their subdirectories. However, this makes removing empty
    # folders more complicated. Therefore, for the cleanup of empty
    # directories, we simply walk again over the directory tree starting from
    # the bottom.
    for dirpath, dirnames, filenames in os.walk(ansible_inventory_path, topdown=True):
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
    for dirpath, dirnames, filenames in os.walk(ansible_inventory_path, topdown=False):
        # check if the folder is empty and delete it if so
        try:
            os.rmdir(dirpath)
        except OSError as exc:
            if exc.errno != errno.ENOTEMPTY:
                raise


def cleanup_obsolete_config(config_path: pathlib.Path = CONFIG_BASE_PATH):
    deprecated_files = ["pass_users.toml"]

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


def apply_prefix(config: typing.Mapping, key_prefix: str) -> typing.MutableMapping:
    final_config = {}
    for key, value in config.items():
        new_key = f"{key_prefix}_{key}"
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
    ansible_inventory_path.parent.mkdir(exist_ok=True, mode=0o750, parents=True)

    # Dump the variables as YAML
    with ansible_inventory_path.open("w") as fout:
        yaml.safe_dump(config, fout)


def dump_to_ansible_inventory(
    config: typing.MutableMapping,
    ansible_inventory_path: pathlib.Path,
    key_prefix: str,
    unflat_keys: typing.List[str] = [],
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


def print_process_state(section: str):
    # Put into a function because it is used several times
    print(
        # "\N{gear} "
        "Section in process: "
        f"{section}"
    )


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
                unallowed_keys, ALLOWED_TOP_LEVEL_SECTIONS
            )
        )

    config = merge({}, config_template, config)

    # Config looks good on first sight, be brave and cleanup the inventory
    print(
        # "\N{broom} "
        "Cleaning up the inventory..."
    )
    cleanup_ansible_inventory()
    print("Cleaning up deprecated config files...")
    cleanup_obsolete_config()

    # START PROCESSING THE TOP SECTIONS
    # ---
    # TERRAFORM
    # ---
    if os.getenv("TF_USAGE", "true") == "true":
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
        tf_config["monitoring_manage_thanos_bucket"] = (
            use_thanos and manage_thanos_bucket
        )

        if "gitlab_backend" in tf_config and tf_config["gitlab_backend"] is True:
            for var in ("TF_HTTP_USERNAME", "TF_HTTP_PASSWORD"):
                if var not in os.environ:
                    raise ValueError(f"gitlab_backend is true, but {var} unset")

            for var in ("gitlab_base_url", "gitlab_project_id", "gitlab_state_name"):
                if var not in tf_config:
                    raise ValueError(f"gitlab_backend is true, but {var} unset")

            if not re.match(r"https?:\/\/.*[^\/]$", tf_config["gitlab_base_url"]):
                raise ValueError("Provided gitlab_base_url is misformed.")

        terraform_helper.deploy_terraform_config(tf_config)

        # Pass the cluster name to inventory
        tf_ansible_inventory_path = ANSIBLE_INVENTORY_BASEPATH / "all" / "cluster.yaml"
        dump_to_ansible_inventory(
            {"cluster_name": tf_config.get("cluster_name", "managed-k8s")},
            tf_ansible_inventory_path,
            "",
        )

    # ---
    # WIREGUARD
    # ---
    # only if wireguard is desired
    if os.getenv("WG_USAGE", "true") == "true":
        print_process_state("Wireguard")
        ip_networks = []
        tf_ipv4_string = None
        tf_ipv6_string = None

        # Getting IPv4 cluster network
        if os.getenv("wg_user") == "gitlab-ci-runner":  # if in gitlab ci
            tf_ipv4_string = os.getenv("TF_VAR_subnet_cidr")
        elif "subnet_cidr" in tf_config:
            tf_ipv4_string = tf_config["subnet_cidr"]
        else:
            tf_ipv4_string = terraform_helper.get_default_value_in_tf_vars(
                "subnet_cidr"
            )

        if tf_ipv4_string:
            ip_networks.append(tf_ipv4_string)
        else:
            raise ValueError("No `subnet_cidr` for ipv4 cluster network found")

        # Getting IPv6 cluster network
        if (
            "dualstack_support" in tf_config
            and tf_config["dualstack_support"] == "true"
        ):
            if "subnet_v6_cidr" in tf_config:
                tf_ipv6_string = tf_config["subnet_v6_cidr"]
            else:
                tf_ipv6_string = terraform_helper.get_default_value_in_tf_vars(
                    "subnet_v6_cidr"
                )

            if tf_ipv6_string:
                ip_networks.append(tf_ipv6_string)
            else:
                raise ValueError("No `subnet_v6_cidr` for ipv6 cluster network found")

        # Proofing whether cluster networks are in conflict with wg networks
        for ip_network in ip_networks:
            if not wireguard_helper.is_ipnet_disjoint(
                ip_network, config.get("wireguard")
            ):
                raise ValueError(
                    f"The network `{tf_ipv4_string}` is in conflict "
                    "with one of the wireguard networks."
                )

        wg_ansible_inventory_path = (
            ANSIBLE_INVENTORY_BASEPATH / "gateways" / "wireguard.yaml"
        )
        dump_to_ansible_inventory(
            wireguard_helper.generate_wireguard_config(config.get("wireguard")),
            wg_ansible_inventory_path,
            SECTION_VARIABLE_PREFIX_MAP.get("wireguard", ""),
        )

    # ---
    # ROOK
    # ---
    print_process_state("ROOK")
    kubernetes_service_storage_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "rook.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("rook"),
        kubernetes_service_storage_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("rook", ""),
    )

    # ---
    # PROMETHEUS
    # ---
    print_process_state("PROMETHEUS")
    kubernetes_service_monitoring_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "prometheus.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("prometheus"),
        kubernetes_service_monitoring_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("prometheus", ""),
        ["common_labels"],
    )

    # ---
    # CERT MANAGER
    # ---
    print_process_state("CERT MANAGER")
    kubernetes_service_cm_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "cert-manager.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("cert-manager"),
        kubernetes_service_cm_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("cert-manager", ""),
    )

    # ---
    # INGRESS
    # ---
    print_process_state("INGRESS")
    kubernetes_service_ingress_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "ingress.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("ingress"),
        kubernetes_service_ingress_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("ingress", ""),
    )

    # ---
    # VAULT
    # ---
    print_process_state("VAULT SERVICE")
    kubernetes_service_vault_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "vault-svc.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("vault"),
        kubernetes_service_vault_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("vault", ""),
    )

    # ---
    # ETCD-BACKUP
    # ---
    print_process_state("ETCD-BACKUP")
    kubernetes_service_storage_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "etcd-backup.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("etcd-backup"),
        kubernetes_service_storage_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("etcd-backup", ""),
    )

    # ---
    # FLUXCD
    # ---
    print_process_state("FLUXCD")
    kubernetes_service_storage_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "fluxcd.yaml"
    )
    dump_to_ansible_inventory(
        config["k8s-service-layer"].get("fluxcd"),
        kubernetes_service_storage_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("fluxcd", ""),
    )

    # ---
    # MISCELLANEOUS
    # ---
    print_process_state("Miscellaneous")
    misc_ansible_inventory_path = (
        ANSIBLE_INVENTORY_BASEPATH / "all" / "miscellaneous.yaml"
    )
    # the toml package is unable to parse the 'container_mirrors' list
    # properly and passes a class to the yaml.safe_dump function, which
    # fails. That is why we need to unpack the whole list with it's
    # embedded dict and rebuild it.
    new_misc_dict = {}
    for key, value in config.get("miscellaneous").items():
        if isinstance(value, list) and key == "container_mirrors":
            new_misc_dict[key] = [dict(val.items()) for val in value]
        else:
            new_misc_dict[key] = value
    dump_to_ansible_inventory(
        new_misc_dict,
        misc_ansible_inventory_path,
        SECTION_VARIABLE_PREFIX_MAP.get("miscellaneous", ""),
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
