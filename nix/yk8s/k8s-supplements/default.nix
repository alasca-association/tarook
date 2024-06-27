{lib, ...}: let
  inherit (builtins) map filter readDir attrNames;
in {
  imports = map (f: ./. + ("/" + f)) (filter (f: f != "default.nix") (attrNames (readDir ./.)));
}
