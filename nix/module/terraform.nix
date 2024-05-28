{
  config,
  lib,
  ...
}: let
  cfg = config.yk8s.terraform;
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.yk8s._lib) mkTopSection;
  inherit (config.yk8s._lib.types) ipv4Cidr;
in {
  options.yk8s.terraform = mkTopSection {
    prevent_disruption = mkOption {
      description = ''
        If true, prevent Terraform from performing disruptive action
        defaults to true if unset
      ''
      ;
      type = types.bool;
      default = true;
    };
    subnet_cidr = mkOption {
      type = ipv4Cidr;
      
    };
    masters = mkOption {
      type = types.int;
    };
    
    workers = mkOption {
      type = types.int;
    };

    master_flavors = mkOption {
      type = with types; listOf str;
    };
    worker_flavors = mkOption {
      type = with types; listOf str;
    };
    enable_az_management = mkEnableOption ''
      if set to true one must set proper values for the "azs" array according to the cloud in use
    '';
    azs = mkOption {
      type = with types; listOf str;
    };

    dualstack_support = mkEnableOption ''
      Enable DualStack support
      WARNING: DualStack support is not stable yet, see https://gitlab.com/yaook/k8s/-/issues/502
    '';
    subnet_v6_cidr = mkOption {
      description = ''
        If you enabled DualStack-support you may want to adjust the IPv6 subnet      
      '';
      type = str; # TODO ipv6cidr type
    };
    create_root_disk_on_volume = mkEnableOption ''
      If true, create block volume for each instance and boot from there.
      Equivalent to `openstack server create --boot-from-volume […].    
    '';
    root_disk_volume_type = mkOption {
      description = ''
        Volume type that is used if `create_root_disk_on_volume` is true.
      '';
      type = types.str;
      default = "three_times_replicated";
    };
    gitlab_backend = mkEnableOption ''
      Enable GitLab-managed Terraform backend
      If true, the Terraform state will be stored inside the provided gitlab project.
      If set, the environment variables `TF_HTTP_USERNAME` and `TF_HTTP_PASSWORD`
      must be configured in a separate file `~/.config/yaook-k8s/env`.
    '';
    gitlab_base_url = mkOption {
      description = ''
        The base URL of your GitLab project.
      '';
      type = types.str;
      default = "https://gitlab.com";
    };
    
    gitlab_project_id = mkOption {
      description = ''
        The unique ID of your GitLab project.
      '';
      type = types.str;
    };
    gitlab_state_name = mkOption {
      description = ''
        The name of the Gitlab state object in which to store the Terraform state, e.g. 'tf-state'      '';
      type = types.str;
      default = "tf-state";
    };




  };
  config.yk8s.terraform = {
    # _variable_transformation # TODO use terraform helper
  };
}
