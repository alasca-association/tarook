{
  config,
  lib,
  yk8s-lib,
  terranix-lib,
  pkgs,
  system,
  ...
}: let
  cfg = config.yk8s.terraform;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkInternalOption types;
  tfOutputsPath = "terraform/outputs.json";
  tfOutputsFullPath = "${config.yk8s.state_directory}/${tfOutputsPath}";
in {
  imports = [
    (mkRemovedOptionModule ["terraform" "haproxy_ports"] "")
    (mkRemovedOptionModule ["terraform" "prevent_disruption"] "Preventing disruption is now handled by a lock file in the Terraform state directory.")
    (mkRenamedOptionModule ["terraform" "subnet_cidr"] ["infra" "subnet_cidr"])
    (mkRenamedOptionModule ["terraform" "subnet_v6_cidr"] ["infra" "subnet_v6_cidr"])
    (mkRenamedOptionModule ["terraform" "ipv4_enabled"] ["infra" "ipv4_enabled"])
    (mkRenamedOptionModule ["terraform" "ipv6_enabled"] ["infra" "ipv6_enabled"])
    (mkRenamedOptionModule ["terraform" "cluster_name"] ["infra" "cluster_name"])
    (mkRenamedOptionModule ["terraform" "public_network"] ["openstack" "public_network"])
    (mkRenamedOptionModule ["terraform" "keypair"] ["openstack" "keypair"])
    (mkRenamedOptionModule ["terraform" "azs"] ["openstack" "azs"])
    (mkRenamedOptionModule ["terraform" "thanos_delete_container"] ["openstack" "thanos_delete_container"])
    (mkRenamedOptionModule ["terraform" "spread_gateways_across_azs"] ["openstack" "spread_gateways_across_azs"])
    (mkRenamedOptionModule ["terraform" "create_root_disk_on_volume"] ["openstack" "create_root_disk_on_volume"])
    (mkRenamedOptionModule ["terraform" "network_mtu"] ["openstack" "network_mtu"])
    (mkRenamedOptionModule ["terraform" "dns_nameservers_v4"] ["openstack" "dns_nameservers_v4"])
    (mkRenamedOptionModule ["terraform" "monitoring_manage_thanos_bucket"] ["openstack" "monitoring_manage_thanos_bucket"])
    (mkRenamedOptionModule ["terraform" "gateway_count"] ["openstack" "gateway_count"])
    (mkRenamedOptionModule ["terraform" "gateway_defaults"] ["openstack" "gateway_defaults"])
    (mkRenamedOptionModule ["terraform" "master_defaults"] ["openstack" "master_defaults"])
    (mkRenamedOptionModule ["terraform" "worker_defaults"] ["openstack" "worker_defaults"])
    (mkRenamedOptionModule ["terraform" "nodes"] ["openstack" "nodes"])

    (mkRenamedOptionModule ["terraform" "gitlab_base_url"] ["terraform" "gitlab" "base_url"])
    (mkRenamedOptionModule ["terraform" "gitlab_project_id"] ["terraform" "gitlab" "project_id"])
    (mkRenamedOptionModule ["terraform" "gitlab_state_name"] ["terraform" "gitlab" "state_name"])
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
    enabled = mkEnableOption ''
      Terraform usage.
      If :ref:`configuration-options.yk8s.openstack.enabled` is true,
      Terraform is automatically used and must not be explicitly enabled.
    '';

    timeout_time = mkOption {
      description = "Timeout duration for Terraform operations";
      type = types.yk8s.terraform.durationStr;
      default = "30m";
    };

    gitlab_backend = mkEnableOption ''
      GitLab-managed Terraform backend
      If true, the Terraform state will be stored inside the provided gitlab project.
      If set, the environment `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`
      must be configured in a separate file `~/.config/yaook-k8s/env`.
    '';

    gitlab.base_url = mkOption {
      description = ''
        The base HTTP(s) URL of your GitLab instance.
      '';
      type = with types; nullOr yk8s.networking.httpxHostPathUrl;
      default = null;
      example = "https://gitlab.com";
    };

    gitlab.project_id = mkOption {
      description = ''
        The unique ID of your GitLab project.
      '';
      type = with types; nullOr yk8s.gitlab.projectId;
      default = null;
    };

    gitlab.state_name = mkOption {
      description = ''
        The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'
      '';
      type = with types; nullOr yk8s.gitlab.terraformStateName;
      default = null;
      example = "tf-state";
    };

    gitlab.backend_address = mkInternalOption {
      readOnly = true;
      type = with types; nullOr nonEmptyStr;
    };

    modules = mkOption {
      type = with types; listOf anything;
      default = [];
    };

    outputs = mkInternalOption {
      readOnly = true;
      type = types.attrs;
      default =
        if config.yk8s.state_directory != null && builtins.pathExists tfOutputsFullPath
        then builtins.fromJSON (builtins.readFile tfOutputsFullPath)
        else throw "${tfOutputsPath} does not exist yet. Terraform stage needs to be run first.";
    };

    migrations = mkInternalOption {
      # TODO: allow different types of migration (mv, rm...)
      type = types.listOf (types.submodule {
        options = {
          from = mkOption {
            type = types.nonEmptyStr;
          };
          to = mkOption {
            type = types.nonEmptyStr;
          };
        };
      });
    };
  };

  config.yk8s = let
    all_gitlab_vars = ["base_url" "project_id" "state_name"];
    all_gitlab_vars_are_set = lib.all (v: v != null) (builtins.attrValues (lib.getAttrs all_gitlab_vars cfg.gitlab));
    all_gitlab_vars_are_unset = lib.all (v: v == null) (builtins.attrValues (lib.getAttrs all_gitlab_vars cfg.gitlab));
  in
    lib.mkIf cfg.enabled {
      terraform.gitlab.backend_address =
        if all_gitlab_vars_are_set
        then "${cfg.gitlab.base_url}/api/v4/projects/${cfg.gitlab.project_id}/terraform/state/${cfg.gitlab.state_name}"
        else null;

      terraform.migrations = let
        getMigrations = path: value:
          lib.optionals (builtins.isAttrs value) (
            if value ? "_import_from"
            then
              lib.singleton {
                from = value._import_from;
                to = lib.strings.concatStringsSep "." path;
              }
            else lib.foldlAttrs (acc: k: v: acc ++ getMigrations (path ++ [k]) v) [] value
          );
      in
        builtins.foldl' (acc: mod: acc ++ (getMigrations [] (mod.resource or {}))) [] cfg.modules;

      _targets.terraform = {
        assertions = [
          {
            assertion = cfg.gitlab_backend -> all_gitlab_vars_are_set;
            message = "[yk8s.terraform] gitlab_backend=true' but GitLab variables are not (completely) provided. Please set all of ${lib.concatStringsSep " " all_gitlab_vars}";
          }
          {
            assertion = all_gitlab_vars_are_set || all_gitlab_vars_are_unset;
            message = ''
              [yk8s.terraform] gitlab_backend=false but some GitLab variables are provided.
              (1) If you want to migrate the Terraform backend method from 'http' to 'local',
              you should provide all the GitLab variables
              (2) If you want to init a cluster with local backend,
              make sure that all all of ${lib.concatStringsSep " " all_gitlab_vars} are unset.
            '';
          }
        ];
        warnings = [];

        inventory_subdir = "terraform";
        inventory_packages = [
          (yk8s-lib.mkYamlAtPath "gitlab.yaml" cfg.gitlab)
        ];

        state_packages = let
          tfConfig = terranix-lib.terranixConfiguration {
            inherit system;
            modules = map (lib.filterAttrsRecursive (k: _: k != "_import_from")) cfg.modules;
          };
        in [
          (yk8s-lib.linkToPath tfConfig "terraform/config.tf.json")
        ];
      };
    };
  config.packages.tf-state-migrations = builtins.seq (yk8s-lib.baseSystemAssertWarn config.yk8s) (pkgs.writeScript "tf-state-migrations" (
    lib.strings.concatMapStringsSep "\n" (v: "run terraform state mv -state \"$tf_statefile_temp\" '${v.from}' '${v.to}'") cfg.migrations
  ));
  config.packages.tf-state-migrations-undo = pkgs.writeScript "tf-state-migrations" (
    lib.strings.concatMapStringsSep "\n" (v: "run terraform state mv -state \"$tf_statefile_temp\" '${v.to}' '${v.from}'") cfg.migrations
  );
  config.packages.tf-state-migrations-json = yk8s-lib.mkJson "tf-state-migrations.json" {
    migration.state.yk8s = {
      dir = yk8s-lib.tfRef "env.terraform_state_dir";
      actions = (
        map (v: "mv '${v.from}' '${v.to}'") cfg.migrations
      );
    };
  };
}
