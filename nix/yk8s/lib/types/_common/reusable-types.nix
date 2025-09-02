{lib}: let
  typeGenerators = import ./type-generators.nix {inherit lib;};
  regex = import ./regex.nix {inherit lib;};
  inherit (typeGenerators) mkRegexStrOptionType;
  inherit (regex) rfc1035 rfc1123 rfc3986;
in {
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
}
