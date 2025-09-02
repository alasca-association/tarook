{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    isoiec80000
    semver
    rfc4648
    ;
  gitlab = import ./gitlab.nix {inherit lib;};
  helm = import ./helm.nix {inherit lib;};
  k8s = import ./k8s.nix {inherit lib;};
  networking = import ./networking.nix {inherit lib;};
  oci = import ./oci.nix {inherit lib;};
  openstack = import ./openstack.nix {inherit lib;};
  posix = import ./posix.nix {inherit lib;};
  prometheus = import ./prometheus.nix {inherit lib;};
  s3 = import ./s3.nix {inherit lib;};
  terraform = import ./terraform.nix {inherit lib;};
  vault = import ./vault.nix {inherit lib;};
  wireguard = import ./wireguard.nix {inherit lib;};
in {
  inherit (common) attrsOf';

  inherit
    (gitlab)
    gitlabProjectId
    gitlabTerraformStateName
    ;
  inherit
    (helm)
    helmChartRef
    helmChartReleaseName
    helmChartRepoUrl
    helmChartVersion
    ;
  inherit
    (k8s)
    k8sClusterName
    k8sDurationStr
    k8sImageRef
    k8sIngressClassName
    k8sIssuerName
    k8sLabel
    k8sLabelAttrs
    k8sLabelPrefix
    k8sLabelStr
    k8sLabelValue
    k8sNamespaceName
    k8sObjectName
    k8sPodContainerName
    k8sQuantity
    k8sSecretName
    k8sServiceName
    k8sServiceType
    k8sStorageClassName
    k8sTaintStr
    k8sThreshold
    k8sVersion
    ;
  inherit
    (networking)
    emailAddress
    httpHostPathUrl
    httpHostUrl
    httpUrl
    httpsHostPathUrl
    httpsHostUrl
    httpsUrl
    httpxHostPathUrl
    httpxHostUrl
    httpxUrl
    ipsecProposalStr
    ipv4Addr
    ipv4AddrWithPort
    ipv4Cidr
    ipv6Addr
    ipv6AddrWithPort
    ipv6Cidr
    privateUseAutonomousSystemNumber
    relativeUrlPath
    subdomainLabel
    subdomainName
    urlPathSegment
    xftpUrl
    ;
  inherit
    (oci)
    ociImageName
    ociImageRef
    ociImageTag
    ;
  inherit
    (openstack)
    openstackAvailabilityZoneName
    openstackFlavorName
    openstackImageName
    openstackKeypairName
    openstackNetworkName
    openstackServerGroupName
    openstackSwiftContainerName
    openstackVolumeTypeName
    ;
  inherit
    (posix)
    absolutePosixPath
    absolutePosixPathWithSpecial
    posixFilename
    posixPath
    posixPathSegment
    posixPathSegmentWithSpecial
    posixPathWithSpecial
    posixUserName
    relativePosixPath
    relativePosixPathWithSpecial
    ;
  inherit
    (prometheus)
    prometheusIntervalStr
    prometheusLabelName
    prometheusRelabelConfig
    prometheusTimeoutStr
    ;
  inherit
    (s3)
    s3BucketName
    s3BucketNamePrefix
    ;
  inherit
    (terraform)
    terraformDurationStr
    ;
  inherit
    (vault)
    vaultChildNamespaceNameSegment
    vaultNamespaceName
    ;
  inherit
    (wireguard)
    wireguardKey
    ;

  /*
  Composite type to constrain the input length of string/list option types

  Example:
    withLimitedLength {max = 32;} lib.types.str -> <option type that accepts strings with up to 32 characters>
  */
  withLimitedLength = {
    min ? null,
    max ? null,
  }:
    assert lib.assertMsg
    (!(min == null && max == null))
    "withLimitedLength: min and max must not both be null";
    assert lib.assertMsg
    ((min == null || max == null) || (min <= max))
    "withLimitedLength: min must be smaller than max";
      elemType:
        assert lib.assertMsg
        (elemType.descriptionClass == "noun")
        "withLimitedLength can only be used with noun class option types";
          lib.mkOptionType rec {
            name = "${elemType.name}WithLimitedLength";
            description = "${elemType.description} with ${
              if (min == null || max == null)
              then
                if min != null
                then "at least ${builtins.toString min}"
                else "up to ${builtins.toString max}"
              else if (min == max)
              then "exactly ${builtins.toString min}"
              else "${builtins.toString min} to ${builtins.toString max}"
            } characters";
            descriptionClass = "composite";
            check = x:
              elemType.check x
              && (
                let
                  type_ = builtins.typeOf x;
                  length =
                    if type_ == "string"
                    then builtins.stringLength x
                    else if type_ == "list"
                    then builtins.length x
                    else throw "withLimitedLength can only be used with string/list option types";
                in
                  (
                    if min != null
                    then length >= min
                    else true
                  )
                  && (
                    if max != null
                    then length <= max
                    else true
                  )
              );
          };

  bytesPower10 = mkRegexStrOptionType {
    name = "bytesPower10";
    description = "Bytes with units based on powers of 10";
    matchAgainstAllOf = ["^(${isoiec80000.bytes.power10RE})$"];
  };
  bytesPower2 = mkRegexStrOptionType {
    name = "bytesPower2";
    description = "Bytes with units based on powers of 2";
    matchAgainstAllOf = ["^(${isoiec80000.bytes.power2RE})$"];
  };

  semver2VersionStr = mkRegexStrOptionType {
    name = "semver2VersionStr";
    description = "Semantic version 2 string";
    matchAgainstAllOf = ["^(${semver.v2.versionStrRE})$"];
  };

  base64Str = mkRegexStrOptionType {
    name = "base64Str";
    description = "Base64 encoded string";
    matchAgainstAllOf = ["^(${rfc4648.base64StrRE})$"];
  };

  # Values that are compatible with JSON, YAML and TOML
  jsonValue = let
    valueType = with lib.types;
      nullOr (oneOf [
        bool
        int
        float
        str
        (attrsOf valueType)
        (listOf valueType)
      ])
      // {
        description = "JSON value";
      };
  in
    valueType;
}
