{
  inputs,
  lib,
  self,
  flake-parts-lib,
  ...
}: {
  options = {
    perSystem =
      flake-parts-lib.mkPerSystemOption
      ({
        config,
        options,
        pkgs,
        inputs',
        system,
        ...
      }: let
        yk8s-lib = import ./yk8s/lib {inherit lib pkgs;};
        inherit (yk8s-lib) linkToPath;
      in {
        config.packages = let
          eval =
            inputs.flake-parts.lib.evalFlakeModule
            {
              inputs = {
                inherit (inputs) nixpkgs;
                self =
                  self
                  // {
                    outPath =
                      throw "The `self.outPath` attribute is not available when generating documentation, because the documentation should not depend on the specifics of the flake files where it is loaded. This error is generally caused by a missing `defaultText` on one or more options in the trace. Please run this evaluation with `--show-trace`, and look for `while evaluating the default value of option` and add a `defaultText` to one or more of the options involved.";
                  };
              };
            }
            self.flakeModules.yk8s;

          /*
          Extracts an attribute set of sections containing the doc preface, doc order and sectionType
          */
          allSections = let
            allSectionOptions =
              (pkgs.nixosOptionsDoc {
                options = eval.options;
                documentType = "none";
                transformOptions = v: let
                  inherit (lib.strings) hasPrefix hasSuffix removePrefix removeSuffix;
                  stripped = builtins.match "perSystem\\.(.*\._internal\..*)" v.name;
                in
                  if (stripped != null)
                  then
                    v
                    // {
                      name = builtins.head stripped;
                      visible = true;
                      internal = false;
                    }
                  else v // {visible = false;};
                warningsAreErrors = false;
              })
              .optionsNix;
            allSectionsWithoutSubsections = lib.attrsets.foldlAttrs (acc: n: v: let
              m = builtins.match "(.*)\._internal\.(.*)" n;
              name = builtins.head m;
              opt = builtins.elemAt m 1;
            in
              lib.attrsets.recursiveUpdate acc (
                if opt == "docs.preface"
                then {${name}.preface = v.description;}
                else if opt == "docs.order"
                then {${name}.order = v.default.text;}
                else if opt == "sectionType"
                then {${name}.sectionType = v.default.text;}
                else {}
              )) {}
            allSectionOptions;

            allSectionsWithSubsections =
              lib.foldlAttrs (
                acc: n: v:
                  lib.recursiveUpdate acc {
                    ${n} =
                      v
                      // {
                        subSections = builtins.filter (s: s != n && lib.strings.hasPrefix n s) (builtins.attrNames allSectionsWithoutSubsections);
                      };
                  }
              ) {}
              allSectionsWithoutSubsections;
          in
            allSectionsWithSubsections;

          declarationsBaseUrl = "https://gitlab.com/yaook/k8s/-/tree/devel/";

          /*
          Returns a list of all evaluated options that start with `prefix` but not with any string from the `exluded` list
          All options are stripped of the "perSystem." prefix
          */
          filteredNixosOptionsDoc = {
            prefix,
            exclude ? [],
          }:
            pkgs.nixosOptionsDoc {
              options = eval.options;
              documentType = "none";
              transformOptions = v:
                if
                  lib.strings.hasPrefix "perSystem.${prefix}" v.name
                  && ! builtins.any (i: lib.strings.hasPrefix "perSystem.${i}" v.name) exclude
                then
                  v
                  // {
                    name = lib.strings.removePrefix "perSystem." v.name;
                  }
                else v // {visible = false;};
              warningsAreErrors = false;
            };
          nixosOptionsDoc = filteredNixosOptionsDoc {prefix = "yk8s";};

          rstDoc = section: values: let
            filename = "${section}.rst";
          in
            linkToPath (builtins.toFile filename (rstDocStr section values)) filename;

          rstDocCombined = sections: let
            sorted = (
              builtins.sort (a: b: a.value.order < b.value.order) (lib.attrsets.mapAttrsToList (name: value: {inherit name value;}) sections)
            );
          in
            builtins.toFile "all.rst" (lib.strings.concatStrings (
              map (e: rstDocStr e.name e.value) sorted
            ));

          underline = symbol: text: ''
            ${text}
            ${lib.strings.concatStrings (lib.lists.replicate (builtins.stringLength text) symbol)}
          '';
          bold = text: "**${text}**";
          indent = text: with lib.strings; concatLines (map (l: "  ${l}") (splitString "\n" text));

          rstDocStr = section: values: let
            options =
              (filteredNixosOptionsDoc {
                prefix = section;
                exclude = values.subSections;
              })
              .optionsNix;
            filename = "${section}.rst";
          in (''
              .. _configuration-options.${section}:

              ${underline "^" section}

            ''
            + (lib.optionalString (values.preface != null) values.preface)
            + lib.strings.concatLines (lib.attrsets.mapAttrsToList (
                n: v:
                  ''

                    .. _configuration-options.${n}:

                    ${underline "#" "``${n}``"}
                    ${
                      if v ? "description" && v.description != null
                      then v.description
                      else ""
                    }

                    **Type:**::

                    ${indent v.type}

                  ''
                  + lib.strings.optionalString (v ? "default" && v.default._type == "literalExpression") ''
                    **Default:**::

                    ${indent v.default.text}

                  ''
                  + lib.strings.optionalString (v ? "example" && v.example._type == "literalExpression")
                  ''
                    **Example:**::

                    ${indent v.example.text}

                  ''
                  + ''
                    **Declared by**
                  ''
                  + (lib.strings.concatLines (map (
                      d: lib.pipe d [(lib.strings.splitString "/") (lib.lists.drop 4) (lib.strings.concatStringsSep "/") (l: declarationsBaseUrl + l)]
                    )
                    v.declarations))
              )
              options));

          rstDocWithIndex = sections: let
            docs = pkgs.buildEnv {
              name = "yaook-k8s-docs-options";
              paths = lib.attrsets.mapAttrsToList rstDoc sections;
            };
            sectionList = lib.attrsets.mapAttrsToList (name: _: lib.strings.removeSuffix ".rst" name) (builtins.readDir docs);
            index =
              ''
                ${underline "#" "Configuration Options"}

                .. toctree::
                  :maxdepth: 2
                  :hidden:

              ''
              + indent (lib.strings.concatLines sectionList)
              + ''

              ''
              + lib.strings.concatLines (map (n: ''
                  :doc:`${lib.strings.removePrefix "yk8s." n} <${n}>`
                '')
                sectionList);
            indexFile = linkToPath (builtins.toFile "index.rst" index) "index.rst";
          in
            pkgs.buildEnv {
              name = "yaook-k8s-docs";
              paths = [docs indexFile];
            };
        in {
          docsJSON = nixosOptionsDoc.optionsJSON;
          docsRST = rstDocWithIndex allSections;
          docsAll = rstDocCombined allSections;
        };
      });
  };
}
