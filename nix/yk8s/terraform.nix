{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.terraform;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption types;
  inherit (lib.attrsets) filterAttrs recursiveUpdate;
  inherit (lib.trivial) pipe;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption linkToPath;
  inherit (yk8s-lib.types) ipv4Cidr;
  inherit (yk8s-lib.transform) filterNull removeObsoleteOptions filterInternal;
  inherit (builtins) fromJSON readFile pathExists length;
  tfvars_file_path = "terraform/config.tfvars.json";
  commonNodeDefaultOptions = {
    image = mkOption {
      type = types.str;
    };
    flavor = mkOption {
      type = types.str;
    };
    root_disk_size = mkOption {
      description = ''
        Only apples if 'terraform.create_root_disk_on_volume=true'.
      '';
      type = types.ints.positive;
    };
    root_disk_volume_type = mkOption {
      description = ''
        Only apples if 'terraform.create_root_disk_on_volume=true'.
        If left empty, the default of the IaaS environment will be used.
      '';
      type = types.str;
      default = "";
    };
  };
in {
  imports = [
    (mkRemovedOptionModule "terraform" "haproxy_ports" "")
  ];

  options.yk8s.terraform = mkTopSection {
    _docs.order = 1;
    _docs.preface = ''
      .. _cluster-configuration.configuring-terraform:

      Configuring Terraform
      ^^^^^^^^^^^^^^^^^^^^^
      .. note::

         There is a variable ``nodes`` to configure
         the k8s master and worker servers.
         The ``role`` attribute must be used to distinguish both [1]_.

         The amount of gateway nodes can be controlled with the `gateway_count` variable.
         It defaults to the number of elements in the ``azs`` array when
         ``spread_gateways_across_azs=true`` and 3 otherwise.

      .. [1] Caveat: Changing the role of a Terraform node
                     will completely rebuild the node.

      .. attention::

          You must configure at least one master node.

      You can add and delete Terraform nodes simply
      by adding and removing their entries to/from the config
      or tuning ``gateway_count`` for gateway nodes.
      Consider the following example:

      .. code:: diff

          terraform = {

         -  gateway_count = 3;
         +  gateway_count = 2;                 # <-- one gateway gets deleted

            nodes = {
              worker-0 = {
                role = "worker";
                flavor = "M";
                image = "Debian 12 (bookworm)";
              };
         -    worker-1 = {                     # <-- gets deleted
         -      role = "worker";
         -      flavor = "M";
         -    };
              worker-2 = {
                role = "worker";
                flavor = "L";
              };
         +    mon1 = {                         # <-- gets created
         +      role = "worker";
         +      flavor = "S";
         +      image = "Ubuntu 22.04 LTS x64";
         +    };
            };
         };

      The name of a Terraform node is composed from the following parts:

      - for master/worker nodes:
        ``terraform.cluster_name`` ``<the nodes' table name>``

      - for gateway nodes:
        ``terraform.cluster_name`` ``terraform.gateway_defaults.common_name`` ``<numeric-index>``

      .. code:: nix

         terraform = {

          cluster_name = "yk8s";
          gateway_count = 1;
          #....

          gateway_defaults.common_name = "gateway-";

          nodes.master-X.role = "master";
          nodes.worker-A.role = "worker";

          # yields the following node names:
          # - yk8s-gateway-0
          # - yk8s-master-X
          # - yk8s-worker-A


      To activate automatic backend of Terraform statefiles to Gitlab,
      adapt the Terraform section of your config:
      set `gitlab_backend` to True,
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
      ensure that `gitlab_backend` is set to `true`
      and all other required variables are set correctly.
      Incorrect data entry may result in an HTTP error respond,
      such as a HTTP/401 error for incorrect credentials.
      Assuming correct credentials in the case of an HTTP/404 error,
      Terraform is executed and the state is migrated to Gitlab.

      To migrate from the "http" to "local" Terraform backend method,
      set `gitlab_backend=false`,
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

    cluster_name = mkOption {
      type = types.str;
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
      type = types.str;
      default = "fd00::/120";
    };

    ipv6_enabled = mkEnableOption "IPv6";

    ipv4_enabled = mkOption {
      description = ''
        If set to true, ipv4 will be used
      '';
      type = types.bool;
      default = true;
    };

    public_network = mkOption {
      type = types.str;
      default = "shared-public-IPv4";
    };

    keypair = mkOption {
      description = ''
        Will most of the time be set via the environment variable TF_VAR_keypair
      '';
      type = with types; nullOr str;
      default = null;
    };

    azs = mkOption {
      description = "Defines the availability zones of your cloud to use for the creation of servers.";
      default = ["AZ1" "AZ2" "AZ3"];
      type = with types; listOf str;
    };

    thanos_delete_container = mkOption {
      type = types.bool;
      default = false;
    };

    # Setting this to false is useful in CI environments if the Cloud Is Full.
    spread_gateways_across_azs = mkOption {
      description = "If true, spawn a gateway node in each availability zone listed in 'azs'. Otherwise leave the distribution to the cloud controller.";
      type = types.bool;
      default = true;
    };

    create_root_disk_on_volume = mkEnableOption ''
      creation of root disk volumes.
      If true, create block volume for each instance and boot from there.
      Equivalent to ``openstack server create --boot-from-volume […]``.
    '';

    timeout_time = mkOption {
      type = types.str;
      default = "30m";
    };

    network_mtu = mkOption {
      type = types.ints.positive;
      default = 1450;
      description = "MTU for the network used for the cluster.";
    };

    dns_nameservers_v4 = mkOption {
      type = with types; listOf str;
      default = [];
      description = "A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet.";
    };

    monitoring_manage_thanos_bucket = mkInternalOption {
      description = "Create an object storage container for thanos.";
      type = types.bool;
      default = with config.yk8s.k8s-service-layer.prometheus;
        use_thanos && manage_thanos_bucket;
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
      example = ''
        "https://gitlab.com"
      '';
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
      type = with types; nullOr str;
      default = null;
      example = ''
        "tf-state"
      '';
    };

    gateway_count = mkOption {
      type = types.ints.positive;
      default =
        if cfg.spread_gateways_across_azs
        then length cfg.azs
        else 3;
      description = "Amount of gateway nodes to create. (default: 0 --> one for each availability zone when 'spread_gateways_across_azs=true', 3 otherwise)";
    };

    gateway_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 10;
      image.default = "Debian 12 (bookworm)";
      flavor.default = "XS";
      common_name = mkOption {
        type = types.str;
        default = "gw-";
      };
    };

    master_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 50;
      flavor.default = "M";
      image.default = "Ubuntu 22.04 LTS x64";
    };

    worker_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 50;
      flavor.default = "M";
      image.default = "Ubuntu 22.04 LTS x64";

      anti_affinity_group = mkOption {
        description = ''
          Leaving this empty means to not join any anti affinity group
        '';
        type = with types; nullOr str;
        default = null;
      };
    };

    nodes = mkOption {
      description = ''
        User defined attribute set of control plane and worker nodes to be created with specified values

        At least one node with role=master must be given.
      '';
      type = types.attrsOf (types.submodule {
        options = {
          role = mkOption {
            type = types.strMatching "master|worker";
          };
          image = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          flavor = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          az = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          root_disk_size = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          root_disk_volume_type = mkOption {
            type = with types; nullOr str;
            default = null;
          };
          anti_affinity_group = mkOption {
            description = ''
              'anti_affinity_group' must not be set when role!="worker"
              Leaving 'anti_affinity_group' empty means to not join any anti affinity group
            '';
            type = with types; nullOr str;
            default = null;
          };
        };
      });
      default = {};
    };
  };
  config.yk8s = lib.mkIf cfg.enabled {
    assertions = let
      inherit (builtins) all length filter attrValues;
    in [
      {
        assertion =
          all (node: node.role != "worker" -> node.anti_affinity_group == null)
          (attrValues cfg.nodes);
        message = "'anti_affinity_group' must not be set for master nodes";
      }
      {
        assertion = (length (filter (node: node.role == "master") (attrValues cfg.nodes))) > 0;
        message = "At least one node with role=master must be given.";
      }
      {
        assertion = config.yk8s.terraform.ipv4_enabled;
        message = "YAOOK/k8s Terraform does not yet support IPv6-only, see #685";
      }
      (let
        current_config_file =
          if config.yk8s.state_directory != null
          then "${config.yk8s.state_directory}/${tfvars_file_path}"
          else null;
        current_config = fromJSON (readFile current_config_file);
        cluster_exists =
          if current_config_file == null
          then false
          else pathExists current_config_file;
        current_cluster_name =
          if
            cluster_exists
            && current_config ? cluster_name
          then current_config.cluster_name
          else
            # hard-coding this value here as it was the default at the time of writing this module. This ensures that
            # old clusters that have been set up with an empty value (and hence have been using the old default) will
            # be compared to the old default value
            "managed-k8s";
      in {
        assertion = cluster_exists -> (config.yk8s.terraform.cluster_name == current_cluster_name);
        message = ''
          Will not update terraform config because there is a mismatch between the deployed and future cluster_name. This would cause death and destruction.
          Set `terraform.cluster_name` back to ${current_cluster_name}. Your suggested change ${config.yk8s.terraform.cluster_name} is unacceptable.
        '';
      })
    ];
    _inventory_packages =
      [
        (mkGroupVarsFile {
          inherit cfg;
          inventory_path = "all/cluster.yaml";
          transformations = [(filterAttrs (name: _: name == "cluster_name"))];
        })
      ]
      ++ (
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
    _state_packages = [
      (
        let
          transformations = [removeObsoleteOptions filterInternal filterNull];
          varsFile = (pkgs.formats.json {}).generate "tfvars.json" (pipe cfg transformations);
        in (pkgs.runCommandLocal "tfvars.json" {} ''
          install -m 644 -D ${varsFile} $out/${tfvars_file_path}
        '')
      )
    ];
  };
}
