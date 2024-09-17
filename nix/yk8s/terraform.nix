{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.terraform;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModuleWithNewSection;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) filterAttrs recursiveUpdate;
  inherit (lib.trivial) pipe;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption linkToPath;
  inherit (yk8s-lib.types) ipv4Cidr;
  inherit (yk8s-lib.transform) filterNull removeObsoleteOptions filterInternal;
  inherit (builtins) fromJSON readFile pathExists length;
in {
  imports = [
    (mkRemovedOptionModule "terraform" "haproxy_ports" "")
    (mkRenamedOptionModuleWithNewSection "terraform" "subnet_cidr" "infra" "subnet_cidr")
    (mkRenamedOptionModuleWithNewSection "terraform" "subnet_v6_cidr" "infra" "subnet_v6_cidr")
    (mkRenamedOptionModuleWithNewSection "terraform" "ipv4_enabled" "infra" "ipv4_enabled")
    (mkRenamedOptionModuleWithNewSection "terraform" "ipv6_enabled" "infra" "ipv6_enabled")
    (mkRenamedOptionModuleWithNewSection "terraform" "cluster_name" "openstack" "cluster_name")
    (mkRenamedOptionModuleWithNewSection "terraform" "public_network" "openstack" "public_network")
    (mkRenamedOptionModuleWithNewSection "terraform" "keypair" "openstack" "keypair")
    (mkRenamedOptionModuleWithNewSection "terraform" "azs" "openstack" "azs")
    (mkRenamedOptionModuleWithNewSection "terraform" "thanos_delete_container" "openstack" "thanos_delete_container")
    (mkRenamedOptionModuleWithNewSection "terraform" "spread_gateways_across_azs" "openstack" "spread_gateways_across_azs")
    (mkRenamedOptionModuleWithNewSection "terraform" "create_root_disk_on_volume" "openstack" "create_root_disk_on_volume")
    (mkRenamedOptionModuleWithNewSection "terraform" "timeout_time" "openstack" "timeout_time")
    (mkRenamedOptionModuleWithNewSection "terraform" "network_mtu" "openstack" "network_mtu")
    (mkRenamedOptionModuleWithNewSection "terraform" "dns_nameservers_v4" "openstack" "dns_nameservers_v4")
    (mkRenamedOptionModuleWithNewSection "terraform" "monitoring_manage_thanos_bucket" "openstack" "monitoring_manage_thanos_bucket")
    (mkRenamedOptionModuleWithNewSection "terraform" "gateway_count" "openstack" "gateway_count")
    (mkRenamedOptionModuleWithNewSection "terraform" "gateway_defaults" "openstack" "gateway_defaults")
    (mkRenamedOptionModuleWithNewSection "terraform" "master_defaults" "openstack" "master_defaults")
    (mkRenamedOptionModuleWithNewSection "terraform" "worker_defaults" "openstack" "worker_defaults")
    (mkRenamedOptionModuleWithNewSection "terraform" "nodes" "openstack" "nodes")
  ];

  options.yk8s.terraform = mkTopSection {
    enabled = mkOption {
      type = types.bool;
      default = true;
    };

    prevent_disruption = mkOption {
      description = ''
        If true, prevent Terraform from performing disruptive action
        defaults to true if unset
      '';
      type = types.bool;
      default = true;
    };

    gitlab_backend = mkEnableOption ''
      GitLab-managed Terraform backend
      If true, the Terraform state will be stored inside the provided gitlab project.
      If set, the environment `TF_HTTP_USERNAME` and `TF_HTTP_PASSWO = mkOptionD`
      must be configured in a separate file `~/.config/yaook-k8s/env`.
    '';

    gitlab_base_url = mkOption {
      description = ''
        The base URL of your GitLab project.
      '';
      type = with types; nullOr str;
      default = null;
      example = "https://gitlab.com";
    };

    gitlab_project_id = mkOption {
      description = ''
        The unique ID of your GitLab project.
      '';
      type = with types; nullOr str;
      default = null;
      apply = v:
        if
          cfg.gitlab_backend
          && v == null
        then
          throw
          "terraform.gitlab_backend is enabled but gitlab_project_id is unset"
        else v;
    };

    gitlab_state_name = mkOption {
      description = ''
        The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'      '';
      type = with types; nullOr str;
      default = null;
      example = "tf-state";
    };
  };
  config.yk8s = lib.mkIf cfg.enabled {
    _inventory_packages = [
      (mkGroupVarsFile {
        cfg = lib.attrsets.getAttrs ["enabled" "prevent_disruption"] cfg;
        inventory_path = "all/terraform.yaml";
      })
    ];
  };
}
