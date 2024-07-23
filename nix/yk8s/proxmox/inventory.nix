{
  cfg,
  lib,
}: let
  inherit (lib.strings) concatLines;
  inherit (lib.attrsets) mapAttrsToList filterAttrs;
in
  ''
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    on_openstack=False
    # ansible_ssh_common_args="-J dd5.mk8s-installvm"

    [orchestrator]
    localhost ansible_connection=local ansible_python_interpreter="{{ ansible_playbook_python }}"

    [frontend:children]
    gateways

    [k8s_nodes:children]
    masters
    workers

    [gateways]
  ''
  + concatLines (mapAttrsToList (
      n: v: "${n} ansible_host=${v.external_ipv4_address} local_ipv4_address=${v.ipv4_address} public_ipv4_address=${v.external_ipv4_address}"
    )
    (filterAttrs (_: v: v.role == "gateway") cfg.nodes))
  + ''

    [masters]
  ''
  + concatLines (mapAttrsToList (n: v: "${n} ansible_host=${v.ipv4_address} local_ipv4_address=${v.ipv4_address}")
    (filterAttrs (_: v: v.role == "master") cfg.nodes))
  + ''

    [workers]
  ''
  + concatLines (mapAttrsToList (n: v: "${n} ansible_host=${v.ipv4_address} local_ipv4_address=${v.ipv4_address}")
    (filterAttrs (_: v: v.role == "worker") cfg.nodes))
