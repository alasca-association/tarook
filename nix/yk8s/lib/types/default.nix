{lib}: let
  common = (import ./_common) {inherit lib;};
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
  inherit (common) attrsOf' withLimitedLength;

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
