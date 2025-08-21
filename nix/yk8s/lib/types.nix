{lib}: let
  transform = import ./transform.nix {inherit lib;};
  inherit (transform) matchesRegex;

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
    octetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])";

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

  ### option type generators ###

  /*
  Create an option type that matches a given string value against a set of regular expressions

  Arguments (as attrset):
  - name: Name of the option type
  - description: Description of the option type
  - matchAgainstAllOf: Optional list of regular expressions of which all must match
  - matchAgainstNoneOf: Optional list of regular expressions of which none must match
  */
  mkRegexStrOptionType = {
    name,
    description,
    matchAgainstAllOf ? [],
    matchAgainstNoneOf ? [],
  }:
    assert lib.assertMsg
    (!(matchAgainstAllOf == matchAgainstNoneOf))
    "positive and negative regex sets must no be equal";
      lib.mkOptionType {
        name = name;
        description = description;
        descriptionClass = "noun";
        check = x:
          builtins.isString x
          && (
            builtins.all (
              regex: matchesRegex regex x
            )
            matchAgainstAllOf
          )
          && (
            builtins.all (
              regex: builtins.match regex x == null
            )
            matchAgainstNoneOf
          );
      };

  ### reusable option types ###

  urlPathSegmentType = mkRegexStrOptionType {
    name = "relativeUrlPath";
    description = "RFC3986 URL path segment (pchar)";
    matchAgainstAllOf = ["^(${rfc3986.urlPathSegmentRE})$"];
  };
  relativeUrlPathType = mkRegexStrOptionType {
    name = "relativeUrlPath";
    description = "RFC3986 relative URL path";
    matchAgainstAllOf = ["^(${rfc3986.relativeUrlPathRE})$"];
  };
  httpxUrlType = mkRegexStrOptionType {
    name = "httpxUrl";
    description = "RFC3986 HTTP(S) URL";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xUrlRE})$"];
  };

  nonEmptyNonSpacedStr = mkRegexStrOptionType {
    name = "nonEmptyNonSpacedStr";
    description = "${lib.types.nonEmptyStr.description} without spaces";
    matchAgainstAllOf = ["^[^ ]+$"];
  };

  ### reusable option types (parameterized) ###

  mkRfc1035SubdomainLabelType = {rejectCapitals ? false}:
    mkRegexStrOptionType {
      name = "${
        if rejectCapitals
        then "lowercaseR"
        else "r"
      }fc1035SubdomainLabel";
      description = ''
        RFC1035 subdomain label${
          lib.optionalString rejectCapitals " (lowercase)"
        }'';
      matchAgainstAllOf =
        [
          "^(${rfc1035.subdomainLabelRE})$"

          # IETF RFC 1035, Section 2.3.4
          # length<=63 (WORKAROUND: This should have been encoded in subdomainLabelRE with positive lookaheads but these are unsupported)
          "^.{0,63}$"
        ]
        # IETF RFC 1035, Section 2.3.4: Case has no significance actually
        ++ (lib.optional rejectCapitals "^[^A-Z]*$");
    };
  mkRfc1035SubdomainNameType = {rejectCapitals ? false}:
    mkRegexStrOptionType {
      name = "${
        if rejectCapitals
        then "lowercaseR"
        else "r"
      }fc1035SubdomainName";
      description = ''
        RFC1035 subdomain name${
          lib.optionalString rejectCapitals " (lowercase)"
        }'';
      matchAgainstAllOf =
        [
          "^(${rfc1035.subdomainNameRE})$"

          # IETF RFC 1035, Section 2.3.4
          # length<=255 (WORKAROUND: This should have been encoded in subdomainLabelRE with positive lookaheads but these are unsupported)
          "^.{0,255}$"
          # labelLength<=63 (WORKAROUND: This should have been encoded in subdomainLabelRE with positive lookaheads but these are unsupported)
          "^[^.]{0,63}([.][^.]{0,63})*$"
        ]
        # IETF RFC 1035, Section 2.3.4: Case has no significance actually
        ++ (lib.optional rejectCapitals "^[^A-Z]*$");
    };
  mkRfc1123SubdomainLabelType = {
    rejectCapitals ? false,
    enforceMaxLength63 ? false,
  }:
    mkRegexStrOptionType {
      name = "${
        if rejectCapitals
        then "lowercaseR"
        else "r"
      }fc1123SubdomainLabel";
      description = ''
        RFC1123 subdomain label${
          lib.optionalString rejectCapitals " (lowercase)"
        }'';
      matchAgainstAllOf =
        ["^(${rfc1123.subdomainLabelRE})$"]
        # IETF RFC 1123, Section 2.1: subdomain labels have no size constraints by default
        ++ (lib.optional enforceMaxLength63 "^.{0,63}$")
        # IETF RFC 1123 does not define any case contraints
        ++ (lib.optional rejectCapitals "^[^A-Z]*$");
    };
  mkRfc1123SubdomainNameType = {
    rejectCapitals ? false,
    enforceMaxLength253_63 ? false,
  }:
    mkRegexStrOptionType {
      name = "${
        if rejectCapitals
        then "lowercaseR"
        else "r"
      }fc1123SubdomainName";
      description = ''
        RFC1123 subdomain name${
          lib.optionalString rejectCapitals " (lowercase)"
        }'';
      matchAgainstAllOf =
        ["^(${rfc1123.subdomainNameRE})$"]
        # IETF RFC 1123, Section 2.1: subdomain names and labels have no size constraints by default
        ++ (lib.optionals enforceMaxLength253_63 ["^.{0,253}$" "^[^.]{0,63}([.][^.]{0,63})*$"])
        # IETF RFC 1123 does not define any case contraints
        ++ (lib.optional rejectCapitals "^[^A-Z]*$");
    };
