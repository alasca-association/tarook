{lib}: rec {
  # as per POSIX.1-2024
  posix1-2024 = {
    # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_146
    filenameRE = "[^/]+";
    # NOTE: A positive lookahead would make this more readable but that is unsupported: "(?!^[.]{1,2})([^/]+)"
    filenameNoSpecialRE = "([^./]{1,2}|[^/]{3,})";

    # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_254
    pathname = let
      sepRE = "[/]+";
      inherit (posix1-2024) filenameRE filenameNoSpecialRE;
      inherit (posix1-2024.pathname) relativeRE relativeNoSpecialRE;
    in {
      relativeRE = "(${filenameRE})((${sepRE})(${filenameRE}))*(${sepRE})?";
      relativeNoSpecialRE = "(${filenameNoSpecialRE})((${sepRE})(${filenameNoSpecialRE}))*(${sepRE})?";
      absoluteRE = "(${sepRE})(${relativeRE})";
      absoluteNoSpecialRE = "(${sepRE})(${relativeNoSpecialRE})";
      anyRE = "(${sepRE})?(${relativeRE})";
      anyNoSpecialRE = "(${sepRE})?(${relativeNoSpecialRE})";
    };

    # https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap03.html#tag_03_409
    usernameRE = "[A-Za-z0-9._-]+";
  };

  # as per ISO/IEC 80000
  isoiec80000 = {
    bytes = {
      power10RE = "[0-9]+.[0-9]+([kMGTPEZYRQ]B)|[1-9][0-9]*([kMGTPEZYRQ]B)";
      power2RE = "[0-9]+.[0-9]+([KMGTPEZY]iB)|[1-9][0-9]*([KMGTPEZY]iB)";
    };
  };

  cidr = {
    ipv4SuffixRE = "[/]([0-9]|[12][0-9]|3[0-2])";
    ipv6SuffixRE = "[/]((1([0-7][0-9]|80))|([1-9]?[0-9]))";
  };

  # as per IETF RFC 2234
  rfc2234 = let
    # Section 6.1
    ALPHA = "[A-Za-z]";
    DIGIT = "[0-9]";
    HEXDIG = "${DIGIT}|[A-F]";
  in {
    inherit ALPHA DIGIT HEXDIG;
  };

  # as per IETF RFC 5234
  rfc5234 = let
    # Appendix B.1
    ALPHA = "[A-Za-z]";
    DIGIT = "[0-9]";
  in {
    inherit ALPHA DIGIT;
  };

  # as per IETF RFC 3513
  rfc3513 = {
    # Section 2.2
    # NOTE: The regex of IETF RFC 3986 is used here because that one was modelled according to an ABNF expression
    #       which matches the address text representation described in IETF RFC 3513.
    ipv6AddressRE = rfc3986.ipv6AddressRE;
  };

  # as per IETF RFC 952
  rfc952 = let
    # Section GRAMMATICAL HOST TABLE SPECIFICATION
    addressRE = "(${octetRE})[.](${octetRE})[.](${octetRE})[.](${octetRE})";
    octetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9])?[0-9])";

    domainnameRE = hnameRE;
    hnameRE = "(${nameRE})*([.](${nameRE}))?";
    nameRE = "${LET}((${letOrDigitOrHyphenRE})*(${letOrDigitRE}))?";
    letOrDigitOrHyphenRE = "${LET}|${DIGIT}|${HYPHEN}";
    letOrDigitRE = "${LET}|${DIGIT}";
    LET = "[A-Za-z]";
    DIGIT = "[0-9]";
    HYPHEN = "[-]";
  in {
    # reused by rfc1123
    inherit letOrDigitRE letOrDigitOrHyphenRE;

    ipv4AddrRE = "(${addressRE})";
    subdomainNameRE = "(${domainnameRE})";
  };

  # as per IETF RFC 1123
  rfc1123 = let
    # Section 2.1 (+ IETF RFC 952)
    domainnameRE = hnameRE;
    hnameRE = "(${nameRE})([.](${nameRE}))*";
    nameRE = "(${letOrDigitRE})((${letOrDigitOrHyphenRE})*(${letOrDigitRE}))?"; # updated
    inherit (rfc952) letOrDigitRE letOrDigitOrHyphenRE;
  in {
    subdomainLabelRE = "(${nameRE})";
    subdomainNameRE = "(${domainnameRE})";
  };

  # as per IETF RFC 1035
  rfc1035 = let
    # Section 2.3.1
    domainRE = "(${subdomainRE})|[ ]";
    subdomainRE = "(${labelRE})([.](${labelRE}))*";
    labelRE = "(${LETTER})((${ldhStrRE})?(${letDigRE}))?"; # without maxLength=63
    ldhStrRE = "(${letDigHypRE})+";
    letDigHypRE = "(${letDigRE})|[-]";
    letDigRE = "${LETTER}|${DIGIT}";
    LETTER = "[A-Za-z]";
    DIGIT = "[0-9]";
  in {
    subdomainNameRE = "(${subdomainRE})";
    subdomainLabelRE = "(${labelRE})";
  };

  # as per IETF RFC 9293
  rfc9293 = {
    # Section 3.1
    portNumberRE = "(6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{1,5})|([0-9]{1,4})";
  };

  # as per IETF RFC 3986
  rfc3986 = let
    # Section 1.3
    inherit (rfc2234) ALPHA DIGIT HEXDIG;

    # Section 2.1
    pctEncodedRE = "%${HEXDIG}${HEXDIG}";
    # Section 2.2
    SUB_DELIMS = "[!$&'()*+,;=]";
    # Section 2.3
    unreservedRE = "${ALPHA}|${DIGIT}|[-]|[._~]";

    # Section 3
    mkUriRE = {
      schemeRE,
      hierPartRE,
      withQuery ? true,
      withFragment ? true,
    }: let
      withQueryRE = "([?](${queryRE}))?";
      withFragmentRE = "([#](${fragmentRE}))?";
    in "${schemeRE}:(${hierPartRE})${
      lib.optionalString withQuery withQueryRE
    }${
      lib.optionalString withFragment withFragmentRE
    }";

    # Section 3.1
    schemeRE = "${ALPHA}(${ALPHA}|${DIGIT}|[+]|[-]|[.])*";

    # Section 3.2
    authorityRE = "((${userInfoRE})[@])?(${hostRE})([:](${portRE}))?";
    # Section 3.2.1
    userInfoRE = "((${unreservedRE})|(${pctEncodedRE})|${SUB_DELIMS}|[:])*";
    # Section 3.2.2
    hostRE = "((${ipLiteralRE})|(${ipv4AddressRE})|(${regNameRE}))";
    ipLiteralRE = "[[](${ipv6AddressRE})[]]"; # without ipvFuture
    ipv6AddressRE = let
      _hexdig = HEXDIG + "|[a-f]"; # with lowercase letters allowed for convenience
      H16 = "(${_hexdig}){1,4}";
    in
      # without mixed ipv6/ipv4 representation (hence LS32 is not used)
      lib.concatStrings [
        "("
        "("
        "("
        "(${H16}:){7}"
        "|::(${H16}:){6}"
        "|${H16}::(${H16}:){5}"
        "|((${H16}:){0,1}${H16})?::(${H16}:){4}"
        "|((${H16}:){0,2}${H16})?::(${H16}:){3}"
        "|((${H16}:){0,3}${H16})?::(${H16}:){2}"
        "|((${H16}:){0,4}${H16})?::(${H16}:){1}"
        "|((${H16}:){0,5}${H16})?::"
        ")${H16}"
        ")"
        "|(((${H16}:){0,6}${H16})?::)"
        ")"
      ];
    ipv4AddressRE = "(${decOctetRE})[.](${decOctetRE})[.](${decOctetRE})[.](${decOctetRE})";
    decOctetRE = "${DIGIT}|[1-9]${DIGIT}|1${DIGIT}{2}|2[0-4]${DIGIT}|25[0-5]";
    regNameRE = "((${unreservedRE})|(${pctEncodedRE})|${SUB_DELIMS})*";
    # Section 3.2.3
    portRE = "${DIGIT}*";

    # Section 3.3
    pathAbEmptyRE = "([/](${segmentRE}))*";
    pathRootlessRE = "(${segmentNzRE})([/](${segmentRE}))*";
    segmentRE = "(${pCharRE})*";
    segmentNzRE = "(${pCharRE})+";
    pCharRE = "(${unreservedRE})|(${pctEncodedRE})|${SUB_DELIMS}|[:@]";

    # Section 3.4
    queryRE = "((${pCharRE})|[/]|[?])*";

    # Section 3.5
    fragmentRE = "((${pCharRE})|[/]|[?])*";
  in {
    # reused by rfc3513
    inherit ipv6AddressRE;

    unreservedCharRE = unreservedRE;

    urlPathSegmentRE = segmentNzRE; # use non-zero segment here to avoid bugs
    relativeUrlPathRE = pathRootlessRE;

    # Uris with empty scheme and mandatory authority component
    xHostUrlRE = mkUriRE {
      schemeRE = "";
      hierPartRE = "//(${authorityRE})"; # Section 3
      withQuery = false;
      withFragment = false;
    };
    xHostPathUrlRE = mkUriRE {
      schemeRE = "";
      hierPartRE = "//(${authorityRE})(${pathAbEmptyRE})"; # Section 3
      withQuery = false;
      withFragment = false;
    };
    xUrlRE = mkUriRE {
      schemeRE = "";
      hierPartRE = "//(${authorityRE})(${pathAbEmptyRE})"; # Section 3
      withQuery = true;
      withFragment = true;
    };
  };

  # as per IETF RFC 5322
  rfc5322 = let
    # Section 3.1
    inherit (rfc5234) ALPHA DIGIT;

    # Section 3.2.3
    aTextRE = "${ALPHA}|${DIGIT}|[!#$%&'*+/=?^_`{|}~-]";
    dotAtomTextRE = "(${aTextRE})+([.](${aTextRE})+)*";
    dotAtomRE = dotAtomTextRE; # without CFWS

    # Section 3.4.1
    addrSpec = "(${localPartRE})@(${domainRE})";
    localPartRE = dotAtomRE; # without quoted-string, obs-local-part
    domainRE = "(${dotAtomRE})|(${domainLiteralRE})"; # without obs-domain
    domainLiteralRE = "[[](${dTextRE})*[]]"; # without CFWS and FWS
    dTextRE = "[!\"#$%&'()*+,./0-9:;<=>?@A-Z]|[^_`a-z{|}~-]"; # without obs-dtext
  in {
    emailAddressRE = "(${addrSpec})";
  };

  # as per Strongswan documentation
  strongswan = let
    algoNameRE = "[A-Za-z0-9_]+"; # without matching any allowed algorithm names
    # https://docs.strongswan.org/docs/latest/config/proposals.html#_general_proposal_format
    ipsecProposalStrRE = "(${algoNameRE})([-](${algoNameRE}))*";
  in {
    inherit ipsecProposalStrRE;
  };

  oci = {
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

  # as per Kubernetes documentation
  k8s = {
    # https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/
    # TODO: enforce quantity is lower than 2^63-1
    quantityRE = let
      quantityRE_ = "(${signedNumberRE})(${suffixRE})";
      DIGIT = "[0-9]";
      digitsRE = "${DIGIT}+";
      decimalPlaceDigitsRE = "${DIGIT}{1,3}"; # constrain to max 3 decimal places
      numberRE = "(${digitsRE})|(${digitsRE})[.](${decimalPlaceDigitsRE})|(${digitsRE})[.]|[.](${decimalPlaceDigitsRE})";
      SIGN = "[+-]";
      signedNumberRE = "(${numberRE})|${SIGN}(${numberRE})";
      suffixRE = "(${binarySiRE})|(${decimalExponentRE})|(${decimalSiRE})?"; # decimalSI may be empty
      binarySiRE = "Ki|Mi|Gi|Ti|Pi|Ei";
      decimalSiRE = "m|k|M|G|T|P|E";
      decimalExponentRE = "e(${signedNumberRE})|E(${signedNumberRE})";
    in
      quantityRE_;

    # https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set
    labelPrefixRE = "(${rfc1123.subdomainNameRE})";
    # TODO: enforce length<=63 (positive lookaheads are not supported unfortunately)
    labelNameRE = "([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]";
    labelRE = "((${k8s.labelPrefixRE})[/])?(${k8s.labelNameRE})";
    # TODO: enforce length<=63 (positive lookaheads are not supported unfortunately)
    labelValueRE = "(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?";

    # https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration
    taintEffectRE = "(NoExecute|NoSchedule|PreferNoSchedule)";

    # as per https://kubernetes.io/docs/concepts/containers/images/#image-names
    imageRefRE = lib.concatStrings [
      "((${rfc1123.subdomainNameRE})([:]${rfc9293.portNumberRE})?[/])?" # domain/ or domain:port/
      "(${oci.dist1.imageNameRE})" # image-name
      "([:](${oci.dist1.imageTagRE}))?" # optional :image-tag
      "([@](${oci.format1.imageDigestStrRE}))?" # optional @digest
    ];

    # as per servicemonitors.monitoring.coreos.com Kubernetes CRD v1
    coreos-monitoring = {
      v1 = let
        # https://github.com/prometheus-operator/prometheus-operator/blob/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml#L260 (interval, scrapeTimeout)
        prometheusIntervalRE = "0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?";
      in {
        prometheusDurationRE = prometheusIntervalRE;
        # https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.LabelName
        prometheusLabelNameRE = "[a-zA-Z0-9_]+";
      };
    };
  };

  # as per Helm documentation and source code
  helm = {
    v3 = let
      # https://github.com/helm/helm/blob/v3.16.2/pkg/chartutil/validate_name.go#L36
      # TODO: enforce 1<=length<=53 (positive lookaheads are not supported unfortunately)
      chartutilValidNameRE = "[a-z0-9]([-a-z0-9]*[a-z0-9])?([.][a-z0-9]([-a-z0-9]*[a-z0-9])?)*";

      # https://helm.sh/docs/topics/charts/#charts-and-versioning
      # (not to be confused with https://helm.sh/docs/chart_best_practices/conventions/#version-numbers)
      # NOTE: not clearly specified but OCI image tags are valid as well
      versionNumberRE = semver.v2.versionStrRE;
      ociImageTagRE = oci.dist1.imageTagRE;
    in {
      chartReleaseNameRE = chartutilValidNameRE;
      chartVersionRE = "(${versionNumberRE})|(${ociImageTagRE})";
    };
  };

  # as per Golang documentation
  golang = let
    # https://pkg.go.dev/tie#ParseDuration
    parseDuration.unsignedRE = "((0|[1-9][0-9]*)(ns|µs|us|ms|s|m|h))+";
  in {
    unsignedIntDurationStrRE = parseDuration.unsignedRE;
  };

  # as per IETF RFC 4648
  rfc4648 = let
    # Section 4
    B64CHAR = "[a-z0-9A-Z+/]";
    base64StrRE = "(${B64CHAR}{4})*(${B64CHAR})((${B64CHAR})==|(${B64CHAR}){2}=|(${B64CHAR}){3})";
  in {
    inherit base64StrRE;
  };

  # as per Semantic Versioning 2.0.0
  semver = {
    v2 = let
      # https://semver.org/spec/v2.0.0.html#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
      versionStrRE = lib.concatStrings [
        "(0|[1-9][0-9]*)" # major
        "[.]"
        "(0|[1-9][0-9]*)" # minor
        "[.]"
        "(0|[1-9][0-9]*)" # patch
        # optional pre-release
        "(-("
        "(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)"
        "([.](0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*"
        "))?"
        # build metadata
        "([+]([0-9a-zA-Z-]+([.][0-9a-zA-Z-]+)*))?"
      ];
    in {
      inherit versionStrRE;
    };
  };

  # as per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
  # (without the prefix and suffix specifics)
  s3 = {
    bucket.name = rec {
      RE = "(${prefix.RE})[a-z0-9]";
      negativeREs = [
        "^[^.]+([.][^.]+)*[.]{2}.*$" # two periods in a row
        "^((${rfc952.ipv4AddrRE})|(${rfc3513.ipv6AddressRE}))$" # ip addresses
        "^xn--.*$" # punny code
      ];
      prefix = {
        RE = "[a-z0-9][a-z0-9.-]{1,61}";
        inherit negativeREs;
      };
    };
  };
}
