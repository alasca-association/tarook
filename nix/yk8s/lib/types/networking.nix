{lib}: let
  types = (import ./.) {inherit lib;};

  inherit (lib.options) mergeEqualOption;

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;

  inherit
    (types.yk8s.networking._regexes)
    rfc952
    rfc1035
    rfc1123
    rfc2234
    rfc3513
    rfc3986
    rfc5234
    rfc5322
    rfc9293
    cidr
    strongswan
    ;
in rec {
  _regexes = {
    cidr = {
      ipv4SuffixRE = "[/]([0-9]|[12][0-9]|3[0-2])";
      ipv6SuffixRE = "[/]((1([0-7][0-9]|80))|([1-9]?[0-9]))";
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

    # as per IETF RFC 2234
    rfc2234 = rec {
      # Section 6.1
      ALPHA = "[A-Za-z]";
      DIGIT = "[0-9]";
      HEXDIG = "${DIGIT}|[A-F]";
    };

    # as per IETF RFC 3513
    rfc3513 = {
      # Section 2.2
      # NOTE: The regex of IETF RFC 3986 is used here because that one was modelled according to an ABNF expression
      #       which matches the address text representation described in IETF RFC 3513.
      ipv6AddressRE = rfc3986.ipv6AddressRE;
    };

    # as per IETF RFC 3986
    rfc3986 = rec {
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
      urlRE = mkUriRE {
        inherit schemeRE;
        hierPartRE = "//(${authorityRE})(${pathAbEmptyRE})"; # Section 3
        withQuery = true;
        withFragment = true;
      };
    };

    # as per IETF RFC 4648
    rfc4648 = let
      # Section 4
      B64CHAR = "[a-z0-9A-Z+/]";
      base64StrRE = "(${B64CHAR}{4})*(${B64CHAR})((${B64CHAR})==|(${B64CHAR}){2}=|(${B64CHAR}){3})";
    in {
      inherit base64StrRE;
    };

    # as per IETF RFC 5234
    rfc5234 = let
      # Appendix B.1
      ALPHA = "[A-Za-z]";
      DIGIT = "[0-9]";
    in {
      inherit ALPHA DIGIT;
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

    # as per IETF RFC 9293
    rfc9293 = {
      # Section 3.1
      portNumberRE = "(6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([0-5]{1,5})|([0-9]{1,4})";
    };

    # as per Strongswan documentation
    strongswan = let
      algoNameRE = "[A-Za-z0-9_]+"; # without matching any allowed algorithm names
      # https://docs.strongswan.org/docs/latest/config/proposals.html#_general_proposal_format
      ipsecProposalStrRE = "(${algoNameRE})([-](${algoNameRE}))*";
    in {
      inherit ipsecProposalStrRE;
    };
  };
  _mkRfc1035SubdomainLabelType = {rejectCapitals ? false}:
    _mkRegexStrOptionType {
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
  _mkRfc1035SubdomainNameType = {rejectCapitals ? false}:
    _mkRegexStrOptionType {
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
  _mkRfc1123SubdomainLabelType = {
    rejectCapitals ? false,
    enforceMaxLength63 ? false,
  }:
    _mkRegexStrOptionType {
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
  _mkRfc1123SubdomainNameType = {
    rejectCapitals ? false,
    enforceMaxLength253_63 ? false,
  }:
    _mkRegexStrOptionType {
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

  ipv4Addr = _mkRegexStrOptionType {
    name = "ipv4Addr";
    description = "IPv4 address in four-octets decimal notation";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})$"];
  };
  ipv4Cidr = _mkRegexStrOptionType {
    name = "ipv4Cidr";
    description = "IPv4 address in four-octets decimal notation plus subnet in CIDR notation";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})(${cidr.ipv4SuffixRE})$"];
  };
  ipv4AddrWithPort = _mkRegexStrOptionType {
    name = "ipv4AddrWithPort";
    description = "IPv4 address in four-octets decimal notation with port";
    matchAgainstAllOf = ["^(${rfc952.ipv4AddrRE})[:](${rfc9293.portNumberRE})$"];
  };
  ipv6Addr = _mkRegexStrOptionType {
    name = "ipv6Addr";
    description = "IPv6 address in colon-hexadecimal notation";
    matchAgainstAllOf = ["^(${rfc3513.ipv6AddressRE})$"];
  };
  ipv6Cidr = _mkRegexStrOptionType {
    name = "ipv6Cidr";
    description = "IPv6 address in colon-hexadecimal notation plus subnet in CIDR notation";
    matchAgainstAllOf = ["^(${rfc3513.ipv6AddressRE})(${cidr.ipv6SuffixRE})$"];
  };
  ipv6AddrWithPort = _mkRegexStrOptionType {
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
    merge = mergeEqualOption;
    check = x:
      builtins.isInt x
      && (
        (x >= 64512 && x <= 65534)
        || (x >= 4200000000 && x <= 4294967294)
      );
  };
  subdomainLabel = _mkRfc1123SubdomainLabelType {};
  subdomainName = _mkRfc1123SubdomainNameType {};

  urlPathSegment = _mkRegexStrOptionType {
    name = "relativeUrlPath";
    description = "RFC3986 URL path segment (pchar)";
    matchAgainstAllOf = ["^(${rfc3986.segmentNzRE})$"]; # use non-zero segment here to avoid bugs
  };
  relativeUrlPath = _mkRegexStrOptionType {
    name = "relativeUrlPath";
    description = "RFC3986 relative URL path";
    matchAgainstAllOf = ["^(${rfc3986.pathRootlessRE})$"];
  };
  httpxHostUrl = _mkRegexStrOptionType {
    name = "httpxHostUrl";
    description = "RFC3986 HTTP(S) URL (scheme and authority only)";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xHostUrlRE})$"];
  };
  httpHostUrl = _mkRegexStrOptionType {
    name = "httpHostUrl";
    description = "RFC3986 HTTP URL (scheme and authority only)";
    matchAgainstAllOf = ["^http(${rfc3986.xHostUrlRE})$"];
  };
  httpsHostUrl = _mkRegexStrOptionType {
    name = "httpsHostUrl";
    description = "RFC3986 HTTPS URL (scheme and authority only)";
    matchAgainstAllOf = ["^https(${rfc3986.xHostUrlRE})$"];
  };
  httpxHostPathUrl = _mkRegexStrOptionType {
    name = "httpxHostPathUrl";
    description = "RFC3986 HTTP(S) URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xHostPathUrlRE})$"];
  };
  httpHostPathUrl = _mkRegexStrOptionType {
    name = "httpHostPathUrl";
    description = "RFC3986 HTTP URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^http(${rfc3986.xHostPathUrlRE})$"];
  };
  httpsHostPathUrl = _mkRegexStrOptionType {
    name = "httpsHostPathUrl";
    description = "RFC3986 HTTPS URL (scheme, authority and path only)";
    matchAgainstAllOf = ["^https(${rfc3986.xHostPathUrlRE})$"];
  };
  httpxUrl = _mkRegexStrOptionType {
    name = "httpxUrl";
    description = "RFC3986 HTTP(S) URL";
    matchAgainstAllOf = ["^http(s)?(${rfc3986.xUrlRE})$"];
  };
  httpUrl = _mkRegexStrOptionType {
    name = "httpUrl";
    description = "RFC3986 HTTP URL";
    matchAgainstAllOf = ["^http(${rfc3986.xUrlRE})$"];
  };
  httpsUrl = _mkRegexStrOptionType {
    name = "httpsUrl";
    description = "RFC3986 HTTPS URL";
    matchAgainstAllOf = ["^https(${rfc3986.xUrlRE})$"];
  };

  xftpUrl = _mkRegexStrOptionType {
    name = "xftpUrl";
    description = "RFC3986 (S)FTP URL";
    matchAgainstAllOf = ["^(s)?ftp(${rfc3986.xUrlRE})$"];
  };

  url = urlWith {schemeRE = rfc3986.schemeRE;};
  urlWith = {schemeRE}:
    _mkRegexStrOptionType {
      name = "url";
      description = "RFC3986 URL";
      matchAgainstAllOf = [
        "^(${rfc3986.urlRE})$"
        "^(${schemeRE}):.*$"
      ];
    };

  emailAddress = _mkRegexStrOptionType {
    name = "emailAddress";
    description = "RFC5322 email address";
    matchAgainstAllOf = ["^(${rfc5322.emailAddressRE})$"];
  };

  ipsecProposalStr = _mkRegexStrOptionType {
    name = "ipsecProposalStr";
    description = "IPsec proposal string";
    matchAgainstAllOf = ["^(${strongswan.ipsecProposalStrRE})$"];
  };
}
