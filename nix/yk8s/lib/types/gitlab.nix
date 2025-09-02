{lib}: let
  common = (import ./_common) {inherit lib;};
  inherit
    (common)
    urlPathSegmentType
    ;
in {
  # see https://docs.gitlab.com/ee/api/repositories.html#list-repository-tree
  gitlabProjectId = with lib.types; oneOf [int urlPathSegmentType];
  gitlabTerraformStateName = urlPathSegmentType;
}
