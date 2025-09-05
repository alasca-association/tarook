{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.miscellaneous;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule mkRenamedOptionModule;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib) mkEnableOption mkOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile linkToPath types;
  inherit
    (yk8s-lib.transform)
    ignoreItemsOfDisabledIPFamily
    ;
in {
  imports = [
    (mkRemovedOptionModule ["miscellaneous" "ingress_whitelisting"] "")
    (mkRemovedOptionModule ["miscellaneous" "container_runtime"] "")
    (mkRemovedOptionModule ["miscellaneous" "pip_mirror_url"] "")
    (mkRenamedOptionModule ["miscellaneous" "ipv4_enabled"] ["infra" "ipv4_enabled"])
    (mkRenamedOptionModule ["miscellaneous" "ipv6_enabled"] ["infra" "ipv6_enabled"])
    (mkRenamedOptionModule ["miscellaneous" "subnet_v6_cidr"] ["infra" "subnet_v6_cidr"])
    (mkRenamedOptionModule ["miscellaneous" "subnet_cidr"] ["infra" "subnet_cidr"])
    (mkRenamedOptionModule ["miscellaneous" "networking_fixed_ip"] ["infra" "networking_fixed_ip"])
    (mkRenamedOptionModule ["miscellaneous" "networking_fixed_ip_v6"] ["infra" "networking_fixed_ip_v6"])
    (mkRenamedOptionModule ["miscellaneous" "hosts_file"] ["infra" "hosts_file"])
    (mkRenamedOptionModule ["miscellaneous" "k8s_network_ipv4_nat_outgoing"] ["kubernetes" "network" "ipv4_nat_outgoing"])
    (mkRenamedOptionModule ["miscellaneous" "k8s_network_ipv6_nat_outgoing"] ["kubernetes" "network" "ipv6_nat_outgoing"])
    (mkRemovedOptionModule ["miscellaneous" "openstack_connect_use_helm"] "Helm is now always used to deploy the CCM and the cinder CSI plugin")
    (mkRenamedOptionModule ["miscellaneous" "openstack_network_name"] ["openstack" "network_name"])
    (mkRenamedOptionModule ["miscellaneous" "openstack_cinder_volume_type"] ["openstack" "cinder_volume_type"])
    (mkRenamedOptionModule ["miscellaneous" "check_openstack_credentials"] ["openstack" "check_credentials"])
    (mkRenamedOptionModule ["miscellaneous" "haproxy_frontend_nodeport_maxconn"] ["load-balancing" "haproxy_frontend_nodeport_maxconn"])
    (mkRenamedOptionModule ["miscellaneous" "haproxy_frontend_k8s_api_maxconn"] ["load-balancing" "haproxy_frontend_k8s_api_maxconn"])
    (mkRemovedOptionModule ["miscellaneous" "docker_registry_mirrors"] "Use containerd.mirrors instead")
    (mkRemovedOptionModule ["miscellaneous" "docker_insecure_registries"] "Use containerd.mirrors instead")
    (mkRemovedOptionModule ["miscellaneous" "container_mirror_default_host"] "Use containerd.mirrors instead")
    (mkRemovedOptionModule ["miscellaneous" "container_mirrors"] "Use containerd.mirrors instead")
    (mkRemovedOptionModule ["miscellaneous" "wireguard_on_workers"] "")
  ];
  options.yk8s.miscellaneous = mkTopSection {
    _docs.preface = ''
      This section contains various configuration options for special use
      cases. You won’t need to enable and adjust any of these under normal
      circumstances.
    '';

    cluster_behind_proxy = mkEnableOption ''
      the cluster will be placed behind a HTTP proxy.
      If unconfigured images will be used to setup the cluster, the updates of
      package sources, the download of docker images and the initial cluster setup will fail.
      NOTE: These chances are currently only tested for Debian-based operating systems and not for RHEL-based!
    '';

    http_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
        Important note: Settings for the Tarook cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr yk8s.networking.httpHostPathUrl;
      default = null;
      example = "http://proxy.example.com:8889";
    };
    https_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
        Important note: Settings for the Tarook cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr yk8s.networking.httpsHostPathUrl;
      default = null;
      example = "https://proxy.example.com:8889";
    };
    no_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the :ref:`configuration-options.yk8s.miscellaneous.no_proxy` config entry
        Important note: Settings for the Tarook cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr (listOf (oneOf [yk8s.networking.ipv4Addr yk8s.networking.ipv4Cidr yk8s.networking.subdomainName]));
      default = [];
      example = ["localhost" "127.0.0.0/8"];
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Cidr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
        }
        "config.yk8s.miscellaneous.no_proxy: "
        v;
    };
    vm_max_map_count = mkOption {
      description = ''
        Value for the kernel parameter `vm.max_map_count` on k8s nodes. Modifications
        might be required depending on the software running on the nodes (e.g., ElasticSearch).
        If you leave the value commented out you're fine and the system's default will be kept.
      '';
      type = types.int;
      default = 262144;
    };
    custom_chrony_configuration = mkEnableOption ''
      custom Chrony configration
      The ntp servers used by chrony can be customized if it should be necessary or wanted.
      A list of pools and/or servers can be specified.
      Chrony treats both similarily but it expects that a pool will resolve to several ntp servers.
    '';
    custom_ntp_pools = mkOption {
      description = ''
        A list of NTP pools.
      '';
      type = with types; listOf (oneOf [yk8s.networking.ipv4Addr yk8s.networking.ipv6Addr yk8s.networking.subdomainName]);
      default = [];
      example = ["0.pool.ntp.example.org" "1.pool.ntp.example.org"];
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Addr];
          ipv6Types = [types.yk8s.networking.ipv6Addr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.miscellaneous.custom_ntp_pools: "
        v;
    };
    custom_ntp_servers = mkOption {
      description = ''
        A list of NTP servers.
      '';
      type = with types; listOf (oneOf [yk8s.networking.ipv4Addr yk8s.networking.ipv6Addr yk8s.networking.subdomainName]);
      default = [];
      example = ["0.server.ntp.example.org" "1.server.ntp.example.org"];
      apply = v:
        ignoreItemsOfDisabledIPFamily {
          ipv4Types = [types.yk8s.networking.ipv4Addr];
          ipv6Types = [types.yk8s.networking.ipv6Addr];
          ipv4Enabled = config.yk8s.infra.ipv4_enabled;
          ipv6Enabled = config.yk8s.infra.ipv6_enabled;
        }
        "config.yk8s.miscellaneous.custom_ntp_servers: "
        v;
    };

    apt_proxy_url = mkOption {
      description = ''
        APT Proxy Configuration
        As a secondary effect, https repositories are not used, since
        those don't work with caching proxies like apt-cacher-ng.
      '';
      type = with types; nullOr yk8s.networking.httpHostPathUrl;
      default = null;
    };
  };
  config.yk8s.assertions = [
    {
      assertion = cfg.cluster_behind_proxy -> cfg.http_proxy != null;
      message = "config.yk8s.miscellaneous.http_proxy: must be set because config.yk8s.miscellaneous.cluster_behind_proxy=true";
    }
    {
      assertion = cfg.cluster_behind_proxy -> cfg.https_proxy != null;
      message = "config.yk8s.miscellaneous.https_proxy: must be set because config.yk8s.miscellaneous.cluster_behind_proxy=true";
    }
    {
      assertion = cfg.cluster_behind_proxy -> cfg.no_proxy != null;
      message = "config.yk8s.miscellaneous.no_proxy: must be set because config.yk8s.miscellaneous.cluster_behind_proxy=true";
    }
  ];
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      inventory_path = "all/miscellaneous.yaml";
    })
  ];
}
