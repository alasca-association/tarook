{lib}: let
  types = import ./types.nix {inherit lib;};
  transform = import ./transform.nix {inherit lib;};
in rec {
  mkInternalOption = args:
    lib.mkOption ({
        internal = true;
        visible = false;
      }
      // args);
  mkSection = cfg: options: let
    preface =
      if options ? _docs && options._docs ? preface
      then options._docs.preface
      else null;
    order =
      if options ? _docs && options._docs ? order
      then options._docs.order
      else null;
    opts = lib.attrsets.filterAttrs (n: _: n != "_docs") options;
  in ({
      _internal = {
        sectionType = mkInternalOption {
          type = lib.types.str;
          default = cfg.sectionType;
        };
        unflat = mkInternalOption {
          type = with lib.types; listOf str;
          default = [];
        };
        removedOptions = mkInternalOption {
          type = with lib.types; listOf (listOf str);
          default = [];
        };
        docs.preface = mkInternalOption {
          description = preface; # we're misusing the description here to expose the text to the docs renderer
          type = lib.types.str;
          default = "";
        };
        docs.order = mkInternalOption {
          type = with lib.types; nullOr int;
          default = order;
        };
      };
    }
    // opts);
  mkTopSection = mkSection {sectionType = "top";};
  mkSubSection = mkSection {sectionType = "sub";};
  mkResourceOption = {
    description,
    cpu,
    memory,
  }:
    lib.mkOption {
      default = {};
      type = lib.types.submodule {
        options = {
          limits.cpu = lib.mkOption {
            description = ''
              CPU limits should never be set.

              Thus, this option is deprecated.
            '';
            type = lib.types.nullOr types.k8sCpus;
            default = null;
          };
          requests.cpu = lib.mkOption {
            inherit description;
            type = lib.types.nullOr types.k8sCpus;
            default =
              if cpu ? "request"
              then cpu.request
              else null;
            example =
              if cpu ? "example"
              then cpu.example
              else null;
          };

          requests.memory = lib.mkOption {
            description = ''
              Memory requests should always be equal to the limits.

              Thus, this option is deprecated.
            '';
            type = lib.types.nullOr types.k8sSize;
            default = null;
          };
          limits.memory = lib.mkOption {
            inherit description;
            type = lib.types.nullOr types.k8sSize;
            default =
              if memory ? "limit"
              then memory.limit
              else null;
            example =
              if memory ? "example"
              then memory.example
              else null;
          };
        };
      };
      apply = transform.filterNull;
    };
  mkMultiResourceOptions = {
    description,
    resources,
  }:
    lib.attrsets.foldlAttrs (acc: prefix: values:
      acc
      // {
        "${prefix}_resources" = mkResourceOption {
          inherit description;
          inherit (values) cpu memory;
        };
      }) {}
    resources;
}