in rec {
  /*
  Variant of nixpkgs.lib.types.attrsOf

  An attribute set of where the values are of the type specified for their respective names in `ts`.

  Example:
    (attrsOf' {a = nonEmptyStr;}).check {a = "foo"; b = 1;} -> true
    (attrsOf' {a = nonEmptyStr;}).check {a = ""; b = 1;} -> false
    (attrsOf' {a = nonEmptyStr;}).check {b = 1;} -> true
  */
  attrsOf' = ts:
    lib.mkOptionType {
      name = "attrsOf'";
      description = "attribute set with items of specific types (${
        builtins.concatStringsSep ", " (
          lib.attrsets.foldlAttrs (acc: n: v: acc ++ ["${n}: ${v.name}"]) [] ts
        )
      })";
      check = x:
        lib.types.attrs.check x
        && lib.attrsets.foldlAttrs
        (
          acc: n: v:
            acc
            && (
              if (builtins.hasAttr n ts)
              then (builtins.getAttr n ts).check v
              else true
            )
        )
        true
        x;
      nestedTypes.elemType = lib.attrsets.attrValues ts;
      inherit (lib.types.attrs) merge emptyValue;
    };

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

  # see https://docs.gitlab.com/ee/api/repositories.html#list-repository-tree
  gitlabProjectId = with lib.types; oneOf [int urlPathSegmentType];
  gitlabTerraformStateName = urlPathSegmentType;

  # TODO: Vault namespace names are part of URL paths in Vault's REST API.
  #       Because there are almost no character constraints for namespaces
  #       names, code that makes API calls has to carefully handle non-URL
  #       characters in them.
  #       Tests revealed that names with characters, such as *@+?# and even
  #       emojis work just fine with the Vault CLI client but are handled
  #       differently by the `hashi_vault` Ansible module.
  #       In https://gitlab.com/yaook/k8s/-/merge_requests/1731#note_2385728506
  #       it was decided that we do not want to reject what Vault accepts,
  #       hence further investigation is needed.
  vaultNamespaceName = mkRegexStrOptionType {
    name = "vaultNamespaceName";
    description = "Name of a Hashicorp Vault namespace";
    # as per https://developer.hashicorp.com/vault/docs/enterprise/namespaces#namespace-naming-restrictions
    matchAgainstAllOf = [
      "^[^ ]+$" # no spaces, non-empty
    ];
    matchAgainstNoneOf = [
      "^.*[/]$" # trailing slash
      "^(root|sys|audit|auth|cubbyhole|identity)([/].*)?$" # reserved namespaces

      # reserved by policy path syntax
      # see https://developer.hashicorp.com/vault/docs/concepts/policies#policy-syntax
      "^[+]$" # single '+'
      "^.*?(\\{\\{.*}}).*?$" # template string within
    ];
  };
  vaultChildNamespaceNameSegment = mkRegexStrOptionType {
    name = "vaultChildNamespaceNameSegment";
    description = "Segment of a Hashicorp Vault namespace";
    # as per https://developer.hashicorp.com/vault/docs/enterprise/namespaces#namespace-naming-restrictions
    # see also https://developer.hashicorp.com/vault/docs/enterprise/namespaces#child-namespaces
    matchAgainstAllOf = [
      "^[^ /]+$" # no spaces, no slashes, non-empty
    ];
    matchAgainstNoneOf = [
      # NOTE: there are no reserved child namespaces

      # reserved by policy path syntax
      # see https://developer.hashicorp.com/vault/docs/concepts/policies#policy-syntax
      "^[+]$" # single '+'
      "^.*?(\\{\\{.*}}).*?$" # template string within
    ];
  };

  posixPathSegment = mkRegexStrOptionType {
    name = "posixPathSegment";
    description = "POSIX path segment (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };
  posixPathSegmentWithSpecial = mkRegexStrOptionType {
    name = "posixPathSegmentWithSpecial";
    description = "POSIX path segment";
    matchAgainstAllOf = ["^(${posix1-2024.filenameRE})$"];
  };
  posixFilename = mkRegexStrOptionType {
    name = "posixFilename";
    description = "POSIX file name";
    matchAgainstAllOf = ["^(${posix1-2024.filenameNoSpecialRE})$"];
  };

  relativePosixPath = mkRegexStrOptionType {
    name = "relativePosixPath";
    description = "Relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeNoSpecialRE})$"];
  };
  relativePosixPathWithSpecial = mkRegexStrOptionType {
    name = "relativePosixPathWithSpecial";
    description = "Relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.relativeRE})$"];
  };
  absolutePosixPath = mkRegexStrOptionType {
    name = "absolutePosixPath";
    description = "Absolute POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteNoSpecialRE})$"];
  };
  absolutePosixPathWithSpecial = mkRegexStrOptionType {
    name = "absolutePosixPathWithSpecial";
    description = "Absolute POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.absoluteRE})$"];
  };
  posixPath = mkRegexStrOptionType {
    name = "posixPath";
    description = "Absolute or relative POSIX path (without special '.' and '..')";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyNoSpecialRE})$"];
  };
  posixPathWithSpecial = mkRegexStrOptionType {
    name = "posixPathWithSpecial";
    description = "Absolute or relative POSIX path";
    matchAgainstAllOf = ["^(${posix1-2024.pathname.anyRE})$"];
  };

  posixUserName = mkRegexStrOptionType {
    name = "posixUserName";
    description = "POSIX user name";
    matchAgainstAllOf = ["^(${posix1-2024.usernameRE})$"];
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

  ipv4Addr = mkRegexStrOptionType {
    name = "ipv4Addr";
    description = "IPv4 address in four-octets decimal notation";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})$"];
  };
  ipv4Cidr = mkRegexStrOptionType {
    name = "ipv4Cidr";
    description = "IPv4 address in four-octets decimal notation plus subnet in CIDR notation";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})(${cidr.ipv4SuffixRE})$"];
  };
  ipv4AddrWithPort = mkRegexStrOptionType {
    name = "ipv4AddrWithPort";
    description = "IPv4 address in four-octets decimal notation with port";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})[:](${rfc9293.portNumberRE})$"];
  };
  ipv6Addr = mkRegexStrOptionType {
    name = "ipv6Addr";
    description = "IPv6 address in colon-hexadecimal notation";
    matchAgainstAllOf = ["^(${rfc3513.ipv6AddressRE})$"];
  };
  ipv6Cidr = mkRegexStrOptionType {
    name = "ipv6Cidr";
    description = "IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation";
    matchAgainstAllOf = ["^(${rfc3513.ipv6AddressRE})(${cidr.ipv6SuffixRE})$"];
  };
  ipv6AddrWithPort = mkRegexStrOptionType {
    name = "ipv6AddrWithPort";
    description = "IPv6 address in colon-hexadecimal notation with port";
    matchAgainstAllOf = ["^[[](${rfc3513.ipv6AddressRE})[]][:](${rfc9293.portNumberRE})$"];
  };

  # as per IETF RFC 6996 section 5
  privateUseAutonomousSystemNumber = lib.mkOptionType {
    name = "privateUseAutonomousSystemNumber";
    description = ''
      Autonomous system number reserved for private use

      Allowed ranges: 64512-65534, 4200000000-4294967294'';
    descriptionClass = "noun";
    check = x:
      builtins.isInt x
      && (
        (x >= 64512 && x <= 65534)
        || (x >= 4200000000 && x <= 4294967294)
      );
  };

  subdomainLabel = mkRfc1123SubdomainLabelType {};
  subdomainName = mkRfc1123SubdomainNameType {};

  urlPathSegment = urlPathSegmentType;
  relativeUrlPath = relativeUrlPathType;
  httpxHostUrl = mkRegexStrOptionType {
    name = "httpxHostUrl";
    description = "RFC3986 HTTP(S) URL (scheme and authority only)";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xHostUrlRE})$"];
  };
  httpHostUrl = mkRegexStrOptionType {
    name = "httpHostUrl";
    description = "RFC3986 HTTP URL (scheme and authority only)";
    matchAgainstAllOf = ["^http(${rfc3986.xHostUrlRE})$"];
  };
  httpsHostUrl = mkRegexStrOptionType {
    name = "httpsHostUrl";
    description = "RFC3986 HTTPS URL (scheme and authority only)";
    matchAgainstAllOf = ["^https(${rfc3986.xHostUrlRE})$"];
  };
  httpxHostPathUrl = mkRegexStrOptionType {
    name = "httpxHostPathUrl";
    description = "RFC3986 HTTP(S) URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xHostPathUrlRE})$"];
  };
  httpHostPathUrl = mkRegexStrOptionType {
    name = "httpHostPathUrl";
    description = "RFC3986 HTTP URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^http(${rfc3986.xHostPathUrlRE})$"];
  };
  httpsHostPathUrl = mkRegexStrOptionType {
    name = "httpsHostPathUrl";
    description = "RFC3986 HTTPS URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^https(${rfc3986.xHostPathUrlRE})$"];
  };
  httpxUrl = httpxUrlType;
  httpUrl = mkRegexStrOptionType {
    name = "httpUrl";
    description = "RFC3986 HTTP URL";
    matchAgainstAllOf = ["^http(${rfc3986.xUrlRE})$"];
  };
  httpsUrl = mkRegexStrOptionType {
    name = "httpsUrl";
    description = "RFC3986 HTTPS URL";
    matchAgainstAllOf = ["^https(${rfc3986.xUrlRE})$"];
  };
  xftpUrl = mkRegexStrOptionType {
    name = "xftpUrl";
    description = "RFC3986 (S)FTP URL";
    matchAgainstAllOf = ["^(s)?ftp(${rfc3986.xUrlRE})$"];
  };

  emailAddress = mkRegexStrOptionType {
    name = "emailAddress";
    description = "RFC5322 email address";
    matchAgainstAllOf = ["^(${rfc5322.emailAddressRE})$"];
  };

  ipsecProposalStr = mkRegexStrOptionType {
    name = "ipsecProposalStr";
    description = "IPsec proposal string";
    matchAgainstAllOf = ["^(${strongswan.ipsecProposalStrRE})$"];
  };

  semver2VersionStr = mkRegexStrOptionType {
    name = "semver2VersionStr";
    description = "Semantic version 2 string";
    matchAgainstAllOf = ["^(${semver.v2.versionStrRE})$"];
  };

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

  k8sClusterName = nonEmptyNonSpacedStr;
  k8sVersion = versions: let
    inherit (builtins) concatStringsSep foldl' length map typeOf;
  in
    assert lib.assertMsg
    (typeOf versions == "list")
    "k8sVersion: versions must be a list, not ${typeOf versions}";
    assert lib.assertMsg
    (length versions > 0)
    "k8sVersion: versions must contain at least one item";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (typeOf x == "list")) true versions)
    "k8sVersion: versions must provide each version as a list";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (length x == 2)) true versions)
    "k8sVersion: versions must only contain major and minor version";
      mkRegexStrOptionType {
        name = "k8sVersion";
        description = ''
          Kubernetes version (one of: ${
            concatStringsSep ", " (
              map (
                vv: "${concatStringsSep "." (map (v: toString v) vv)}.x"
              )
              versions
            )
          })'';
        # build a single regular expression to match the specified combinations of
        #  major and minor version plus any patch version
        #  Example: [[1 30] [1 31]] -> [ "^((1[.]30)|(1[.]31))[.][0-9]+$" ]
        matchAgainstAllOf = [
          "^(${
            concatStringsSep "|" (
              map (vv: "(${
                concatStringsSep "[.]" (map (v: toString v) vv)
              })")
              versions
            )
          })[.][0-9]+$"
        ];
      };
  k8sQuantity = mkRegexStrOptionType {
    name = "k8sQuantity";
    description = "Kubernetes quantity";
    matchAgainstAllOf = ["^(${k8s.quantityRE})$"];
  };
  k8sThreshold = mkRegexStrOptionType {
    name = "k8sThreshold";
    description = "Kubernetes threshold";
    matchAgainstAllOf = ["^(${k8s.quantityRE}|(0|[1-9][0-9]*)%)$"];
  };
  # as per https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  k8sServiceType = lib.types.enum [
    "ClusterIP"
    "NodePort"
    "LoadBalancer"
    "ExternalName"
  ];

  # as per https://kubernetes.io/docs/reference/kubernetes-api/
  # and https://kubernetes.io/docs/concepts/overview/working-with-objects/names
  # NOTE: Although capitals are valid as per the RFCs, Kubernetes rejects them
  # NOTE: k8sObjectName is an unspecific type and should be avoided if possible
  k8sObjectName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sNamespaceName = lib.types.oneOf [
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sStorageClassName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sSecretName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sServiceName = mkRfc1035SubdomainLabelType {rejectCapitals = true;};
  k8sIngressClassName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sIssuerName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sPodContainerName = lib.types.oneOf [
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sLabelPrefix = mkRegexStrOptionType {
    name = "k8sLabelPrefix";
    description = "Kubernetes label prefix";
    matchAgainstAllOf = [
      "^(${k8s.labelPrefixRE})$"

      # length<=253 (WORKAROUND: This should have been encoded in k8s.labelPrefixRE with positive lookaheads but these are unsupported)
      "^.{0,253}$"
    ];
  };
  k8sLabelValue = mkRegexStrOptionType {
    name = "k8sLabelValue";
    description = "Kubernetes label value";
    matchAgainstAllOf = [
      "^(${k8s.labelValueRE})$"

      # length<=63 (WORKAROUND: This should have been encoded in k8s.labelValueRE with positive lookaheads but these are unsupported)
      "^.{0,63}$"
    ];
  };
  k8sLabel = mkRegexStrOptionType {
    name = "k8sLabel";
    description = "Kubernetes label";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})$"

      # prefixLength<=253, nameLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE with positive lookaheads but these are unsupported)
      "^([^/]{0,253}[/])?([^/]{0,63})$"
    ];
  };
  k8sLabelStr = mkRegexStrOptionType {
    name = "k8sLabelStr";
    description = "Kubernetes label string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})=(${k8s.labelValueRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=]{0,253}[/])?([^/=]{0,63})[=]([^=]{0,63})$"
    ];
  };
  k8sLabelAttrs = lib.mkOptionType {
    name = "k8sLabelAttrs";
    description = "attribute set of Kubernetes label-value pairs";
    descriptionClass = "noun";
    check = x:
      builtins.isAttrs x
      && (
        lib.attrsets.foldlAttrs (
          acc: label: value:
            acc && k8sLabel.check label && k8sLabelValue.check value
        )
        true
        x
      );
  };

  k8sTaintStr = mkRegexStrOptionType {
    name = "k8sTaintStr";
    description = "Kubernetes taint string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})(=(${k8s.labelValueRE}))?:(${k8s.taintEffectRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=:]{0,253}[/])?([^/=:]{0,63})([=][^=:]{0,63})?([:][^:]+)$"
    ];
  };
  # as per https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-duration
  k8sDurationStr = mkRegexStrOptionType {
    name = "k8sDurationStr";
    description = "Kubernetes duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };
  k8sImageRef = mkRegexStrOptionType {
    name = "k8sImageRef";
    description = "Kubernetes container image reference";
    matchAgainstAllOf = ["^(${k8s.imageRefRE})$"];
  };

  # as per https://v3.helm.sh/docs/topics/chart_repository/
  helmChartRepoUrl = httpxUrlType;
  helmChartReleaseName = mkRegexStrOptionType {
    name = "helmChartReleaseName";
    description = "Helm chart release name";
    matchAgainstAllOf = [
      "^(${helm.v3.chartReleaseNameRE})$"

      # 1<=length<=53 (WORKAROUND: This should have been encoded in helm.v3.chartReleaseNameRE with positive lookaheads but these are unsupported)
      "^.{1,53}$"
    ];
  };
  helmChartVersion = mkRegexStrOptionType {
    name = "helmChartVersion";
    description = "Helm chart version (Semantic version 2 string or OCI image tag)";
    matchAgainstAllOf = ["^(${helm.v3.chartVersionRE})$"];
  };
  helmChartRef = relativeUrlPathType;

  # as per https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
  terraformDurationStr = mkRegexStrOptionType {
    name = "terraformDurationStr";
    description = "Terraform duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };

  base64Str = mkRegexStrOptionType {
    name = "base64Str";
    description = "Base64 encoded string";
    matchAgainstAllOf = ["^(${rfc4648.base64StrRE})$"];
  };
  wireguardKey = mkRegexStrOptionType {
    name = "wireguardKey";
    description = "Wireguard key";
    matchAgainstAllOf = [
      "^(${rfc4648.base64StrRE})$"

      # length=44 (WORKAROUND: This should have been encoded in base64StrRE with positive lookaheads but these are unsupported)
      "^.{44}$"
    ];
  };

  prometheusIntervalStr = mkRegexStrOptionType {
    name = "prometheusIntervalStr";
    description = "Prometheus interval string";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusDurationRE})$"];
  };
  prometheusLabelName = mkRegexStrOptionType {
    name = "prometheusLabelName";
    description = "Prometheus label name";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusLabelNameRE})$"];
  };
  prometheusTimeoutStr = mkRegexStrOptionType {
    name = "prometheusTimeoutStr";
    description = "Prometheus timeout string";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusDurationRE})$"];
  };
  # as per https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.RelabelConfig
  # without inter-field dependencies and constraints
  prometheusRelabelConfig = attrsOf' {
    sourceLabels = lib.types.listOf prometheusLabelName;
    separator = lib.types.str;
    targetLabel = prometheusLabelName;
    regex = lib.types.nonEmptyStr;
    # NOTE: for some reason `types.ints.u64` is not made available
    modulus = lib.types.ints.unsigned;
    replacement = lib.types.nonEmptyStr;
    action = lib.types.nonEmptyStr;
  };

  s3BucketName = mkRegexStrOptionType {
    name = "s3BucketName";
    description = "S3 bucket name";
    matchAgainstAllOf = [
      "^(${s3.bucket.name.RE})$"
    ];
    matchAgainstNoneOf = s3.bucket.name.prefix.negativeREs;
  };
  s3BucketNamePrefix = mkRegexStrOptionType {
    name = "s3BucketNamePrefix";
    description = "S3 bucket name prefix";
    matchAgainstAllOf = [
      "^(${s3.bucket.name.prefix.RE})$"
    ];
    matchAgainstNoneOf = s3.bucket.name.prefix.negativeREs;
  };
}
