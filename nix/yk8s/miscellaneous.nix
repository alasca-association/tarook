{
  config,
  pkgs,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.miscellaneous;
  modules-lib = import ./lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRemovedOptionModule;
  inherit (pkgs.stdenv) mkDerivation;
  inherit (lib) mkEnableOption mkOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile linkToPath;
  inherit (yk8s-lib.types) ipv4Cidr;
in {
  imports = [
    (mkRemovedOptionModule "miscellaneous" "ingress_whitelisting" "")
    (mkRemovedOptionModule "miscellaneous" "container_runtime" "")
    (mkRemovedOptionModule "miscellaneous" "pip_mirror_url" "")
  ];
  options.yk8s.miscellaneous = mkTopSection {
    _docs.preface = ''
      This section contains various configuration options for special use
      cases. You won’t need to enable and adjust any of these under normal
      circumstances.
    '';

    wireguard_on_workers = mkEnableOption ''
      to install wireguard on all workers (without setting up any server-side stuff)
      so that it can be used from within Pods.
    '';

    cluster_behind_proxy = mkEnableOption ''
      the cluster will be placed behind a HTTP proxy.
      If unconfigured images will be used to setup the cluster, the updates of
      package sources, the download of docker images and the initial cluster setup will fail.
      NOTE: These chances are currently only tested for Debian-based operating systems and not for RHEL-based!
    '';

    haproxy_frontend_k8s_api_maxconn = mkOption {
      type = types.ints.positive;
      default = 2000;
    };

    haproxy_frontend_nodeport_maxconn = mkOption {
      type = types.ints.positive;
      default = 2000;
    };

    http_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the no_proxy config entry
        Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "http://proxy.example.com:8889";
    };
    https_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the no_proxy config entry
        Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "https://proxy.example.com:8889";
    };
    no_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the no_proxy config entry
        Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "localhost,127.0.0.0/8";
    };
    openstack_network_name = mkOption {
      description = ''
        Name of the internal OpenStack network. This field becomes important if a VM is
        attached to two networks but the controller-manager should only pick up one. If
        you don't understand the purpose of this field, there's a very high chance you
        won't need to touch it/uncomment it.
        Note: This network name isn't fetched automagically (by terraform) on purpose
        because there might be situations where the CCM should not pick the managed network.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = "\${config.yk8s.terraform.cluster_name}-network";
    };
    openstack_connect_use_helm = mkOption {
      description = ''
        Use the helm chart to deploy the CCM and the cinder csi plugin.
        If openstack_connect_use_helm is false the deployment will be done with the help
        of the deprecated manifest code.
        This will be enforced for clusters with Kubernetes >= v1.29 and
        the deprecated manifest code will be dropped along with Kubernetes v1.28
      '';
      type = types.bool;
      default = true;
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
    docker_registry_mirrors = mkOption {
      description = ''
        Custom Docker Configuration
        A list of registry mirrors can be configured as a pull through cache to reduce
        external network traffic and the amount of docker pulls from dockerhub.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
      example = ["https://0.docker-mirror.example.org" "https://1.docker-mirror.example.org"];
    };
    docker_insecure_registries = mkOption {
      description = ''
        Custom Docker Configuration
        A list of insecure registries that can be accessed without TLS verification.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
      example = ["0.docker-registry.example.org" "1.docker-registry.example.org"];
    };
    container_mirror_default_host = mkOption {
      type = types.nonEmptyStr;
      default = "install-node";
    };
    container_mirrors = mkOption {
      # TODO: type could be just listOf attrs in case we dont want to typecheck the whole set
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.nonEmptyStr;
          };
          upstream = mkOption {
            type = types.nonEmptyStr;
          };
          port = mkOption {
            type = with types; nullOr port;
            default = null;
          };
          mirrors = mkOption {
            type = with types; listOf nonEmptyStr;
            default = [];
          };
        };
      });
      default = [];
      example = [
        {
          name = "docker.io";
          upstream = "https://registry-1.docker.io/";
          port = 5000;
        }
        {
          name = "gitlab.cloudandheat.com";
          upstream = "https://registry.gitlab.cloudandheat.com/";
          mirrors = ["https://install-node:8000"];
        }
      ];
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
      type = with types; listOf nonEmptyStr;
      default = [];
      example = ["0.pool.ntp.example.org" "1.pool.ntp.example.org"];
    };
    custom_ntp_servers = mkOption {
      description = ''
        A list of NTP servers.
      '';
      type = with types; listOf nonEmptyStr;
      default = [];
      example = ["0.server.ntp.example.org" "1.server.ntp.example.org"];
    };

    check_openstack_credentials = mkOption {
      description = ''
        OpenStack credential checks
        Terrible things will happen when certain tasks are run and OpenStack credentials are not sourced.
        Okay, maybe not so terrible after all, but the templates do not check if certain values exist.
        Hence config files with empty credentials are written. The LCM will execute a simple check to see
        if you provided valid credentials as a sanity check iff you're on openstack and the flag below is set
        to True.
      '';
      type = types.bool;
      default = true;
    };

    apt_proxy_url = mkOption {
      description = ''
        APT Proxy Configuration
        As a secondary effect, https repositories are not used, since
        those don't work with caching proxies like apt-cacher-ng.
      '';
      type = with types; nullOr nonEmptyStr;
      default = null;
    };

    subnet_cidr = mkOption {
      description = ''
        In case it is not set via terraform
      '';
      type = types.nullOr ipv4Cidr;
      default = null;
      apply = v:
        if v == null && config.yk8s.terraform.enabled == false
        then throw "miscellaneous.subnet_cidr must be set if terraform is disabled"
        else if v != null && config.yk8s.terraform.enabled == true
        then throw "miscellaneous.subnet_cidr mustn't be set if terraform is enabled"
        else v;
    };

    hosts_file = mkOption {
      description = ''
        A custom hosts file in case terraform is disabled
      '';
      type = with types; nullOr pathInStore;
      default = null;
      example = "hosts_file = ./hosts;";
      apply = v:
        if v == null && config.yk8s.terraform.enabled == false
        then throw "miscellaneous.hosts_file must be set if terraform is disabled"
        else if v != null && config.yk8s.terraform.enabled == true
        then throw "miscellaneous.hosts_file mustn't be set if terraform is enabled"
        else v;
    };
  };
  config.yk8s.assertions = [
    {
      assertion = cfg.cluster_behind_proxy -> cfg.http_proxy != null;
      message = "miscellaneous.http_proxy must be set if miscellaneous.cluster_behind_proxy is true";
    }
    {
      assertion = cfg.cluster_behind_proxy -> cfg.https_proxy != null;
      message = "miscellaneous.https_proxy must be set if miscellaneous.cluster_behind_proxy is true";
    }
    {
      assertion = cfg.cluster_behind_proxy -> cfg.no_proxy != null;
      message = "miscellaneous.no_proxy must be set if miscellaneous.cluster_behind_proxy is true";
    }
  ];
  config.yk8s._inventory_packages =
    [
      (mkGroupVarsFile {
        inherit cfg;
        inventory_path = "all/miscellaneous.yaml";
        transformations = [(lib.attrsets.filterAttrs (n: _: n != "hosts_file"))];
      })
    ]
    ++ lib.optional (cfg.hosts_file != null)
    (linkToPath cfg.hosts_file "hosts");
}
