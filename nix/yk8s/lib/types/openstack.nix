{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    ;
in {
  availabilityZoneName = lib.types.nonEmptyStr;
  swiftContainerName = mkRegexStrOptionType {
    name = "openstackSwiftContainerName";
    description = "Openstack Swift container name";
    # as per https://docs.openstack.org/api-ref/object-store/#create-update-or-delete-container-metadata
    matchAgainstAllOf = [
      "^[^/]{1,256}$" # non-empty, length 1-256, no slashes
    ];
  };
  flavorName = lib.types.nonEmptyStr;
  imageName = lib.types.nonEmptyStr;
  keypairName = lib.types.nonEmptyStr;
  networkName = lib.types.nonEmptyStr;
  serverGroupName = lib.types.nonEmptyStr;
  volumeTypeName = lib.types.nonEmptyStr;
}
