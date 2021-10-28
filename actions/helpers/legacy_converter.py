#!/usr/bin/python3

import typing    # needed for type hints
import toml      # needed to dump the new configuration
import pathlib   # needed for path handling
import shutil    # needed to copy the old config
import json      # needed for shiny feedback
import datetime  # needed for the backup suffix
# needed to merge default values into config
from mergedeep import merge, Strategy

# This mapping defines all the keys we expect to see, how they
# are called in the new configuration format, and to which section they
# are belonging. This is necessary, because the refactored inventory helper
# automatically attaches the prefix to the keys, depending on the section
# they belong to, when processing them.
KNOWN_SECTIONS_AND_KEYS_MAP = {
    "load-balancing": {
        "lb_ports": "lb_ports",
        "deprecated_nodeport_lb_test_port": "deprecated_nodeport_lb_test_port", # NOQA
    },
    "ch-k8s-lbaas": {
        "ch_k8s_lbaas": "enabled",
        "ch_k8s_lbaas_shared_secret": "shared_secret",
        "ch_k8s_lbaas_version": "version"
    },
    "kubernetes": {
        "k8s_version": "version",
        "is_gpu_cluster": "is_gpu_cluster",
        "k8s_use_podsecuritypolicies": "use_podsecuritypolicies"
    },
    "kubernetes-network": {
        "k8s_network_plugin": "plugin",
        "k8s_network_plugin_switch_restart_all_namespaces": "plugin_switch_restart_all_namespaces",  # NOQA
        "k8s_network_plugin_switch_restart_namespaces": "plugin_switch_restart_namespaces",  # NOQA
        "k8s_network_pod_subnet": "pod_subnet",
        "k8s_network_service_subnet": "service_subnet",
        "k8s_network_bgp_worker_as": "bgp_worker_as",
    },
    "rook": {
        "rook": "enabled",
        "rook_version": "version",
        "rook_nosds": "nosds",
        "rook_osd_volume_size": "osd_volume_size",
        "rook_toolbox": "toolbox",
        "rook_fs": "ceph_fs",
        "rook_fs_require_safe_replica_size": "ceph_fs_safe_replica_size",
        "rook_fs_replicated": "ceph_fs_replicated",
        "rook_mon_volume": "mon_volume",
        "rook_mon_volume_storage_class": "local-storage",
        "rook_pool_require_safe_replica_size": "pool_require_safe_replica_size",  # NOQA
        "rook_mon_memory_limit": "mon_memory_limit",
        "rook_mon_memory_request": "mon_memory_request",
        "rook_mon_cpu_request": "mon_cpu_request",
        "rook_mon_cpu_limit": "mon_cpu_limit",
        "rook_skip_upgrade_checks": "skip_upgrade_checks",
        "rook_osd_memory_limit": "osd_memory_limit",
        "rook_osd_memory_request": "osd_memory_request",
        "rook_osd_cpu_limit": "osd_cpu_limit",
        "rook_osd_cpu_request": "osd_cpu_request",
        "rook_osd_storage_class": "osd_storage_class",
        "rook_mgr_memory_limit": "mgr_memory_limit",
        "rook_mgr_memory_request": "mgr_memory_request",
        "rook_mgr_cpu_limit": "mgr_cpu_limit",
        "rook_mgr_cpu_request": "mgr_cpu_request",
        "rook_mds_memory_limit": "mds_memory_limit",
        "rook_mds_memory_request": "mds_memory_request",
        "rook_mds_cpu_limit": "mds_cpu_limit",
        "rook_mds_cpu_request": "mds_cpu_request",
        "rook_operator_cpu_limit": "operator_cpu_limit",
        "rook_operator_cpu_request": "operator_cpu_request",
        "rook_placement_taint": "placement_taint",
        "rook_placement_label": "placement_label",
        "rook_nodeplugin_toleration": "nodeplugin_toleration",
        "storage_nodeplugin_toleration": "storage_nodeplugin_toleration",
        "rook_pools": "pools",
    },
    "monitoring": {
        "monitoring": "enabled",
        "monitoring_use_thanos": "use_thanos",
        "monitoring_thanos_metadata_volume_size": "thanos_metadata_volume_size",  # NOQA
        "monitoring_thanos_metadata_volume_storage_class": "thanos_metadata_volume_storage_class",  # NOQA
        "monitoring_prometheus_monitor_all_namespaces": "prometheus_monitor_all_namespaces",  # NOQA
        "monitoring_alertmanager_memory_limit": "alertmanager_memory_limit",
        "monitoring_alertmanager_memory_request": "alertmanager_memory_request",  # NOQA
        "monitoring_alertmanager_cpu_limit": "alertmanager_cpu_limit",
        "monitoring_alertmanager_cpu_request": "alertmanager_cpu_request",
        "monitoring_alertmanager_config_secret": "alertmanager_config_secret",
        "monitoring_prometheus_memory_limit": "prometheus_memory_limit",
        "monitoring_prometheus_memory_request": "prometheus_memory_request",
        "monitoring_prometheus_cpu_limit": "prometheus_cpu_limit",
        "monitoring_prometheus_cpu_request": "prometheus_cpu_request",
        "monitoring_grafana_memory_limit": "grafana_memory_limit",
        "monitoring_grafana_memory_request": "grafana_memory_request",
        "monitoring_grafana_cpu_limit": "grafana_cpu_limit",
        "monitoring_grafana_cpu_request": "grafana_cpu_request",
        "monitoring_grafana_plugins": "grafana_plugins",
        "monitoring_kube_state_metrics_memory_limit": "kube_state_metrics_memory_limit",  # NOQA
        "monitoring_kube_state_metrics_memory_request": "kube_state_metrics_memory_request",  # NOQA
        "monitoring_kube_state_metrics_cpu_limit": "kube_state_metrics_cpu_limit",  # NOQA
        "monitoring_kube_state_metrics_cpu_request": "kube_state_metrics_cpu_request",  # NOQA
        "monitoring_thanos_sidecar_memory_limit": "thanos_sidecar_memory_limit",  # NOQA
        "monitoring_thanos_sidecar_memory_request": "thanos_sidecar_memory_request",  # NOQA
        "monitoring_thanos_sidecar_cpu_limit": "thanos_sidecar_cpu_limit",
        "monitoring_thanos_sidecar_cpu_request": "thanos_sidecar_cpu_request",
        "monitoring_thanos_query_memory_limit": "thanos_query_memory_limit",
        "monitoring_thanos_query_memory_request": "thanos_query_memory_request",  # NOQA
        "monitoring_thanos_query_cpu_limit": "thanos_query_cpu_limit",
        "monitoring_thanos_query_cpu_request": "thanos_query_cpu_request",
        "monitoring_thanos_store_memory_limit": "thanos_store_memory_limit",
        "monitoring_thanos_store_memory_request": "thanos_store_memory_request",  # NOQA
        "monitoring_thanos_store_cpu_limit": "thanos_store_cpu_limit",
        "monitoring_thanos_store_cpu_request": "thanos_store_cpu_request",
        "monitoring_thanos_compact_memory_limit": "thanos_compact_memory_limit", # NOQA
        "monitoring_thanos_compact_memory_request": "thanos_compact_memory_request",  # NOQA
        "monitoring_thanos_compact_cpu_limit": "thanos_compact_cpu_limit",
        "monitoring_thanos_compact_cpu_request": "thanos_compact_cpu_request",
        "monitoring_thanos_objectstorage_container_name": "thanos_objectstorage_container_name",  # NOQA
        "monitoring_placement_taint": "placement_taint",
        "monitoring_placement_label": "placement_label",
        "monitoring_internet_probe": "internet_probe",
        "monitoring_internet_probe_targets": "internet_probe_targets",
    },
    "wireguard": {
        "wg_ip_cidr": "ip_cidr",
        "wg_ip_gw": "ip_gw",
        "wg_s2s_enabled": "s2s_enabled",
        "wg_s2s_transfer_subnet": "s2s_transfer_subnet",
        "wg_s2s_ip": "s2s_ip",
        "wg_s2s_peer_ip": "s2s_peer_ip",
        "wg_s2s_port": "s2s_port",
        "wg_s2s_peer_pub_key": "s2s_peer_pub_key",
        "wg_s2s_peer_public_endpoint": "s2s_peer_public_endpoint",
        "wg_s2s_bgp_as": "s2s_bgp_as",
        "wg_s2s_peer_bgp_as": "s2s_peer_bgp_as"
    },
    "ipsec": {
        "ipsec_enabled": "enabled",
        "ipsec_proposals": "proposals",
        "ipsec_esp_proposals": "esp_proposals",
        "ipsec_peer_networks": "peer_networks",
        "ipsec_local_networks": "local_networks",
        "ipsec_virtual_subnet_pool": "virtual_subnet_pool",
        "ipsec_remote_addrs": "remote_addrs",
        "ipsec_eap_psk": "eap_psk",
        "ipsec_remote_name": "remote_name",
        "ipsec_purge_installation": "purge_installation",
    },
    "cah-users": {
        "cah_users_roll_out_users_from": "roll_out_users_from",
        "cah_users_exclude_users_from": "exclude_users_from",
        "cah_users_include_users": "include_users",
        "cah_users_exclude_users": "exclude_users"
    },
    "miscellaneous": {
        "wireguard_on_workers": "wireguard_on_workers",
        "openstack_network_name": "openstack_network_name",
        "nvidia_classic_driver_name": "nvidia_classic_driver_name",
        "journald_storage": "journald_storage",
    },
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


def confirm_prompt(question: str) -> bool:
    reply = None
    while reply not in ("y", "n"):
        reply = input(f"{question} (y/n): ").lower()
    return (reply == "y")


def _convert_legacy_config(
    legacy_config: typing.MutableMapping,
    config_path: pathlib.Path,
    config_template_path: pathlib.Path
) -> typing.MutableMapping:
    """
    Function to convert a configuration file from the old format to the
    newly introduced one. We are popping out / deleting every key-value
    pair after copying it to the new configuration format. This allows
    us to validate that we did not miss a variable in the end by checking
    if the old configuration is empty after we processed it. We have
    to treat host vars and lists specially.

    This function basically does:
    * Creating a backup of the current configuration
    * Extracting the "ansible" section of the old configuration
    * Copying the "secrets" section as "passwordstore" section
      * this section has not changed its format
    * Copying the "terraform" section
      * this section has not changed its format
    * Popping out the wireguard peers
    * Converting the vrrp priorities
      * They are directly assigned as "host var" in the old format.
        We have to handle them specially to convert them to the new format
    * Converting the "test nodes"
      * In the old format this information is stored as a list of dicts.
        In the new format its simply a dict. We have to treat it special
    * Converting the labels and taints
      * Also previously defined as host var
    * Iterating over the remaining "ansbile" section. For ech key found,
      mapping it to the new format. Keeping keys we cannot map
    * For ease of implementation we put everything in top level sections.
      Now we have to move around some sections to meet the new config format.
    * Validating that we were able to process each key of the old config
    * Dumping the configuration
    """

    ansible_config = legacy_config.get("ansible")

    new_config = dict()

    # Copy additional users from passwordstore section
    new_config["passwordstore"] = dict()
    new_config["passwordstore"]["additional_users"] = \
        legacy_config["secrets"].pop(
            "passwordstore_additional_users", dict()
    )
    new_config["passwordstore"]["rollout_company_users"] = legacy_config.get(
        "secrets").pop(
        "passwordstore_rollout_company_users", True
    )
    # Copy terraform section
    new_config["terraform"] = legacy_config.pop("terraform", dict())

    # Popping out wireguard peers
    new_config["wireguard"] = dict()
    new_config["wireguard"]["peers"] = \
        ansible_config["02_trampoline"]["group_vars"]["gateways"].pop(
        "wg_peers", list()
    )

    # Processing VRRP priorities
    new_config["load-balancing"] = dict()
    new_config["load-balancing"]["priorities"] = dict()
    # Maybe this nested loop is a bit overkill, but it's working...
    for stage, stage_cfg in ansible_config.items():
        for var_type, vars_cfg in stage_cfg.items():
            for entity, entity_cfg in vars_cfg.items():
                for key, value in list(entity_cfg.items()):
                    if key == "vrrp_priority":
                        new_config["load-balancing"]["priorities"][entity] = value  # NOQA
                        del ansible_config[stage][var_type][entity][key]

    # Processing test-nodes
    new_config["testing"] = dict()
    new_config["testing"]["test-nodes"] = dict()
    for test_node in list(ansible_config["03_final"]["group_vars"]["all"]["test_worker_nodes"]):  # NOQA
        node = test_node["worker"]
        name = test_node["name"]
        new_config["testing"]["test-nodes"][node] = name
    del ansible_config["03_final"]["group_vars"]["all"]["test_worker_nodes"]

    # Process labels and taints
    new_config["node-scheduling"] = dict()
    new_config["node-scheduling"]["labels"] = dict()
    new_config["node-scheduling"]["taints"] = dict()
    for node, node_cfg in list(ansible_config["03_final"]["host_vars"].items()):  # NOQA
        if "k8s_node_labels" in node_cfg.keys():
            if node not in new_config["node-scheduling"]["labels"].keys():
                new_config["node-scheduling"]["labels"][node] = list()
            for label in node_cfg.get("k8s_node_labels"):
                new_config["node-scheduling"]["labels"][node].append(label)  # NOQA
            del ansible_config["03_final"]["host_vars"][node]["k8s_node_labels"]  # NOQA
        if "k8s_node_taints" in node_cfg.keys():
            if node not in new_config["node-scheduling"]["taints"]:
                new_config["node-scheduling"]["taints"][node] = list()
            for taint in node_cfg.get("k8s_node_taints"):
                new_config["node-scheduling"]["taints"][node].append(taint)  # NOQA
            del ansible_config["03_final"]["host_vars"][node]["k8s_node_taints"]  # NOQA
    # Sadly we have to adjust the label/taint syntax after conversion to
    # meet the new playbook requirements
    for node, labels in new_config["node-scheduling"]["labels"].items():
        replaced_labels = []
        for label in labels:
            replaced_labels.append(label.replace("=", "/").replace(
                "{{ managed_k8s_control_plane_key }}", "node-restriction.kubernetes.io") + "=true")  # NOQA
        new_config["node-scheduling"]["labels"][node] = replaced_labels
    for node, taints in new_config["node-scheduling"]["taints"].items():
        replaced_taints = []
        for taint in taints:
            replaced_taints.append(taint.replace("=", "/").replace(
                ":", "=true:").replace(
                    "{{ managed_k8s_control_plane_key }}", "node-restriction.kubernetes.io")  # NOQA
                )
        new_config["node-scheduling"]["taints"][node] = replaced_taints

    # Iterate over the whole "ansible" section tree and compare the observed
    # keys based on our "known keys" map. Copy the variable if that's the case
    for stage, stage_cfg in list(ansible_config.items()):
        for var_type, vars_cfg in list(stage_cfg.items()):
            for entity, entity_cfg in list(vars_cfg.items()):
                for key, value in list(entity_cfg.items()):
                    for section, section_map in KNOWN_SECTIONS_AND_KEYS_MAP.items():  # NOQA
                        for oldkey, newkey in section_map.items():
                            if key == oldkey:
                                # GOT YA
                                if section not in new_config.keys():
                                    new_config[section] = dict()
                                new_config[section][newkey] = value
                                del ansible_config[stage][var_type][entity][key]  # NOQA

    # Moving around some sections to meet the new configuration format
    new_config["kubernetes"]["network"] = new_config.pop("kubernetes-network")
    new_config["k8s-service-layer"] = dict()

    # Rook
    new_config["k8s-service-layer"]["rook"] = new_config.pop("rook")
    new_config["kubernetes"]["storage"] = dict()
    new_config["kubernetes"]["storage"]["rook_enabled"] = new_config["k8s-service-layer"]["rook"].pop("enabled", False)  # NOQA
    new_config["kubernetes"]["storage"]["nodeplugin_toleration"] = \
        new_config["k8s-service-layer"]["rook"].pop(
            "storage_nodeplugin_toleration", False)
    # Convert label/taints to new structure (scheduling key)
    # Remove taint. Decided to use the label as ground truth to keep it simple
    new_config["k8s-service-layer"]["rook"].pop("placement_taint", "")
    # Check if a label is defined and if so use it
    # Otherwise we'll leave the scheduling_key empty.
    if new_config["k8s-service-layer"]["rook"].get("placement_label"):
        new_config["k8s-service-layer"]["rook"]["scheduling_key"] = \
            new_config["k8s-service-layer"]["rook"]["placement_label"].pop("key") \
            + "/" + new_config["k8s-service-layer"]["rook"]["placement_label"].pop("value")  # NOQA
        # replace managed_k8s_control_plane_key (if it is used)
        new_config["k8s-service-layer"]["rook"]["scheduling_key"] = \
            new_config["k8s-service-layer"]["rook"]["scheduling_key"].replace(  # NOQA
                "{{ managed_k8s_control_plane_key }}",
                "node-restriction.kubernetes.io"
        )
        del new_config["k8s-service-layer"]["rook"]["placement_label"]

    # Monitoring
    new_config["k8s-service-layer"]["prometheus"] = new_config.pop("monitoring")  # NOQA
    new_config["kubernetes"]["monitoring"] = dict()
    new_config["kubernetes"]["monitoring"]["enabled"] = new_config["k8s-service-layer"]["prometheus"].pop("enabled", True)  # NOQA
    # Convert label/taints to new structure (scheduling key)
    # Remove taint. Decided to use the label as ground truth to keep it simple
    new_config["k8s-service-layer"]["prometheus"].pop("placement_taint", "")
    # Check if a label is defined and if so use it
    # Otherwise we'll leave the scheduling_key empty.
    if new_config["k8s-service-layer"]["prometheus"].get("placement_label"):
        new_config["k8s-service-layer"]["prometheus"]["scheduling_key"] = \
            new_config["k8s-service-layer"]["prometheus"]["placement_label"].pop("key") \
            + "/" + new_config["k8s-service-layer"]["prometheus"]["placement_label"].pop("value")  # NOQA
        # replace managed_k8s_control_plane_key (if it is used)
        new_config["k8s-service-layer"]["prometheus"]["scheduling_key"] = \
            new_config["k8s-service-layer"]["prometheus"]["scheduling_key"].replace(  # NOQA
                "{{ managed_k8s_control_plane_key }}",
                "node-restriction.kubernetes.io"
        )
        del new_config["k8s-service-layer"]["prometheus"]["placement_label"]

    # Validate that we were able process each variable of the old config
    if prune(legacy_config):
        raise ValueError(
            "There are unknown keys in your configuration file. "
            "Please manually validate, adjust and retry. Unknown keys:\n"
            "{}".format(json.dumps(prune(ansible_config), indent=4, sort_keys=True))  # NOQA
        )

    # Join the values from the template
    with config_template_path.open("r") as fin:
        config_template = toml.load(fin)

    merged_config = merge(config_template, new_config,
                          strategy=Strategy.REPLACE)

    return merged_config


def convert_legacy_config(
    legacy_config: typing.MutableMapping,
    config_path: pathlib.Path,
    config_template_path: pathlib.Path
) -> typing.MutableMapping:

    # Create a backup of the config
    backup_path = config_path.with_suffix(
        F".{datetime.datetime.utcnow().isoformat()}.toml.old")
    shutil.copyfile(config_path, backup_path)
    print(
        # \"\N{floppy disk}"
        "Saved a backup of the old configuration "
        F"to {backup_path}"
    )

    merged_config = _convert_legacy_config(legacy_config,
                                           config_path,
                                           config_template_path)
    # Dump the new configuration
    with config_path.open("w") as fout:
        toml.dump(merged_config, fout)

    print(
        "---\n"
        # "\N{hospital} "
        "Inventory-Helper: "
        "Successfully converted your old-fashioned config. However, "
        "please do a manual verification.\n"
        # F"\N{floppy disk}"
        F"Saved the new configuration to '{config_path}'\n"
        "---"
    )

    while True:
        reply = confirm_prompt("Finished your manual verification?")
        if reply:
            return merged_config
        else:
            print("Take your time and come back when you feel safe...")


if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser()
    parser.add_argument("--config-file",
                        type=pathlib.Path,
                        default=pathlib.Path("config/config.toml"))
    args = parser.parse_args()
    config_path = args.config_file
    print(f"Working on {config_path}", file=sys.stderr)
    config_template_path = pathlib.Path("managed-k8s/templates/config.template.toml") # NOQA
    with open(config_path, "r") as f:
        legacy_config = toml.load(f)
    legacy_sections = ["ansible", "terraform", "secrets"]
    if not (set(legacy_config.keys()) == set(legacy_sections)):
        print("This doesn't look like a legacy config. FIN.", file=sys.stderr)
        sys.exit(1)
    print(_convert_legacy_config(legacy_config,
                                 config_path,
                                 config_template_path))
