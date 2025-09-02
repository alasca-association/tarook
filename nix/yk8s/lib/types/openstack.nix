{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    ;
in {
  openstackAvailabilityZoneName = lib.types.nonEmptyStr;
  openstackSwiftContainerName = mkRegexStrOptionType {
    name = "openstackSwiftContainerName";
    description = "Openstack Swift container name";
    # as per https://docs.openstack.org/api-ref/object-store/#create-update-or-delete-container-metadata
    matchAgainstAllOf = [
      "^[^/]{1,256}$" # non-empty, length 1-256, no slashes
    ];
  };
  openstackFlavorName = lib.types.nonEmptyStr;
  openstackImageName = lib.types.nonEmptyStr;
  openstackKeypairName = lib.types.nonEmptyStr;
  openstackNetworkName = lib.types.nonEmptyStr;
  openstackServerGroupName = lib.types.nonEmptyStr;
  openstackVolumeTypeName = lib.types.nonEmptyStr;
}
