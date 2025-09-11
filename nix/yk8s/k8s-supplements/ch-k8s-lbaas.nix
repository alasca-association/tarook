{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.ch-k8s-lbaas;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedResourceOptionModule mkResourceOptionModule;
  inherit (lib) mkOption mkEnableOption types;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkResourceOption mkDisableOption;
  inherit
    (yk8s-lib.types)
    base64Str
    httpHostUrl
    httpxHostPathUrl
    ipv4Addr
    k8sImageRef
    ociImageTag
    posixUserName
    ;
  inherit
    (yk8s-lib.transform)
    warnIfZero
    ;
in {
  imports = [
    (mkRenamedResourceOptionModule ["ch-k8s-lbaas"] ["controller"])
    (mkResourceOptionModule ["ch-k8s-lbaas"] ["controller_resources"] {
      description = "Request and limit for the LBaaS controller";
      cpu.request = "100m";
      memory.limit = "256Mi";
    })
  ];

  options.yk8s.ch-k8s-lbaas = mkTopSection {
    enabled = mkEnableOption "our LBaas service";
    shared_secret = mkOption {
      description = ''
        A unique, random, base64-encoded secret.
        To generate such a secret, you can use the following command:
        $ dd if=/dev/urandom bs=16 count=1 status=none | base64
      '';
      # type as per https://pkg.go.dev/encoding/base64#StdEncoding
      #  (ch-k8s-lbaas uses that library)
      type = base64Str;
      example = "Example+NZHrRAV9AAN83T7Hc6wVk9IGzPou6UjwWhL+4hu1I4XPj+YG/AgKiFIc1a1EzmQKax9VAj6P/oA45w==";
    };
    version = mkOption {
      type = ociImageTag;
      default = "0.9.0";
      # NOTE: constrained to >= 0.8.0 by assertion (due to OVN support)
    };
    agent_port = mkOption {
      description = ''
        The TCP port on which the LBaaS agent should listen on the frontend nodes.
      '';
      type = types.port;
      default = 15203;
      apply = v:
        warnIfZero "config.yk8s.ch-k8s-lbaas.agent_port: should not be port zero" v;
    };
    port_manager = mkOption {
      description = ''
        Configure which IP address ("port") manager to use. Two options are available:

        * openstack: Uses OpenStack and the Tarook gateway nodes to provision
          LBaaS IP addresses ports.
        * static: Uses a fixed set of IP addresses to use for load balancing. When the
          static port manager is used,
          :ref:`configuration-options.yk8s.ch-k8s-lbaas.agent_urls`
          and
          :ref:`configuration-options.yk8s.ch-k8s-lbaas.static_ipv4_addresses`
          must be set as well.
      '';
      type = types.enum [
        "openstack"
        "static"
      ];
      default = "openstack";
    };
    static_ipv4_addresses = mkOption {
      description = ''
        List of IPv4 addresses which are usable for the static port manager. It is
        your responsibility to ensure that the node(s) which run the agent(s) receive
        traffic for these IPv4 addresses.
      '';
      default = [];
      type = types.listOf ipv4Addr;
      apply = v:
        if v == [] && cfg.port_manager == "static"
        then throw "config.yk8s.ch-k8s-lbaas.static_ipv4_addresses: must not be empty when config.yk8s.ch-k8s-lbaas.port_manager='static'"
        else v;
    };
    agent_urls = mkOption {
      description = ''
        Customize URLs for the agents. This will typically be a list of HTTP URLs
        like http://agent_ip:15203. This option must be set if :ref:`configuration-options.yk8s.ch-k8s-lbaas.port_manager` is
        set to ``static`` and is ignored otherwise.
      '';
      default = [];
      # NOTE: ch-k8s-lbaas ignores the HTTP URL path, its agents don't support TLS
      type = types.listOf httpHostUrl;
      apply = v:
        if v == [] && cfg.port_manager == "static"
        then throw "config.yk8s.ch-k8s-lbaas.agent_urls: must not be empty when config.yk8s.ch-k8s-lbaas.port_manager='static'"
        else v;
    };
    use_floating_ips = mkDisableOption "the use of floating IPs";
    controller_repo = mkOption {
      type = k8sImageRef;
      default = "registry.gitlab.com/yaook/ch-k8s-lbaas/controller";
    };
    agent_user = mkOption {
      type = posixUserName;
      default = "ch-k8s-lbaas-agent";
    };
    agent_source = mkOption {
      # NOTE: the URL path is appended to, therefore query and fragment are disallowed
      type = httpxHostPathUrl;
      default = "https://github.com/cloudandheat/ch-k8s-lbaas/releases/download";
    };
    use_bgp = mkOption {
      type = types.bool;
      default = config.yk8s.kubernetes.network.calico.enabled;
    };
  };
  config.yk8s.assertions = [
    # Due to OVN support, require version >= 0.8.0 (warn only if not in semver2 format)
    (
      let
        inherit (builtins) elemAt match typeOf;
        inherit (lib.strings) toInt;
        semver2RE = lib.concatStrings [
          "(0|[1-9][0-9]*)" # major
          "[.]"
          "(0|[1-9][0-9]*)" # minor
          "[.]"
          "(0|[1-9][0-9]*)" # patch
          # optional pre-release
          "(-("
          "(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)"
          "([.](0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*"
          "))?"
          # build metadata
          "([+]([0-9a-zA-Z-]+([.][0-9a-zA-Z-]+)*))?"
        ];
      in let
        cfg_version = cfg.version;
        matches = match semver2RE cfg_version;
        isSemver2 =
          if typeOf matches == "list"
          then true
          else false;
      in {
        assertion =
          if isSemver2
          then
            ! (
              (toInt (elemAt matches 0) <= 0)
              && (toInt (elemAt matches 1) < 8)
            )
          else
            lib.warn ''
              config.yk8s.ch-k8s-lbaas.version: not in semver2 format
                                                Please make sure that '${cfg_version}' has a version level of at least 0.8.0.
            ''
            true;
        message = "config.yk8s.ch-k8s-lbaas.version: must be at least 0.8.0";
      }
    )
  ];
  config.yk8s._inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "ch_k8s_lbaas_";
      inventory_path = "all/ch-k8s-lbaas.yaml";
      only_if_enabled = true;
    })
  ];
}
