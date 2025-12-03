{lib}: let
  types = (import ./.) {inherit lib;};
  inherit
    (types.yk8s.networking)
    urlPathSegment
    ;
in {
  # see https://docs.gitlab.com/ee/api/repositories.html#list-repository-tree
  projectId = with lib.types; oneOf [int urlPathSegment];
  terraformStateName = urlPathSegment;
}
