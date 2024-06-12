{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.miscellaneous;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
in {
  options.yk8s.miscellaneous = mkTopSection {
    wireguard_on_workers = mkEnableOption ''
      Install wireguard on all workers (without setting up any server-side stuff)
      so that it can be used from within Pods.
    '';
    cluster_behind_proxy = mkEnableOption ''
      Configuration details if the cluster will be placed behind a HTTP proxy.
      If unconfigured images will be used to setup the cluster, the updates of
      package sources, the download of docker images and the initial cluster setup will fail.
      NOTE: These chances are currently only tested for Debian-based operating systems and not for RHEL-based!
    '';
    http_proxy = mkOption {
      description = ''
        Set the approriate HTTP proxy settings for your cluster here. E.g. the address of the proxy or
        internal docker repositories can be added to the no_proxy config entry
        Important note: Settings for the yaook-k8s cluster itself (like the service subnet or the pod subnet)
        will be set automagically and do not have to set manually here.
      '';
      type = with types; nullOr str;
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
      type = with types; nullOr str;
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
      type = with types; nullOr str;
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
      type = types.str;
      default = "managed-k8s-network";
    };
    vm_max_map_count = mkOption {
      description = ''
        Value for the kernel parameter `vm.max_map_count` on k8s worker nodes. Modifications
        might be required depending on the software running on the nodes (e.g., ElasticSearch).
        If you leave the value commented out you're fine and the system's default will be kept.
      '';
      type = types.int;
      default = 262144;
    };
    docker.registry_mirrors = mkOption {
      description = ''
        Custom Docker Configuration
        A list of registry mirrors can be configured as a pull through cache to reduce
        external network traffic and the amount of docker pulls from dockerhub.
      '';
      type = with types; listOf str;
      default = [];
      example = ''
        [ "https://0.docker-mirror.example.org" "https://1.docker-mirror.example.org" ]
      '';
    };
    docker.insecure_registries = mkOption {
      description = ''
        Custom Docker Configuration
        A list of insecure registries that can be accessed without TLS verification.
      '';
      type = with types; listOf str;
      default = [];
      example = ''
        [ "0.docker-registry.example.org" "1.docker-registry.example.org" ]
      '';
    };
    container.mirror_default_host = mkOption {
      type = types.str;
      default = "install-node";
    };
    container.mirrors = mkOption {
      # TODO: type could be just listOf attrs in case we dont want to typecheck the whole set
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
          };
          upstream = mkOption {
            type = types.str;
          };
          port = mkOption {
            type = with types; nullOr port;
            default = null;
          };
          mirrors = mkOption {
            type = with types; listOf str;
            default = [];
          };
        };
      });
      default = [
        {
          name = "docker.io";
          upstream = "https://registry-1.docker.io/";
          port = 5000;
        }
        # TODO: is the following meant as an example instead?
        {
          name = "gitlab.cloudandheat.com";
          upstream = "https://registry.gitlab.cloudandheat.com/";
          mirrors = ["https://install-node:8000"];
        }
      ];
    };
    custom_chrony_configuration = mkEnableOption ''
      Custom Chrony Configration
      The ntp servers used by chrony can be customized if it should be necessary or wanted.
      A list of pools and/or servers can be specified.
      Chrony treats both similarily but it expects that a pool will resolve to several ntp servers.
    '';
    custom_ntp_pools = mkOption {
      description = ''
        A list of NTP pools.
      '';
      type = with types; listOf str;
      default = [];
      example = ''
        [ "0.pool.ntp.example.org", "1.pool.ntp.example.org"]
      '';
    };
    custom_ntp_servers = mkOption {
      description = ''
        A list of NTP servers.
      '';
      type = with types; listOf str;
      default = [];
      example = ''
        [ "0.server.ntp.example.org", "1.server.ntp.example.org"]
      '';
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
      type = with types; nullOr str;
      default = null;
    };

    pip_mirror_url = mkOption {
      description = ''
        Custom PyPI mirror
        Use this in offline setups or to use a pull-through cache for
        accessing the PyPI.
        If the TLS certificate used by the mirror is not signed by a CA in
        certifi, you can put its cert in `config/pip_mirror_ca.pem` to set
        it explicitly.
      '';
      type = with types; nullOr str;
      default = null;
    };
  };
  config.yk8s.miscellaneous = {
    _inventory_path = "all/miscellaneous.yaml";
  };
}
