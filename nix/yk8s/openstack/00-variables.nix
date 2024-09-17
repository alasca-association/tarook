{lib, ...}: {
  options = {
    vars = lib.mkOption {
      description = ''
        Variables passed in by the Nix module
      '';
      type = lib.types.attrs;
    };
    nodes_prefix = lib.mkOption {
      type = lib.types.str;
      default =
        if config.var.cluster_name == ""
        then ""
        else "${config.var.cluster_name}-";
    };
  };
}
