{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    rfc952
    rfc3513
    rfc3986
    rfc5322
    rfc9293
    cidr
    mkRfc1123SubdomainNameType
    mkRfc1123SubdomainLabelType
    httpxUrlType
    relativeUrlPathType
    urlPathSegmentType
    strongswan
    ;
in {
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
}
