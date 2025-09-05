{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    oci
    ;
in {
  imageTag = mkRegexStrOptionType {
    name = "ociImageTag";
    description = "OCI image tag";
    matchAgainstAllOf = ["^(${oci.dist1.imageTagRE})$"];
  };
  imageName = mkRegexStrOptionType {
    name = "ociImageName";
    description = "OCI image name";
    matchAgainstAllOf = ["^(${oci.dist1.imageNameRE})$"];
  };
  imageRef = mkRegexStrOptionType {
    name = "ociImageRef";
    description = "OCI image reference";
    matchAgainstAllOf = ["^(${oci.dist1.imageNameRE}):(${oci.dist1.imageTagRE})$"];
  };
}
