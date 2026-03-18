{
  options,
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.infra;
  opts = options.yk8s.infra;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkDisableOption linkToPath mkYamlAtPath mkInternalOption types;
  inherit (yk8s-lib.transform) filterNull;
  inherit (lib) mkEnableOption mkOption;
in {
  imports = [
    (mkRemovedOptionModule ["infra" "hosts_file"] "Use infra.ansible_hosts instead")
  ];

  options.yk8s.infra = mkTopSection {
    _docs.preface = ''
      This section contains various configuration options necessary for all
      cluster types, Terraform and bare-metal based.
    '';

    cluster_name = mkOption {
      # NOTE: empty or spaced strings must never by accepted here
      type = types.yk8s.k8s.clusterName;
      description = ''
        Name of the cluster that is to be build and managed.

        Used to distinguish the cluster from others
        and to name harbour infrastructure resources.
      '';
    };

    ipv4_enabled = mkDisableOption "IPv4";

    ipv6_enabled = mkEnableOption "IPv6";

    subnet_cidr = mkOption {
      type = types.yk8s.networking.ipv4Cidr;
      default = "172.30.154.0/24";
      description = ''
        The IPv4 CIDR of the internally used network.
        Only applies if :ref:`configuration-options.yk8s.infra.ipv4_enabled` is set to ``true``.
      '';
      apply = v:
        if ! cfg.ipv4_enabled
        then null
        else v;
    };

    subnet_v6_cidr = mkOption {
      type = types.yk8s.networking.ipv6Cidr;
      default = "fd00::/120";
      description = ''
        The IPv6 CIDR of the internally used network.
        Only applies if :ref:`configuration-options.yk8s.infra.ipv6_enabled` is set to ``true``.
      '';
      apply = v:
        if ! cfg.ipv6_enabled
        then null
        else v;
    };

    networking_fixed_ip = mkOption {
      type = with types; nullOr yk8s.networking.ipv4Addr;
      default = null;
    };

    networking_fixed_ip_v6 = mkOption {
      type = with types; nullOr yk8s.networking.ipv6Addr;
      default = null;
    };

    networking_floating_ip = mkInternalOption {
      # TODO: move to yk8s.wireguard when ipsec gets removed
      description = ''
        Address that is used by Wireguard and IPsec to connect to the active gateway node.
      '';
      type = with types; nullOr yk8s.networking.ipv4Addr;
      default = null;
    };

    ansible_hosts = let
      hostsSubmodule = types.submodule {
        freeformType = types.yk8s.formats.jsonValue;
        options = {
          ansible_host = mkOption {
            type = with types; with types.yk8s.networking; nullOr (oneOf [ipv4Addr ipv6Addr subdomainName]);
            default = null;
          };
          local_ipv4_address = mkOption {
            type = with types; nullOr yk8s.networking.ipv4Addr;
            default = null;
          };
          local_ipv6_address = mkOption {
            type = with types; nullOr yk8s.networking.ipv6Addr;
            default = null;
          };
        };
      };
      groupSubmodule = types.submodule {
        options = {
          children = mkOption {
            visible = "shallow"; # Otherwise renderDocs chokes on the recursive submodule
            type = types.attrsOf groupSubmodule;
            default = {};
          };
          hosts = mkOption {
            type = types.attrsOf hostsSubmodule;
            default = {};
          };
          vars = mkOption {
            type = with types; attrsOf yk8s.formats.jsonValue;
            default = {};
          };
        };
      };
    in
      mkOption {
        description = ''
          Entries to the Ansible hosts file. Will be rendered to a YAML-based file into the inventory.
          This option is mandatory for bare-metal clusters and is automatically managed if Terraform is used.

          Migrating from ``yk8s.infra.hosts_file``
          """"""""""""""""""""""""""""""""""""""""

          Bare-metal clusters which previously used a self-managed ini-based inventory file
          must migrate their inventory file and either configure the Ansible hosts directly in their configuration
          or migrate the ini-based file to a YAML- or JSON-based file
          and then import that file in their configuration.

          It is recommended to configure the Ansible hosts directly in the configuration
          via the suboptions listed below.

          However, the following gives a baseline for the conversion:

          1. Convert the ini-based host file to YAML

             .. code::

                ansible-inventory -i <PATH_TO_CURRENT_HOSTS_FILE> --yaml --list --export --output config/hosts.yaml

          2. Edit the file structure of ``config/hosts.yaml``
             such that the file can be properly imported into the configuration.
             It must follow the structure of this example:

             .. code:: yaml

                frontend:
                  children:
                    masters: {}
                masters:
                  hosts:
                    example-master-0:
                      ansible_host: 192.0.2.10
                      local_ipv4_address: 192.0.2.10
                    example-master-1:
                      ansible_host: 192.0.2.11
                      local_ipv4_address: 192.0.2.11
                    example-master-2:
                      ansible_host: 192.0.2.12
                      local_ipv4_address: 192.0.2.12
                workers:
                  hosts:
                    example-worker-0:
                      ansible_host: 192.0.2.20
                      local_ipv4_address: 192.0.2.20
                    example-worker-1:
                      ansible_host: 192.0.2.21
                      local_ipv4_address: 192.0.2.21
                    example-worker-2:
                      ansible_host: 192.0.2.22
                      local_ipv4_address: 192.0.2.22
                # NOTE: Since this block matches Tarook's default,
                #       it can be omitted.
                orchestrator:
                  hosts:
                    localhost:
                      ansible_connection: local
                      ansible_python_interpreter: '{{ ansible_playbook_python }}'
                # NOTE: Since this block matches Tarook's default,
                #       it can be omitted.
                all:
                  vars:
                    ansible_python_interpreter: /usr/bin/python3


          3. You may then set ``yk8s.infra.ansible_hosts = yk8s-lib.importYAML ./hosts.yaml;``
             to import the file in your configuration.

             .. attention::

                The file has to be added to the git repository in order to be evaluated by Nix.

          Check the parts regarding YAML in the Ansible documentation: https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
        '';
        type = types.submodule {
          freeformType = types.attrsOf groupSubmodule;
          options = {
            all.vars.ansible_python_interpreter = mkOption {
              type = types.yk8s.posix.absolutePath;
              default = "/usr/bin/python3";
            };
            frontend = mkOption {
              visible = "shallow"; # Otherwise the submodule's options are repeated here
              type = groupSubmodule;
              default = {children.gateways = {};};
              example = {children.masters = {};};
            };
            gateways = mkOption {
              visible = "shallow"; # Otherwise the submodule's options are repeated here
              type = groupSubmodule;
              default = {};
            };
            k8s_nodes = mkInternalOption {
              readOnly = true;
              type = groupSubmodule;
              default = {
                children = {
                  masters = {};
                  workers = {};
                };
              };
            };
            masters = mkOption {
              visible = "shallow"; # Otherwise the submodule's options are repeated here
              type = groupSubmodule;
              example = {
                hosts = {
                  devcluster-master-1 = {
                    ansible_host = "172.30.154.66";
                    local_ipv4_address = "172.30.154.66";
                  };
                };
              };
            };
            workers = mkOption {
              visible = "shallow"; # Otherwise the submodule's options are repeated here
              type = groupSubmodule;
              default = {};
              example = {
                hosts = {
                  devcluster-worker-1 = {
                    ansible_host = "172.30.154.99";
                    local_ipv4_address = "172.30.154.99";
                  };
                };
              };
            };
            orchestrator = mkOption {
              visible = "shallow"; # Otherwise the submodule's options are repeated here
              type = groupSubmodule;
              default = {
                hosts.localhost = {
                  ansible_connection = "local";
                  ansible_python_interpreter = "{{ ansible_playbook_python }}";
                };
              };
            };
          };
        };
      };

    final_hosts = mkInternalOption {
      description = ''
        Internal read-only option to access all hosts and their effective attributes available to Ansible.
        Each host gets the following additional attributes
        * ``group_names``: A list of all Ansible groups to which the host belongs
        * ``role``: One of ``master``, ``worker``, ``gateway`` or ``null``
      '';
      readOnly = true;
      type = types.attrs;
      default = let
        getHostsFromGroupAttrs = lib.foldlAttrs (
          acc: groupName: groupValues: let
            hosts = lib.recursiveUpdate (getHostsFromGroupAttrs (
              lib.filterAttrs (n: _: builtins.elem n (builtins.attrNames (groupValues.children or {}))) cfg.ansible_hosts
            )) (groupValues.hosts or {});
          in
            lib.recursiveUpdate acc (lib.mapAttrs (
                hostName: hostValues:
                  hostValues
                  // rec {
                    group_names = lib.unique ((lib.attrByPath [hostName "group_names"] [] acc) ++ [groupName]);
                    role = let
                      relevantGroups = lib.intersectLists group_names ["masters" "workers" "gateways"];
                    in
                      assert lib.assertMsg ((builtins.length relevantGroups) <= 1) "${hostName} has more than one role assigned. Nodes can only be one of master, worker or gateway";
                        if relevantGroups == []
                        then null
                        else lib.strings.removeSuffix "s" (builtins.head relevantGroups);
                  }
              )
              hosts)
        ) {};
        allHosts = getHostsFromGroupAttrs cfg.ansible_hosts;
        groupNames = lib.pipe allHosts [builtins.attrValues (map (v: v.group_names)) lib.flatten lib.unique];
        allGroups = builtins.foldl' lib.recursiveUpdate cfg.ansible_hosts ([{all.hosts = allHosts;}]
          ++ (map (group: {
              ${group} = {
                children = cfg.ansible_hosts.${group}.children or {};
                vars = cfg.ansible_hosts.${group}.vars or {};
                hosts = lib.filterAttrs (_: v: builtins.elem group v.group_names) allHosts;
              };
            })
            groupNames));
        populateChildren = groupName: groupValues:
          groupValues
          // {children = lib.mapAttrs (childName: _: allGroups.${childName}) (groupValues.children or {});};
      in
        lib.mapAttrs populateChildren allGroups;
    };
  };

  config.yk8s._targets.ansible.assertions = [
    {
      assertion = (cfg.ansible_hosts.orchestrator.children or {}) == {} && (builtins.length (builtins.attrNames cfg.ansible_hosts.orchestrator.hosts)) == 1;
      message = "config.yk8s.infra.ansible_hosts.orchestrator must contain exactly one host and no children";
    }
    {
      assertion = (config.yk8s.wireguard.enabled || config.yk8s.ipsec.enabled) -> config.yk8s.terraform.enabled || cfg.networking_floating_ip != null;
      message = "config.yk8s.infra.networking_floating_ip must be set if Wireguard or IPsec is used.";
    }
    {
      assertion = builtins.all (host: (host.ansible_connection or "") != "local" -> host.ansible_host != null) (builtins.attrValues cfg.final_hosts.all.hosts);
      message = "ansible_host must be set for all hosts in config.yk8s.infra.ansible_hosts if ansible_connection!=local";
    }
    {
      assertion =
        cfg.ipv4_enabled
        -> builtins.all (host: host.local_ipv4_address != null) (builtins.attrValues cfg.final_hosts.k8s_nodes.hosts);
      message = "local_ipv4_address must be set for all hosts in config.yk8s.infra.ansible_hosts.k8s_nodes";
    }
    {
      assertion =
        cfg.ipv6_enabled
        -> builtins.all (host: host.local_ipv6_address != null) (builtins.attrValues cfg.final_hosts.k8s_nodes.hosts);
      message = "local_ipv6_address must be set for all hosts in config.yk8s.infra.ansible_hosts.k8s_nodes";
    }
    {
      assertion = cfg.ipv4_enabled -> (cfg.networking_fixed_ip != null);
      message = "config.yk8s.infra.networking_fixed_ip: must be set if config.yk8s.infra.ipv4_enabled=true";
    }
    {
      assertion = cfg.ipv6_enabled -> (cfg.networking_fixed_ip_v6 != null);
      message = "config.yk8s.infra.networking_fixed_ip_v6: must be set if config.yk8s.infra.ipv6_enabled=true";
    }
    (let
      hostnames = lib.attrNames cfg.final_hosts.all.hosts;
      check = v: (types.yk8s.k8s.objectName.check v) && (types.yk8s.networking.subdomainName.check v);
      invalidHostnames = lib.filter (n: !check n) hostnames;
    in {
      assertion = lib.all check hostnames;
      message = "yk8s.infra.ansible_hosts: The following hostnames contain invalid characters:\n" + lib.concatLines (map (n: "  * ${n}") invalidHostnames);
    })
  ];
  config.yk8s._targets.ansible.warnings =
    []
    # Produce warning if option is used when ipv4_enabled=false
    ++ lib.optional (
      (! cfg.ipv4_enabled) && (opts.subnet_cidr.highestPrio < 1500) # priority of option defaults
    )
    "config.yk8s.infra.subnet_cidr: is ignored because yk8s.infra.ipv4_enabled=false"
    # Produce warning if option is used when ipv6_enabled=false
    ++ lib.optional (
      (! cfg.ipv6_enabled) && (opts.subnet_v6_cidr.highestPrio < 1500) # priority of option defaults
    )
    "config.yk8s.infra.subnet_v6_cidr: is ignored because yk8s.infra.ipv6_enabled=false";
  config.yk8s._targets.ansible.inventory_packages = let
    trimEmptySubmoduleAttrs = lib.mapAttrs (_: submodule:
      lib.pipe submodule [
        (lib.filterAttrs (_: v: v != {}))
        (lib.mapAttrs (
          n: v:
            if n == "children"
            then trimEmptySubmoduleAttrs v
            else v
        ))
      ]);
  in [
    (mkYamlAtPath "hosts" (lib.pipe cfg.ansible_hosts [trimEmptySubmoduleAttrs filterNull]))
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/infra.yaml";
      transformations = [(c: removeAttrs c ["ansible_hosts" "final_hosts"])];
    })
  ];
}
