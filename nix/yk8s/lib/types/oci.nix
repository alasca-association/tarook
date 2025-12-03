{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
in rec {
  _regexes = {
    # as per OCI Distribution Specification v1.1.0
    dist1 = {
      # https://github.com/opencontainers/distribution-spec/tree/v1.1.0/spec.md#pulling-manifests
      imageTagRE = "[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}";
      imageNameRE = "[a-z0-9]+(([.]|_|__|[-]+)[a-z0-9]+)*([/][a-z0-9]+(([.]|_|__|[-]+)[a-z0-9]+)*)*";
    };

    # as per OCI Image Format Specification v1.0
    format1 = {
      # https://github.com/opencontainers/image-spec/blob/v1.0/descriptor.md#digests
      imageDigestStrRE = let
        encodedRE = "[a-zA-Z0-9=_-]+";
        ALGO_SEP = "[+._-]";
        algoCompRE = "[a-z0-9]+";
        algoRE = "(${algoCompRE})(${ALGO_SEP}(${algoCompRE}))*";
      in "(${algoRE})[:](${encodedRE})";
    };
  };
  imageTag = _mkRegexStrOptionType {
    name = "ociImageTag";
    description = "OCI image tag";
    matchAgainstAllOf = ["^(${_regexes.dist1.imageTagRE})$"];
  };
  imageName = _mkRegexStrOptionType {
    name = "ociImageName";
    description = "OCI image name";
    matchAgainstAllOf = ["^(${_regexes.dist1.imageNameRE})$"];
  };
  imageRef = _mkRegexStrOptionType {
    name = "ociImageRef";
    description = "OCI image reference";
    matchAgainstAllOf = ["^(${_regexes.dist1.imageNameRE}):(${_regexes.dist1.imageTagRE})$"];
  };
}
