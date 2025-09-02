{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    oci
    ;
in {
  ociImageTag = mkRegexStrOptionType {
    name = "ociImageTag";
    description = "OCI image tag";
    matchAgainstAllOf = ["^(${oci.dist1.imageTagRE})$"];
  };
  ociImageName = mkRegexStrOptionType {
    name = "ociImageName";
    description = "OCI image name";
    matchAgainstAllOf = ["^(${oci.dist1.imageNameRE})$"];
  };
  ociImageRef = mkRegexStrOptionType {
    name = "ociImageRef";
    description = "OCI image reference";
    matchAgainstAllOf = ["^(${oci.dist1.imageNameRE}):(${oci.dist1.imageTagRE})$"];
  };
}
