{
  config,
  lib,
  yk8s-lib,
  pkgs,
  ...
}: let
  cfg = config.yk8s.openstack;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.attrsets) filterAttrs recursiveUpdate;
  inherit (lib.trivial) pipe;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkInternalOption mkDisableOption linkToPath types;
  inherit (yk8s-lib.transform) removeObsoleteOptions filterInternal;
  inherit (builtins) fromJSON readFile pathExists length;
  tfvars_file_path = "terraform/config.tfvars.json";
  commonNodeDefaultOptions = {
    image = mkOption {
      type = types.yk8s.openstack.imageName;
    };
    flavor = mkOption {
      type = types.yk8s.openstack.flavorName;
    };
    root_disk_size = mkOption {
      description = ''
        Only applies if :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume` is set to ``true``
      '';
      type = types.ints.positive;
    };
    root_disk_volume_type = mkOption {
      description = ''
        Only applies if :ref:`configuration-options.yk8s.openstack.create_root_disk_on_volume` is set to ``true``
        If null, the default of the IaaS environment will be used.
      '';
      type = with types; nullOr yk8s.openstack.volumeTypeName;
      default = null;
    };
  };
  # NOTE: Some options are not used by Ansible but other parts of the LCM,
  #       such as Terraform. Therefore they are filtered out.
  nonAnsibleOptions = [
    "public_network"
    "keypair"
    "azs"
    "thanos_delete_container"
    "spread_gateways_across_azs"
    "create_root_disk_on_volume"
    "dns_nameservers_v4"
    "monitoring_manage_thanos_bucket"
    "gateway_count"
    "gateway_defaults"
    "master_defaults"
    "worker_defaults"
    "nodes"
  ];
in {
  options.yk8s.openstack = mkTopSection {
    _docs.order = 1;
    _docs.preface = ''
      .. note::

         :ref:`configuration-options.yk8s.openstack.nodes`
         allows you to configure
         the k8s master and worker servers.
         The ``role`` attribute must be used to distinguish both [1]_.

         The amount of gateway nodes can be controlled with
         :ref:`configuration-options.yk8s.openstack.gateway_count`.

      .. [1] Caveat: Changing the role of a Terraform node
                     will completely rebuild the node.

      .. attention::

          You must configure at least one master node.

      You can add and delete Terraform nodes simply
      by adding and removing their entries to/from the config
      or tuning :ref:`configuration-options.yk8s.openstack.gateway_count` for gateway nodes.
      Consider the following example:

      .. code:: diff

          openstack = {

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

      The name of an OpenStack node is composed from the following parts:

      - for master/worker nodes:
        ``yk8s.infra.cluster_name`` ``<the nodes' key in yk8s.openstack.nodes>``

      - for gateway nodes:
        ``yk8s.infra.cluster_name`` ``yk8s.openstack.gateway_defaults.common_name`` ``<numeric-index>``

      .. code:: nix

         openstack = {

          cluster_name = "yk8s";
          gateway_count = 1;
          #....

          gateway_defaults.common_name = "gateway-";

          nodes.master-x.role = "master";
          nodes.worker-a.role = "worker";

          # yields the following node names:
          # - yk8s-gateway-0
          # - yk8s-master-x
          # - yk8s-worker-a
    '';

    enabled = mkOption {
      description = ''
        Whether to build the cluster on top of Openstack.
      '';
      type = types.bool;
      default = true;
    };

    public_network = mkOption {
      description = ''
        Name of the Openstack provider network to use
      '';
      type = types.yk8s.openstack.networkName;
    };

    keypair = mkOption {
      description = ''
        Name of the SSH public key in your cloud environment

        Will most of the time be set via the environment variable TF_VAR_keypair
      '';
      type = with types; nullOr yk8s.openstack.keypairName;
      default = null;
    };

    azs = mkOption {
      description = "Availability zones of the underlying Openstack cloud to use for the creation of servers.";
      default = [];
      type = with types; listOf yk8s.openstack.availabilityZoneName;
    };

    thanos_delete_container = mkEnableOption ''
      deletion of the Thanos object storage container
      in case
      :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.use_thanos`
      AND :ref:`configuration-options.yk8s.k8s-service-layer.prometheus.manage_thanos_bucket`
      are switched off
    '';

    # Setting this to false is useful in CI environments if the Cloud Is Full.
    spread_gateways_across_azs = mkOption {
      description = "If true, spawn a gateway node in each availability zone listed in :ref:`configuration-options.yk8s.openstack.spread_gateways_across_azs`, Otherwise leave the distribution to the cloud controller.";
      type = types.bool;
      default = true;
    };

    create_root_disk_on_volume = mkEnableOption ''
      creation of root disk volumes.
      If true, create block volume for each instance and boot from there.
      Equivalent to ``openstack server create --boot-from-volume […]``.
    '';

    network_mtu = mkOption {
      type = types.ints.positive;
      default = 1450;
      description = "MTU for the network used for the cluster.";
    };

    dns_nameservers_v4 = mkOption {
      type = with types; listOf yk8s.networking.ipv4Addr;
      default = [];
      description = "A list of IPv4 addresses which will be configured as DNS nameservers of the IPv4 subnet.";
    };

    monitoring_manage_thanos_bucket = mkInternalOption {
      description = "Create an object storage container for thanos.";
      type = types.bool;
      default = with config.yk8s.k8s-service-layer.prometheus;
        use_thanos && manage_thanos_bucket;
    };
    gateway_count = mkOption {
      type = types.ints.positive;
      default =
        if cfg.spread_gateways_across_azs
        then length cfg.azs
        else 3;
      description = ''
        Amount of gateway nodes to create.

        Defaults to 3
        unless
        :ref:`configuration-options.yk8s.openstack.spread_gateways_across_azs`
        is set to ``true``
        in which case it will match the amount of availability zones by default.
      '';
    };

    gateway_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 10;
      common_name = mkOption {
        type = types.str;
        default = "gw-";
      };
    };

    master_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 50;
    };

    worker_defaults = recursiveUpdate commonNodeDefaultOptions {
      root_disk_size.default = 50;

      anti_affinity_group = mkOption {
        description = ''
          Leaving this empty means to not join any anti affinity group
        '';
        type = with types; nullOr yk8s.openstack.serverGroupName;
        default = null;
      };
    };

    nodes = mkOption {
      description = ''
        User defined attribute set of control plane and worker nodes to be created with specified values

        At least one node with role=master must be given.

        You may also specify those attributes or a subset of them
        using :ref:`yk8s.openstack.{master,worker}_defaults <configuration-options.yk8s.openstack>`.
      '';
      type = types.attrsOf (types.submodule {
        options = {
          role = mkOption {
            type = types.enum [
              "master"
              "worker"
            ];
          };
          image = mkOption {
            type = with types; nullOr yk8s.openstack.imageName;
            default = null;
          };
          flavor = mkOption {
            type = with types; nullOr yk8s.openstack.flavorName;
            default = null;
          };
          az = mkOption {
            type = with types; nullOr yk8s.openstack.availabilityZoneName;
            default = null;
          };
          root_disk_size = mkOption {
            type = with types; nullOr ints.positive;
            default = null;
          };
          root_disk_volume_type = mkOption {
            type = with types; nullOr yk8s.openstack.volumeTypeName;
            default = null;
          };
          anti_affinity_group = mkOption {
            description = ''
              Must not be set when role!="worker".
              If left empty no anti affinity group will be joined.
            '';
            type = with types; nullOr yk8s.openstack.serverGroupName;
            default = null;
          };
        };
      });
      default = {};
    };

    network_name = mkOption {
      description = ''
        Name of the internal OpenStack network. This field becomes important if a VM is
        attached to two networks but the controller-manager should only pick up one. If
        you don't understand the purpose of this field, there's a very high chance you
        won't need to touch it.
        Note: This network name isn't fetched automagically (by terraform) on purpose
        because there might be situations where the CCM should not pick the managed network.
      '';
      type = with types; nullOr yk8s.openstack.networkName;
      default = null;
      example = lib.options.literalExpression "\"\${config.yk8s.infra.cluster_name}-network\"";
    };

    cinder_enable_topology = mkEnableOption ''
      cinder topology.
      This flag enables the topology feature gate of the cinder controller plugin.
      Its purpose is to allocate volumes from cinder which are in the same AZ as
      the worker node to which the volume should be attached.
      Important: Cinder must support AZs and the AZs must match the AZs used by nova!
    '';

    cinder_volume_type = mkOption {
      description = ''
        Use a specific volume type for the csi-sc-cinderplugin StorageClass.
        If unset, no volume type is explicitly set and the default volume type
        of the IaaS-layer is used.
      '';
      type = with types; nullOr yk8s.openstack.volumeTypeName;
      default = null;
    };

    check_credentials = mkDisableOption ''
      OpenStack credential checks
      Terrible things will happen when certain tasks are run and OpenStack credentials are not sourced.
      Okay, maybe not so terrible after all, but the templates do not check if certain values exist.
      Hence config files with empty credentials are written. The LCM will execute a simple check to see
      if you provided valid credentials as a sanity check if you're on openstack and this option is set
      to true.
    '';
  };
  config.yk8s = lib.mkMerge [
    {
      _targets.ansible.inventory_packages = [
        (mkGroupVarsFile {
          inherit cfg;
          inventory_path = "all/openstack.yaml";
          ansible_prefix = "openstack_";
          only_if_enabled = true;
          transformations = [(c: builtins.removeAttrs c nonAnsibleOptions)];
        })
      ];
    }
    (lib.mkIf cfg.enabled {
      terraform.enabled = true;

      assertions = let
        inherit (builtins) all length filter attrValues;
      in [
        {
          assertion =
            all (node: node.role != "worker" -> node.anti_affinity_group == null)
            (attrValues cfg.nodes);
          message = "config.yk8s.openstack.nodes.[].anti_affinity_group: must not be set for master nodes";
        }
        {
          assertion = (length (filter (node: node.role == "master") (attrValues cfg.nodes))) > 0;
          message = "config.yk8s.openstack.nodes: at least one node with role=master must be given.";
        }
        {
          assertion = config.yk8s.infra.ipv4_enabled;
          message = "config.yk8s.openstack: Tarook Terraform does not yet support IPv6-only, see #685";
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
            current_config.cluster_name
            or
            # hard-coding this value here as it was the default at the time of writing this module. This ensures that
            # old clusters that have been set up with an empty value (and hence have been using the old default) will
            # be compared to the old default value
            "managed-k8s";
        in {
          assertion = cluster_exists -> (config.yk8s.infra.cluster_name == current_cluster_name);
          message = ''
            config.yk8s.infra.cluster_name:
            Will not update terraform config because there is a mismatch between the deployed and future cluster_name. This would cause death and destruction.
            Set `config.yk8s.infra.cluster_name` back to ${current_cluster_name}. Your suggested change ${config.yk8s.infra.cluster_name} is unacceptable.
          '';
        })
        {
          # although IPv4 technically works with lower MTUs, 576 Bytes is the recommended minimum size of datagrams
          # https://datatracker.ietf.org/doc/html/rfc791
          assertion = config.yk8s.infra.ipv4_enabled -> cfg.network_mtu >= 576;
          message = "config.yk8s.openstack.network_mtu: must be at least 576 Bytes to support IPv4.";
        }
        {
          # 1280 Bytes is the technical minimum MTU for IPv6 to work
          # https://datatracker.ietf.org/doc/html/rfc8200#section-5
          assertion = config.yk8s.infra.ipv6_enabled -> cfg.network_mtu >= 1280;
          message = "config.yk8s.openstack.network_mtu: must be at least 1280 Bytes to support IPv6.";
        }
      ];

      infra = {
        networking_floating_ip = config.yk8s.terraform.outputs.networking_floating_ip.value;
        networking_fixed_ip = config.yk8s.terraform.outputs.networking_fixed_ip.value or null;
        networking_fixed_ip_v6 = config.yk8s.terraform.outputs.networking_fixed_ip_v6.value or null;
        ansible_hosts = {
          all.vars = {
          };

          frontend.children = {
            gateways = {};
          };

          gateways.hosts =
            lib.mapAttrs (
              name: _:
                {
                  ansible_host = config.yk8s.terraform.outputs.gateway_fips.value.${name}.address;
                  port_id = config.yk8s.terraform.outputs.gateway_ports.value.${name}.id;
                  local_ipv4_address = builtins.head config.yk8s.terraform.outputs.gateway_ports.value.${name}.all_fixed_ips;
                }
                // lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
                  local_ipv6_address = builtins.elemAt config.yk8s.terraform.outputs.gateway_ports.value.${name}.all_fixed_ips 1;
                }
            )
            config.yk8s.terraform.outputs.gateways.value;

          masters.hosts =
            lib.mapAttrs (
              name: _:
                {
                  ansible_host = builtins.head config.yk8s.terraform.outputs.master_ports.value.${name}.all_fixed_ips;
                  port_id = config.yk8s.terraform.outputs.master_ports.value.${name}.id;
                  local_ipv4_address = builtins.head config.yk8s.terraform.outputs.master_ports.value.${name}.all_fixed_ips;
                }
                // lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
                  local_ipv6_address = builtins.elemAt config.yk8s.terraform.outputs.master_ports.value.${name}.all_fixed_ips 1;
                }
            )
            config.yk8s.terraform.outputs.masters.value;
          workers.hosts =
            lib.mapAttrs (
              name: _:
                {
                  ansible_host = builtins.head config.yk8s.terraform.outputs.worker_ports.value.${name}.all_fixed_ips;
                  port_id = config.yk8s.terraform.outputs.worker_ports.value.${name}.id;
                  local_ipv4_address = builtins.head config.yk8s.terraform.outputs.worker_ports.value.${name}.all_fixed_ips;
                }
                // lib.optionalAttrs config.yk8s.infra.ipv6_enabled {
                  local_ipv6_address = builtins.elemAt config.yk8s.terraform.outputs.worker_ports.value.${name}.all_fixed_ips 1;
                }
            )
            config.yk8s.terraform.outputs.workers.value;
        };
      };
      ch-k8s-lbaas = {
        subnet_id = config.yk8s.terraform.outputs.subnet_id.value;
        floating_ip_network_id = config.yk8s.terraform.outputs.floating_ip_network_id.value;
      };
    })
  ];
}
