{
  config,
  lib,
  yk8s-lib,
  ...
}: let
  cfg = config.yk8s.ch-k8s-lbaas;
  modules-lib = import ../lib/modules.nix {inherit lib;};
  inherit (modules-lib) mkRenamedResourceOptionModule mkResourceOptionModule;
  inherit (lib) mkOption mkEnableOption;
  inherit (yk8s-lib) mkTopSection mkGroupVarsFile mkResourceOption mkDisableOption mkInternalOption types;
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
    _docs.preface = ''
      ``ch-k8s-lbaas`` is a LoadBalancing-solution for clusters running on OpenStack
      as well as clusters running on bare metal.
      Further information about it can be found here: :doc:`/user/explanation/services/ch-k8s-lbaas`.
    '';
    enabled = mkEnableOption "our LBaas service";
    shared_secret = mkOption {
      description = ''
        .. attention:: DEPRECATED

           This option is going to be removed soon
           since the shared secret is now stored in and automatically handled via Vault.

        A unique, random, base64-encoded secret.
        To generate such a secret, you can use the following command:
        $ dd if=/dev/urandom bs=16 count=1 status=none | base64
      '';
      # type as per https://pkg.go.dev/encoding/base64#StdEncoding
      #  (ch-k8s-lbaas uses that library)
      type = types.nullOr types.yk8s.encoding.base64Str;
      example = "Example+NZHrRAV9AAN83T7Hc6wVk9IGzPou6UjwWhL+4hu1I4XPj+YG/AgKiFIc1a1EzmQKax9VAj6P/oA45w==";
      default = null;
    };
    version = mkOption {
      type = types.yk8s.oci.imageTag;
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
      type = with types; listOf yk8s.networking.ipv4Addr;
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
      type = with types; listOf yk8s.networking.httpHostUrl;
      apply = v:
        if v == [] && cfg.port_manager == "static"
        then throw "config.yk8s.ch-k8s-lbaas.agent_urls: must not be empty when config.yk8s.ch-k8s-lbaas.port_manager='static'"
        else v;
    };
    use_floating_ips = mkDisableOption "the use of floating IPs";
    controller_repo = mkOption {
      type = types.yk8s.k8s.imageRef;
      default = "registry.gitlab.com/yaook/ch-k8s-lbaas/controller";
    };
    agent_user = mkOption {
      type = types.yk8s.posix.userName;
      default = "ch-k8s-lbaas-agent";
    };
    agent_source = mkOption {
      # NOTE: the URL path is appended to, therefore query and fragment are disallowed
      type = types.yk8s.networking.httpxHostPathUrl;
      default = "https://github.com/cloudandheat/ch-k8s-lbaas/releases/download";
    };
    use_bgp = mkOption {
      type = types.bool;
      default = config.yk8s.kubernetes.network.calico.enabled;
    };
    enable_snat = mkDisableOption ''
      source-nat'ing by the ch-k8s-lbaas-agents running on the frontend nodes.

      Disabling this has a similar effect as a direct server return.
      It allows to see the real source IP of traffic sent to a LoadBalancer-service.

      After reconfiguring this option, execute the following:

      .. code::

        $ ./managed-k8s/actions/apply-k8s-supplements.sh install-ch-k8s-lbaas.yaml

      to rollout necessary changes.

      Running on OpenStack
      """"""""""""""""""""

      If source-nat'ing is disabled, the frontend nodes will be configured to act as gateway
      for the Kubernetes nodes. They will propagate routes via BGP overwriting the default routes of
      Kubernetes nodes such that **all** traffic is routed via the VIP by default.

      .. important:: Administrative Traffic

        Traffic sent via Wireguard is still SNAT'ed as otherwise
        freshly provisioned nodes can't be administered.

      .. warning:: Implications when running on OpenStack

        Disabling source-nat'ing has some implications:

        1. If a failover occurs on the frontend nodes, **all** connections are impacted,
           not only connections to LoadBalancer-Services.
        2. The source IP of Kubernetes nodes as seen by the outside world changes from
           the OpenStack router IP to the Gateway's VIP.
        3. It's not possible to attach floating IPs to Kubernetes nodes anymore due to
           routing asymmetry.

      Be aware, that the frontend nodes must be potent enough to handle the increased amount of traffic
      if source-nat'ing is disabled, as they could become the bottleneck otherwise'';
    subnet_id = mkInternalOption {
      type = with types; nullOr nonEmptyStr;
      default = null;

      apply = v:
        if config.yk8s.openstack.enabled && v == null
        then throw "ch-k8s-lbaas.subnet_id must be set if openstack is enabled"
        else v;
    };
    floating_ip_network_id = mkInternalOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      apply = v:
        if config.yk8s.openstack.enabled && v == null
        then
          throw
          "ch-k8s-lbaas.floating_ip_network_id must be set if openstack is enabled"
        else v;
    };
  };
  config.yk8s._targets.ansible.warnings =
    [
    ]
    ++ lib.optional (cfg.enabled && cfg.shared_secret != null) ''
      config.yk8s.ch-k8s-lbaas.shared_secret: is deprecated.
      The option will be removed in a future release.

      You have two options:
      a) You want to keep the currently configured shared secret.
         The configured shared secret is automatically moved to Vault on a rollout.
         After a rollout has been done, you can unset this option.
      b) You do not care about the shared secret.
         You can unset this option.
         A shared secret will be automatically generated and stored in Vault on a rollout.
    '';
  config.yk8s._targets.ansible.assertions = [
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
    {
      assertion = (!config.yk8s.openstack.enabled) -> (cfg.subnet_id == null && cfg.floating_ip_network_id == null);
      message = "config.yk8s.ch-k8s-lbaas.subnet_id and config.yk8s.ch-k8s-lbaas.floating_ip_network_id must be null if config.yk8s.openstack.enabled==false";
    }
  ];
  config.yk8s._targets.ansible.inventory_packages = [
    (mkGroupVarsFile {
      inherit cfg;
      ansible_prefix = "ch_k8s_lbaas_";
      inventory_path = "all/ch-k8s-lbaas.yaml";
      only_if_enabled = false;
    })
  ];
}
