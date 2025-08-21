{lib}: rec {
  /*
  Like nixpkgs.lib.options.mkEnableOption but with true as the default
  */
  mkDisableOption = name:
    lib.mkOption {
      default = true;
      example = false;
      description = "Whether to enable ${name}.";
      type = lib.types.bool;
    };
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

  /*
  Returns an option representing the values of a Helm chart.

  A name must be given, all other parameters are optional.

  defaultValues can be given but note that they will be lost completely if the user
  sets any value themselves (even if they set different values than are set in defaultValues).
  For all values that should persist additionally to any user specified values, add them as
  chartOptions with their own default value.

  !!IMPORTANT!!
  Note that the option must be added to the unflat list of mkGroupVarsFile

  Example:

  {
    options.yk8s.my-module.helm_values = mkHelmValuesOption {
      name = "my-application";
      defaultValues = {
        A = "this setting will be lost as soon as anything else is set by the user or by a module, even if A is not set there"
      };
      chartOptions = {
        B = lib.mkOption {
          # ...
          default = "this setting will persist if other options are set but will be overwritten if B is set somewhere else";
      };
    };
    config.yk8s.my-module.helm_values = {
      C = "this setting will persist if other options are set and will create a conflict if C is set somewhere else. In order to override it, lib.mkForce must be used";
    };
    config.yk8s._inventory_packages = [
      (mkGroupVarsFile {
        inherit (config.yk8s) my-module;
        ansible_prefix = "my_prefix_";
        inventory_path = "all/my_module.yaml";
        unflat = ["helm_values"];
        })
    ];
  }
  */
  mkHelmValuesOption = {
    name,
    valuesDocUrl ? null,
    extraDescription ? "",
    chartOptions ? {},
    defaultValues ? {},
  }:
    lib.mkOption {
      description =
        ''
          Helm values for the ${name} helm chart.

          Some values are set by default through Tarook, but arbitrary values can be set.
        ''
        + (lib.optionalString (valuesDocUrl != null) ''
          For a full list of possible values, see
          ${valuesDocUrl}
        '')
        + extraDescription;
      default = defaultValues;
      type = lib.types.submodule {
        freeformType = yk8s-lib.types.jsonValue;
        options = chartOptions;
      };
    };
  mkHelmChartVersionOption = args:
    lib.mkOption ({
        example = "1.2.3";
        description = ''
          The helm chart version to be used.

          If the version shall be unpinned, set to: ``null``.
        '';
        type = lib.types.nullOr yk8s-lib.types.helmChartVersion;
      }
      // args);
}
