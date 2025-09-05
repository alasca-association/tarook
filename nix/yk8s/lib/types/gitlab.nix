{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    urlPathSegmentType
    ;
in {
  # see https://docs.gitlab.com/ee/api/repositories.html#list-repository-tree
  projectId = with lib.types; oneOf [int urlPathSegmentType];
  terraformStateName = urlPathSegmentType;
}
