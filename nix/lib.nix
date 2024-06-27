{lib, ...}: rec {
  importTOML = file: fromTOML (builtins.readFile file);
  importYAML = pkgs: file: let
    jsonFile = pkgs.runCommandLocal "converted-yaml.json" {} ''
      ${pkgs.yj}/bin/yj < "${file}" > "$out"
    '';
  in
    builtins.fromJSON (builtins.readFile jsonFile);
  importYamlTree = pkgs: dir: (lib.attrsets.mapAttrs' (file: _: {
    name = lib.strings.removeSuffix ".yaml" file;
    value = importYAML pkgs "${dir}/${file}";
  }) (builtins.readDir dir));
}
