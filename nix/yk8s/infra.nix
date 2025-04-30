{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.infra;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile linkToPath mkYamlAtPath removeAttrsByPath mkInternalOption;
  inherit (yk8s-lib.types) ipv4Cidr ipv4Addr;
in {
  options.yk8s.infra = mkTopSection {
    _docs.preface = ''
      This section contains various configuration options necessary for all
      cluster types, Terraform and bare-metal based.
    '';

    cluster_name = mkOption {
      type = types.nonEmptyStr;
    };

    ipv4_enabled = mkOption {
      description = ''
        If set to true, ipv4 will be used
      '';
      type = types.bool;
      default = true;
    };

    ipv6_enabled = mkOption {
      description = ''
        If set to true, ipv6 will be used
      '';
      type = types.bool;
      default = false;
    };

    subnet_cidr = mkOption {
      type = ipv4Cidr;
      default = "172.30.154.0/24";
    };

    subnet_v6_cidr = mkOption {
      type = types.nonEmptyStr;
      default = "fd00::/120";
    };

    networking_fixed_ip = mkOption {
      type = types.nullOr ipv4Addr;
      default = null;
      apply = v:
        if cfg.ipv4_enabled && v == null
        then
          throw
          "infra.networking_fixed_ip must be set if ipv4 is enabled"
        else v;
    };

    networking_fixed_ip_v6 = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      apply = v:
        if cfg.ipv6_enabled && v == null
        then
          throw
          "infra.networking_fixed_ip_v6 must be set if ipv6 is enabled"
        else v;
    };

    networking_floating_ip = mkOption {
      # TODO: move to yk8s.wireguard when ipsec gets removed
      description = ''
        Address that is used by Wireguard and IPsec to connect to the active gateway node.
      '';
      type = types.nullOr ipv4Addr;
      default = null;
    };

    hosts_file = mkOption {
      description = ''
        A custom hosts file. This option is deprecated. Use :ref:`configuration-options.yk8s.infra.ansible_hosts` instead.
      '';
      type = with types; nullOr pathInStore;
      default = null;
      example = "./hosts";
    };

    ansible_hosts = let
      applyGroupSubmoduleAttrs = lib.mapAttrs (_: lib.filterAttrs (_: a: a != {}));
      groupSubmodule = types.submodule {
        options = {
          children = mkOption {
            type = types.attrsOf groupSubmodule;
            default = {};
            apply = applyGroupSubmoduleAttrs;
          };
          hosts = mkOption {
            type = types.attrs;
            default = {};
          };
          vars = mkOption {
            type = types.attrs;
            default = {};
          };
        };
      };
    in
      mkOption {
        description = ''
          Entries to the Ansible hosts file. Will be rendered to a YAML-based file into the inventory.

          Check the parts regarding YAML in the Ansible documentation: https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
        '';
        default = null;
        apply = applyGroupSubmoduleAttrs;
        type = types.nullOr (types.submodule {
          freeformType = types.attrsOf groupSubmodule;
          options = {
            all.vars.ansible_python_interpreter = mkOption {
              type = types.nonEmptyStr;
              default = "/usr/bin/python3";
            };
            gateways = mkOption {
              type = groupSubmodule;
            };
            masters = mkOption {
              type = groupSubmodule;
            };
            workers = mkOption {
              type = groupSubmodule;
              default = {};
            };
            orchestrator = mkOption {
              type = groupSubmodule;
              default = {
                hosts.localhost = {
                  ansible_connection = "local";
                  ansible_python_interpreter = "{{ ansible_playbook_python }}";
                };
              };
            };
          };
        });
      };

    final_hosts = mkInternalOption {
      description = ''
        Internal read-only option to access all hosts and their effective attributes available to Ansible.
        Each host gets the additional attribute ``group_names`` which is a list of all Ansible groups to which the host belongs.
      '';
      readOnly = true;
      type = with types; nullOr attrs;
      default =
        if cfg.ansible_hosts == null
        then null
        else let
          getHostsFromGroupAttrs = lib.foldlAttrs (
            acc: groupName: groupValues: let
              hosts = lib.recursiveUpdate (getHostsFromGroupAttrs (groupValues.children or {})) (groupValues.hosts or {});
            in
              lib.recursiveUpdate acc (lib.mapAttrs (
                  hostName: hostValues: hostValues // {group_names = (hostValues.group_names or []) ++ [groupName];}
                )
                hosts)
          ) {};
        in
          getHostsFromGroupAttrs cfg.ansible_hosts;
    };
  };

  config.yk8s.infra.ansible_hosts = {
    frontend.children = lib.mkDefault {
      gateways = {};
    };

    k8s_nodes.children = lib.mkDefault {
      masters = {};
      workers = {};
    };
  };

  config.yk8s.assertions = [
    {
      assertion = (config.yk8s.wireguard.enabled || config.yk8s.ipsec.enabled) -> config.yk8s.terraform.enabled || cfg.networking_floating_ip != null;
      message = "infra.networking_floating_ip must be set if Wireguard or IPsec is used.";
    }
    {
      assertion = cfg.ansible_hosts != null -> cfg.hosts_file == null;
      message = "infra.hosts_file must not be set if infra.ansible_hosts is used (which implicitly happens through Terraform).";
    }
  ];
  config.yk8s.warnings = lib.optional (cfg.hosts_file != null) "infra.hosts_file is deprecated. Use infra.ansible_hosts instead.";
  config.yk8s._targets.ansible.inventory_packages = [
    (
      if (cfg.ansible_hosts != null)
      then
        (
          mkYamlAtPath "hosts" cfg.ansible_hosts
        )
      else (linkToPath cfg.hosts_file "hosts")
    )
    (mkGroupVarsFile {
      cfg = removeAttrsByPath cfg [["hosts_file"] ["ansible_hosts"]];
      inventory_path = "all/infra.yaml";
      transformations = [(lib.attrsets.filterAttrs (n: _: n != "hosts_file"))];
    })
  ];
}
