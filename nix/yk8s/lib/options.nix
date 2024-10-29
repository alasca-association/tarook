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
    preface = options._docs.preface or null;
    order = options._docs.order or null;
    opts = lib.attrsets.filterAttrs (n: _: n != "_docs") options;
  in ({
      _internal = {
        sectionType = mkInternalOption {
          type = lib.types.str;
          default = cfg.sectionType;
        };
        unflat = mkInternalOption {
          type = with lib.types; listOf nonEmptyStr;
          default = [];
        };
        transformations = mkInternalOption {
          type = with lib.types; listOf (functionTo attrs);
          default = [];
        };
        removedOptions = mkInternalOption {
          type = with lib.types; listOf (listOf nonEmptyStr);
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
}
