{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.terraform;
  removed-lib = import ./lib/removed.nix {inherit lib;};
  inherit (removed-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) filterAttrs;
  inherit (lib.trivial) pipe;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption;
  inherit (yk8s-lib.types) ipv4Cidr ipv6Cidr;
  inherit (yk8s-lib.transform) filterNull removeObsoleteOptions filterInternal;
  inherit (builtins) fromJSON readFile pathExists;
  tfvars_file_path = "terraform/config.tfvars.json";
  checkClusterName = v: let
    current_config_file = "${config.yk8s.cluster_repository}/${tfvars_file_path}";
    current_config = fromJSON (readFile current_config_file);
    cluster_exists = pathExists current_config_file;
  in
    if
      cluster_exists
      && ! current_config ? cluster_name
      && v != null
    then
      # hard-coding this value here as it is the default at the time of writing this module. This ensures that
      # even if we change the default value, old clusters that have been set up with an empty value (and hence
      # have been using the current default) will migrate to explicitely using it
      "managed-k8s"
    else if
      cluster_exists
      && current_config ? cluster_name
      && current_config.cluster_name != v
    then
      throw ''
        Will not update terraform config because there is a mismatch between the deployed and future cluster_name. This would cause death and destruction.
        Set `terraform.cluster_name` back to ${current_config.cluster_name}. Your suggested change ${v} is unacceptable.
      ''
    else v;
in {
  imports = [
    (mkRemovedOptionModule "terraform" "haproxy_ports" "")
  ];

  options.yk8s.terraform = mkTopSection {
    enabled = mkOption {
      type = types.bool;
      default = true;
    };

    cluster_name = mkOption {
      type = types.str;
      default = "managed-k8s";
      apply = checkClusterName;
    };

    prevent_disruption = mkOption {
      description = ''
        If true, prevent Terraform from performing disruptive action
        defaults to true if unset
      '';
      type = types.bool;
      default = true;
    };

    subnet_cidr = mkOption {
      type = ipv4Cidr;
      default = "172.30.154.0/24";
    };

    subnet_v6_cidr = mkOption {
      description = ''
        If you enabled DualStack-support you may want to adjust the IPv6 subnet
      '';
      type = types.nullOr ipv6Cidr;
      default = null;
      apply = v:
        if cfg.dualstack_support && v == null
        then
          throw
          "terraform.ipv6cidr must be set if dualstack_support is enabled"
        else v;
    };

    dualstack_support = mkEnableOption ''
      Enable DualStack support
      If set to true, dualstack support related resources will be (re-)created
      WARNING: DualStack support is not stable yet, see https://gitlab.com/yaook/k8s/-/issues/502
    '';

    public_network = mkOption {
      type = types.str;
      default = "shared-public-IPv4"; # TODO remove in !1326
    };

    keypair = mkOption {
      description = ''
        Will most of the time be set via the environment variable TF_VAR_keypair
      '';
      type = with types; nullOr str;
      default = null;
    };

    default_master_image_name = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    default_worker_image_name = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    gateway_image_name = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    gateway_flavor = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    default_master_flavor = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    default_worker_flavor = mkOption {
      type = with types; nullOr str;
      default = null;
    };

    azs = mkOption {
      description = ''
        If 'enable_az_management=true' defines which availability zones of your cloud to use to distribute the spawned server for better HA. Additionally the count of the array will define how many gateway server will be spawned. The naming of the elements doesn't matter if 'enable_az_management=false'. It is also used for unique naming of gateways.
      '';
      default = null;
      type = with types; nullOr (listOf str);
      apply = v:
        if cfg.enable_az_management && v == []
        then
          throw
          "terraform.enable_az_management is true but azs is empty"
        else v;
    };

    masters = mkOption {
      type = types.int;
      default = 3;
    };

    workers = mkOption {
      type = types.int;
      default = 4;
    };

    worker_flavors = mkOption {
      type = with types; listOf str;
      default = [];
      apply = v:
        if v == [] && cfg.default_worker_flavor == null
        then throw "terraform.worker_flavors cannot be empty if terraform.default_worker_flavor is not set"
        else v;
    };

    worker_images = mkOption {
      type = with types; listOf str;
      default = [];
      apply = v:
        if v == [] && cfg.default_worker_image_name == null
        then throw "terraform.worker_images cannot be empty if terraform.default_worker_image_name is not set"
        else v;
    };

    worker_azs = mkOption {
      type = with types; listOf str;
      default = [];
    };

    worker_names = mkOption {
      description = ''
        It can be used to uniquely identify workers
      '';
      type = with types; listOf str;
      default = [];
    };

    master_flavors = mkOption {
      type = with types; listOf str;
      default = [];
      apply = v:
        if v == [] && cfg.default_master_flavor == null
        then throw "terraform.master_flavors cannot be empty if terraform.default_master_flavor is not set"
        else v;
    };

    master_images = mkOption {
      type = with types; listOf str;
      default = [];
      apply = v:
        if v == [] && cfg.default_master_image_name == null
        then throw "terraform.master_images cannot be empty if terraform.default_master_image_name is not set"
        else v;
    };

    master_azs = mkOption {
      type = with types; listOf str;
      default = [];
    };

    master_names = mkOption {
      description = ''
        It can be used to uniquely identify masters
      '';
      type = with types; listOf str;
      default = [];
    };

    thanos_delete_container = mkOption {
      type = types.bool;
      default = false;
    };

    enable_az_management = mkEnableOption ''
      if set to true one must set proper values for the "azs" array according to the cloud in use
    '';

    create_root_disk_on_volume = mkEnableOption ''
      If true, create block volume for each instance and boot from there.
      Equivalent to `openstack server create --boot-from-volume […].
    '';

    timeout_time = mkOption {
      type = types.str;
      default = "30m";
    };

    root_disk_volume_type = mkOption {
      description = ''
        Volume type that is used if `create_root_disk_on_volume` is true.
      '';
      type = types.str;
      default = "three_times_replicated";
    };

    master_join_anti_affinity_group = mkOption {
      type = with types; listOf bool;
      default = [];
    };

    worker_join_anti_affinity_group = mkOption {
      type = with types; listOf bool;
      default = [];
    };

    worker_anti_affinity_group_name = mkOption {
      type = types.str;
      default = "cah-anti-affinity";
    };

    master_root_disk_sizes = mkOption {
      type = with types; listOf int;
      default = [];
      description = "If 'create_root_disk_on_volume=true' and the master flavor does not specify a disk size, the root disk volume of this particular instance will have this size.";
    };

    master_root_disk_volume_types = mkOption {
      type = with types; listOf str;
      default = [];
      description = "If 'create_root_disk_on_volume=true', volume type for root disk of this particular control plane node. If left empty, the volume type specified in 'root_disk_volume_type' will be used.";
    };

    worker_root_disk_sizes = mkOption {
      type = with types; listOf int;
      default = [];
      description = "If 'create_root_disk_on_volume=true', size of the root disk of this particular worker node. If left empty, the root disk size specified in 'default_worker_root_disk_size' is used.";
    };

    worker_root_disk_volume_types = mkOption {
      type = with types; listOf str;
      default = [];
      description = "If 'create_root_disk_on_volume=true', volume types for the root disk of this particular worker node. If left empty, the volume type specified in 'root_disk_volume_type' will be used.";
    };

    gateway_root_disk_volume_size = mkOption {
      type = types.int;
      default = 10;
      description = "If 'create_root_disk_on_volume=true' and the gateway flavor does not specify a disk size, the root disk volume will have this size.";
    };

    gateway_root_disk_volume_type = mkOption {
      type = types.str;
      default = "";
      description = "If 'create_root_disk_on_volume=true', set the volume type of the root disk volume for Gateways. Can't be configured separately for each instance. If left empty, the volume type specified in 'root_disk_volume_type' will be used.";
    };

    default_master_root_disk_size = mkOption {
      type = types.int;
      default = 50;
      description = "If 'create_root_disk_on_volume=true', the master flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size.";
    };

    default_worker_root_disk_size = mkOption {
      type = types.int;
      default = 50;
      description = "If 'create_root_disk_on_volume=true', the worker flavor does not specify a disk size and no specific value has been given, the root disk volume will have this size.";
    };

    network_mtu = mkOption {
      type = types.int;
      default = 1450;
      description = "MTU for the network used for the cluster.";
    };

    dns_nameservers_v4 = mkOption {
      type = with types; listOf str;
      default = [];
      description = "A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet.";
    };
    monitoring_manage_thanos_bucket = mkInternalOption {
      description = ''
        If we want to use thanos, then the user can decide if terraform should create
        an object storage container.
      '';
      type = types.bool;
      default = with config.yk8s.k8s-service-layer.prometheus;
        use_thanos && manage_thanos_bucket;
    };

    gitlab_backend = mkEnableOption ''
      Enable GitLab-managed Terraform backend
      If true, the Terraform state will be stored inside the provided gitlab project.
      If set, the environment `TF_HTTP_USERNAME` and `TF_HTTP_PASSWO = mkOptionD`
      must be configured in a separate file `~/.config/yaook-k8s/env`.
    '';
    gitlab_base_url = mkOption {
      description = ''
        The base URL of your GitLab project.
      '';
      type = types.str;
      default = "https://gitlab.com";
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
          "[terraform] gitlab_backend is enabled but gitlab_project_id is unset"
        else v;
    };

    gitlab_state_name = mkOption {
      description = ''
        The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'      '';
      type = types.str;
      default = "tf-state";
    };
  };
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/cluster.yaml";
      transformations = [(filterAttrs (name: _: name == "cluster_name"))];
    })
  ];
  config.yk8s._state_packages = [
    (
      let
        transformations = [removeObsoleteOptions filterInternal filterNull];
        varsFile = (pkgs.formats.json {}).generate "tfvars.json" (pipe cfg transformations);
      in (pkgs.runCommandLocal "tfvars.json" {} ''
        install -m 644 -D ${varsFile} $out/${tfvars_file_path}
      '')
    )
  ];
}
