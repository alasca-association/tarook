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
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption linkToPath mkJson;
  inherit (yk8s-lib.types) ipv4Cidr;
  inherit (yk8s-lib.transform) filterNull removeObsoleteOptions filterInternal;
  inherit (builtins) fromJSON readFile pathExists length;
  tfvars_file_path = "terraform/config.tfvars.json";

  openstackTerraformOptions = [
    "public_network"
    "keypair"
    "azs"
    "thanos_delete_container"
    "spread_gateways_across_azs"
    "create_root_disk_on_volume"
    "network_mtu"
    "dns_nameservers_v4"
    "monitoring_manage_thanos_bucket"
    "gateway_count"
    "gateway_defaults"
    "master_defaults"
    "worker_defaults"
    "nodes"
  ];
  infraTerraformOptions = [
    "cluster_name"
    "ipv4_enabled"
    "ipv6_enabled"
    "subnet_cidr"
    "subnet_v6_cidr"
  ];
in {
  imports = [
    (mkRemovedOptionModule "terraform" "haproxy_ports" "")
    (mkRemovedOptionModule "terraform" "prevent_disruption" "Preventing disruption is now handled by a lock file in the Terraform state directory.")
    (mkRenamedOptionModuleWithNewSection "terraform" "subnet_cidr" "infra" "subnet_cidr")
    (mkRenamedOptionModuleWithNewSection "terraform" "subnet_v6_cidr" "infra" "subnet_v6_cidr")
    (mkRenamedOptionModuleWithNewSection "terraform" "ipv4_enabled" "infra" "ipv4_enabled")
    (mkRenamedOptionModuleWithNewSection "terraform" "ipv6_enabled" "infra" "ipv6_enabled")
    (mkRenamedOptionModuleWithNewSection "terraform" "cluster_name" "infra" "cluster_name")
    (mkRenamedOptionModuleWithNewSection "terraform" "public_network" "openstack" "public_network")
    (mkRenamedOptionModuleWithNewSection "terraform" "keypair" "openstack" "keypair")
    (mkRenamedOptionModuleWithNewSection "terraform" "azs" "openstack" "azs")
    (mkRenamedOptionModuleWithNewSection "terraform" "thanos_delete_container" "openstack" "thanos_delete_container")
    (mkRenamedOptionModuleWithNewSection "terraform" "spread_gateways_across_azs" "openstack" "spread_gateways_across_azs")
    (mkRenamedOptionModuleWithNewSection "terraform" "create_root_disk_on_volume" "openstack" "create_root_disk_on_volume")
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
    _docs.order = 1;
    _docs.preface = ''
      Gitlab Terraform backend
      """"""""""""""""""""""""

      To activate automatic backend of Terraform statefiles to Gitlab,
      adapt the Terraform section of your config:
      set :ref:`configuration-options.yk8s.terraform.gitlab_backend` to ``true``,
      set the URL of the Gitlab project and
      the name of the Gitlab state object.

      .. code:: nix

        terraform = {
          gitlab_backend    = true;
          gitlab_base_url   = "https://gitlab.com";
          gitlab_project_id = "012345678";
          gitlab_state_name = "tf-state";
        };

      Put your Gitlab username and access token
      into the ``~/.config/yaook-k8s/env``.
      Your Gitlab access token must have
      at least Maintainer role and
      read/write access to the API.
      Please see GitLab documentation for creating a
      `personal access token <https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html>`__.

      To successful migrate from the "local" to "http" Terraform backend method,
      ensure that :ref:`configuration-options.yk8s.terraform.gitlab_backend` is set to ``true``
      and all other required variables are set correctly.
      Incorrect data entry may result in an HTTP error respond,
      such as a HTTP/401 error for incorrect credentials.
      Assuming correct credentials in the case of an HTTP/404 error,
      Terraform is executed and the state is migrated to Gitlab.

      To migrate from the "http" to "local" Terraform backend method,
      set :ref:`configuration-options.yk8s.terraform.gitlab_backend` to ``false``,
      `MANAGED_K8S_NUKE_FROM_ORBIT=true`,
      and assume
      that all variables above are properly set
      and the Terraform state exists on GitLab.
      Once the migration is successful,
      unset the variables above
      to continue using the "local" backend method.

      .. code:: bash

        export TF_HTTP_USERNAME="<gitlab-username>"
        export TF_HTTP_PASSWORD="<gitlab-access-token>"
    '';
    enabled = mkOption {
      type = types.bool;
      default = true;
    };

    timeout_time = mkOption {
      type = types.nonEmptyStr;
      default = "30m";
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
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "https://gitlab.com";
    };

    gitlab_project_id = mkOption {
      description = ''
        The unique ID of your GitLab project.
      '';
      type = with types; nullOr nonEmptyStr;
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
        The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "tf-state";
    };
  };
  config.yk8s = {
    _inventory_packages =
      [
        (mkGroupVarsFile {
          cfg = lib.attrsets.getAttrs ["enabled"] cfg;
          inventory_path = "all/terraform.yaml";
        })
      ]
      ++ lib.optionals cfg.enabled (
        let
          linkTfstateIfExists = source: target:
            if config.yk8s.state_directory != null && builtins.pathExists "${config.yk8s.state_directory}/${source}"
            then [(linkToPath "${config.yk8s.state_directory}/${source}" target)]
            else
              builtins.trace "INFO: ${config.yk8s._state_base_path}/${source} does not yet exist. Terraform stage needs to be run first."
              [];
        in
          (linkTfstateIfExists "terraform/rendered/hosts" "hosts")
          ++ (linkTfstateIfExists "terraform/rendered/terraform_networking-trampoline.yaml" "group_vars/all/terraform_networking-trampoline.yaml")
          ++ (linkTfstateIfExists "terraform/rendered/terraform_networking.yaml" "group_vars/all/terraform_networking.yaml")
      );
    _state_packages =
      lib.optional cfg.enabled
      (
        let
          filteredTerraformCfg = yk8s-lib.removeAttrsByPath config.yk8s.terraform [["enabled"]];
          filteredInfraCfg = lib.attrsets.getAttrs infraTerraformOptions config.yk8s.infra;
          filteredOpenstackCfg = lib.attrsets.getAttrs openstackTerraformOptions config.yk8s.openstack;
          mergedCfg =
            builtins.foldl' (acc: e: lib.attrsets.recursiveUpdate acc (removeObsoleteOptions e)) {}
            [filteredTerraformCfg filteredInfraCfg filteredOpenstackCfg];
          transformations = [filterInternal filterNull];
          varsFile = mkJson "tfvars.json" (pipe mergedCfg transformations);
        in (pkgs.runCommandLocal "tfvars.json" {} ''
          install -m 644 -D ${varsFile} $out/${tfvars_file_path}
        '')
      );
  };
}
