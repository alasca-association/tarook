{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  inherit
    (lib)
    mapCartesianProduct
    range
    filter
    match
    isList
    head
    intersectLists
    ;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    reusableValues
    yk8s-lib
    ;
  inherit (yk8s-lib.transform) matchesRegex;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "networkingOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      ipv4Addr = {
        target = optionTypes.ipv4Addr;
        tests.typeChecking = {
          accepted.inputs = [
            "192.0.2.0"
            "192.0.2.1"
            "192.0.2.135"
            "198.51.100.0"
            "198.51.100.10"
            "198.51.100.255"
            "203.0.113.0"
            "127.0.0.1"
            "1.1.1.1"
            "100.127.255.255"
            "239.2.5.150"
          ];
          rejected.inputs =
            [
              ""
              "2886794753"
              "0xAC10FE01"
              "127.1"
              "127.65530"
              "192.0.2.0.45"
              ".1.1.1"
              "1.1.1."
            ]
            # ipv4Addr is mutually exclusive with ipv4Cidr, ipv6Addr and ipv6Cidr
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv4Cidr = {
        target = optionTypes.ipv4Cidr;
        tests.typeChecking = {
          # every valid ipv4Addr cidr-suffixed with 0 to 32 is a valid ipv4Cidr
          accepted.inputs = mapCartesianProduct ({
            ipv4Addr,
            ipv4CidrSuffix,
          }: "${ipv4Addr}/${ipv4CidrSuffix}") {
            ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
            ipv4CidrSuffix = map (x: toString x) (range 0 32);
          };
          rejected.inputs =
            [
              ""
              "192.0.2.0"
              "192.0.2.1/33"
              "192.0.2.1/033"
              "192.0.2.135/100"
              "192.0.2.135/"
              "198.51.100.0/-2"
              "2886794753/24"
              "0xAC10FE01/32"
              "127.1/24"
              "127.65530/24"
              ".1.1.1/24"
              "1.1.1./24"
            ]
            # ipv4Cidr is mutually exclusive with ipv4Addr, ipv6Addr and ipv6Cidr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv4AddrWithPort = {
        target = optionTypes.ipv4AddrWithPort;
        tests.typeChecking = {
          accepted.inputs = mapCartesianProduct ({
            ipv4Addr,
            tcpPort,
          }: "${ipv4Addr}:${toString tcpPort}") {
            ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
            tcpPort = reusableValues.rfc9293PortNumbers.valid;
          };
          rejected.inputs =
            [
              ""
              "foobar"
              "foo:bar"
              "example.com:443"
              "127.0.0.1:foo"
              ":443"
              "127.0.0.1:"
            ]
            # every combination of ipv4Addr and port number where at least one is invalid
            ++ mapCartesianProduct ({
              invalidIpv4Addr,
              tcpPort,
            }: "${invalidIpv4Addr}:${toString tcpPort}") {
              invalidIpv4Addr = filter (x: matchesRegex "^.+:.+$" x) ipv4Addr.tests.typeChecking.rejected.inputs;
              tcpPort = reusableValues.rfc9293PortNumbers.valid;
            }
            ++ mapCartesianProduct ({
              ipv4Addr,
              invalidTcpPort,
            }: "${ipv4Addr}:${toString invalidTcpPort}") {
              ipv4Addr = ipv4Addr.tests.typeChecking.accepted.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            }
            ++ mapCartesianProduct ({
              invalidIpv4Addr,
              invalidTcpPort,
            }: "${invalidIpv4Addr}:${toString invalidTcpPort}") {
              invalidIpv4Addr = filter (x: matchesRegex "^.+:.+$" x) ipv4Addr.tests.typeChecking.rejected.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };
      ipv6Addr = {
        target = optionTypes.ipv6Addr;
        tests.typeChecking = {
          accepted.inputs = [
            "::"
            "::1"
            "2001:db8::"
            "2001:db8:50b:3034::"
            "fe80::876:7cff:fe9e:2f27"
            "FE80::876:7CFF:fE9E:2F27"
            "3fff::"
            "3FFF::"
          ];
          rejected.inputs =
            [
              ""
              ":"
              "ba732:db:5023bc123:3034:fba:24:34fb:ba74:32d3"
              "hgow23:23saa:13::"
              "349102305239191823"
              "abc-42:23/af"
            ]
            # ipv6Addr is mutually exclusive with ipv4Addr, ipv4Cidr and ipv6Cidr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Cidr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv6Cidr = {
        target = optionTypes.ipv6Cidr;
        tests.typeChecking = {
          # every valid ipv6Addr cidr-suffixed with 0 to 64 is a valid ipv6Cidr
          accepted.inputs = mapCartesianProduct ({
            ipv6Addr,
            ipv6CidrSuffix,
          }: "${ipv6Addr}/${ipv6CidrSuffix}") {
            ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
            ipv6CidrSuffix = map (x: toString x) (range 0 64);
          };
          rejected.inputs =
            [
              ""
              "::/181"
              "3fff::/010"
              "3fff::/"
              "349102305239191823/64"
            ]
            # ipv6Cidr is mutually exclusive with ipv4Addr, ipv4Cidr and ipv6Addr
            ++ ipv4Addr.tests.typeChecking.accepted.inputs
            ++ ipv4Cidr.tests.typeChecking.accepted.inputs
            ++ ipv6Addr.tests.typeChecking.accepted.inputs;
          inherit nonStringValuesRejected;
        };
      };
      ipv6AddrWithPort = {
        target = optionTypes.ipv6AddrWithPort;
        tests.typeChecking = {
          accepted.inputs = mapCartesianProduct ({
            ipv6Addr,
            tcpPort,
          }: "[${ipv6Addr}]:${toString tcpPort}") {
            ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
            tcpPort = reusableValues.rfc9293PortNumbers.valid;
          };
          rejected.inputs =
            [
              ""
              "foobar"
              "foo:bar"
              "example.com:443"
              "[::1]:foo"
              ":443"
              "[::1]:"
            ]
            # every combination of ipv6Addr and port number where at least one is invalid
            ++ mapCartesianProduct ({
              invalidIpv6Addr,
              tcpPort,
            }: "[${invalidIpv6Addr}]:${toString tcpPort}") {
              invalidIpv6Addr = filter (x: matchesRegex "^.+:.+$" x) ipv6Addr.tests.typeChecking.rejected.inputs;
              tcpPort = reusableValues.rfc9293PortNumbers.valid;
            }
            ++ mapCartesianProduct ({
              ipv6Addr,
              invalidTcpPort,
            }: "[${ipv6Addr}]:${toString invalidTcpPort}") {
              ipv6Addr = ipv6Addr.tests.typeChecking.accepted.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            }
            ++ mapCartesianProduct ({
              invalidIpv6Addr,
              invalidTcpPort,
            }: "[${invalidIpv6Addr}]:${toString invalidTcpPort}") {
              invalidIpv6Addr = filter (x: matchesRegex "^.+:.+$" x) ipv6Addr.tests.typeChecking.rejected.inputs;
              invalidTcpPort = reusableValues.rfc9293PortNumbers.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };

      privateUseAutonomousSystemNumber = {
        target = optionTypes.privateUseAutonomousSystemNumber;
        tests.typeChecking = {
          accepted.inputs = [
            4200000000
            4200001000
            4294452900
            4294967294
            64512
            64933
            65534
          ];
          rejected.inputs = [
            4199999999
            4294967295
            64511
            64511.5
            65535
            23849242
            0
            (-34)
            ""
            "foobar"
            "4200001000"
          ];
          nonIntegerValuesRejected.inputs = reusableValues.nonInteger;
        };
      };

      subdomainLabel = {
        target = optionTypes.subdomainLabel;
        tests.typeChecking = {
          accepted.inputs = [
            "foo"
            "4foo"
            "foo-bar-baz"
            "a"
            "ab"
            "loooooooooooooooooooooooooong-subomain-label-with-63-characters"
            "looooooooooooooooooooooooooong-subomain-label-with-64-characters"
          ];
          rejected.inputs = [
            ""
            "foo%bar-label"
            "with spaces "
            "foobar-"
            "-foobar"
            "foo.bar"
          ];
          inherit nonStringValuesRejected;
        };
      };
      subdomainName = {
        target = optionTypes.subdomainName;
        tests.typeChecking = {
          accepted.inputs =
            [
              "foo.bar"
              "foo.bar.baz"
              "FOO.baR.baz"
              "foo-bar.baz"
              "3www.example.com"
              "192.168.0.1"
              "subdomain-name-that-is-253-characters-long.lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-sed-do-eiusmod-tempor-incididunt-ut-labore-et-dolore-magna-aliqua-Ut-enim-ad-minim-veniam-quis-nostrud-exercitation-ullamco-laboris-nisi-ut-aliquip-xxxxxxx"
              "subdomain-name-that-is-254-characters-long.lorem-ipsum-dolor-sit-amet-consectetur-adipiscing-elit-sed-do-eiusmod-tempor-incididunt-ut-labore-et-dolore-magna-aliqua-Ut-enim-ad-minim-veniam-quis-nostrud-exercitation-ullamco-laboris-nisi-ut-aliquip-xxxxxxxx"
            ]
            # subdomainName is a superset of subdomainLabel
            ++ subdomainLabel.tests.typeChecking.accepted.inputs
            ++ map (label: "${label}.example.com") subdomainLabel.tests.typeChecking.accepted.inputs;
          rejected.inputs = [
            ""
            "foo%bar-label"
            "with spaces "
            "foobar-"
            "-foobar"
            "foo_bar.baz"
            ".example.com"
            "example.com."
            "-.example.com"
            "a-.example.com"
            "a-.example.com"
            "foo.-example.com"
          ];
          inherit nonStringValuesRejected;
        };
      };

      urlPathSegment = {
        target = optionTypes.urlPathSegment;
        tests.typeChecking = {
          accepted.inputs = [
            "urlpathsegment"
            "url%20path%20segment%20with%20%25-encoded%20spaces"
            "index.html"
            "."
          ];
          rejected.inputs = [
            ""
            "url path segment with spaces"
            "invalid%G3char%3kencoding"
            "path-segment-with#fragment"
            "relative/path"
            "/absolute/path"
          ];
          inherit nonStringValuesRejected;
        };
      };
      relativeUrlPath = {
        target = optionTypes.relativeUrlPath;
        tests.typeChecking = {
          accepted.inputs =
            [
              "relative/path"
              "relative/path/"
              "relative_path/foobar"
              "~/-weird_URL/$path=foo;bar+a(5*3,4)&/@:'"
              "."
            ]
            # relativeUrlPath is a superset of urlPathSegment
            ++ urlPathSegment.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [
              ""
              "/absolute/path"
              "path/with?query"
              "path/with#fragment"
              "path/with€unencoded`chars^"
            ]
            # relativeUrlPath is a superset of urlPathSegment
            ++ filter (x: matchesRegex "^[^/]*$" x) urlPathSegment.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpHostUrl = {
        target = optionTypes.httpHostUrl;
        tests.typeChecking = {
          accepted.inputs = [
            "http://example.com"
            "http://example.com:443"
            "http://example.com:" # allowed but URL normalizers should omit the ':'
            "http://user@example.com"
            "http://foo:aF0._~-!$&'()*+,;=%20@example.com"
            "http://uid=john.doe,ou=foo&bar,dc=example,dc=com@example.com"
          ];
          rejected.inputs = [
            ""
            "http://example.com/"
            "http://example.com/with/path"
            "http://user@here@example.com"
            "ftp://example.com"
            "https://" # valid URL but invalid for the http scheme
            "https://user@" # valid URL but invalid for the http scheme
          ];
          inherit nonStringValuesRejected;
        };
      };
      httpsHostUrl = {
        target = optionTypes.httpsHostUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpHostUrl starting with 'https' instead of 'http' becomes a httpsHostUrl
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpHostUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # every invalid httpHostUrl that does not start with 'https' is also an invalid httpsHostUrl
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpHostUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxHostUrl = {
        target = optionTypes.httpxHostUrl;
        # httpxHostUrl is a superset of httpHostUrl and httpsHostUrl
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpHostUrl.tests.typeChecking.accepted.inputs
            ++ httpsHostUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpHostUrl.tests.typeChecking.rejected.inputs
            httpsHostUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxHostPathUrl = {
        target = optionTypes.httpxHostPathUrl;
        # httpxHostPathUrl is a superset of httpHostPathUrl and httpsHostPathUrl
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpHostPathUrl.tests.typeChecking.accepted.inputs
            ++ httpsHostPathUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpHostPathUrl.tests.typeChecking.rejected.inputs
            httpsHostPathUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpHostPathUrl = {
        target = optionTypes.httpHostPathUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # httpHostPathUrl is a superset of httpHostUrl
            ++ httpHostUrl.tests.typeChecking.accepted.inputs
            # every httpHostUrl with a path appended becomes a httpHostPathUrl
            ++ map (url: "${url}/with/path")
            httpHostUrl.tests.typeChecking.accepted.inputs
            # every concatenation with '/' of httpHostUrl and relativeUrlPath becomes a httpHostPathUrl
            ++ mapCartesianProduct ({
              httpHostUrl,
              relativeUrlPath,
            }: "${httpHostUrl}/${relativeUrlPath}") {
              httpHostUrl = httpHostUrl.tests.typeChecking.accepted.inputs;
              relativeUrlPath = relativeUrlPath.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [""]
            # every concatenation with '/' of a valid httpHostUrl and an invalid relativeUrlPath (that does not start with '/') is an invalid httpHostPathUrl
            ++ mapCartesianProduct ({
              httpHostUrl,
              invalidRelativeUrlPath,
            }: "${httpHostUrl}/${invalidRelativeUrlPath}") {
              httpHostUrl = httpHostUrl.tests.typeChecking.accepted.inputs;
              invalidRelativeUrlPath =
                filter (x: matchesRegex "^[^/].*$" x) relativeUrlPath.tests.typeChecking.rejected.inputs;
            }
            # every concatenation with '/' of an invalid httpHostUrl and a valid relativeUrlPath is an invalid httpHostPathUrl
            ++ mapCartesianProduct ({
              invalidHttpHostUrl,
              relativeUrlPath,
            }: "${invalidHttpHostUrl}/${relativeUrlPath}") {
              invalidHttpHostUrl = [
                "http://user@here@example.com"
                "ftp://example.com"
                "https://" # valid URL but invalid for the http scheme
                "https://user@" # valid URL but invalid for the http scheme
              ];
              relativeUrlPath = relativeUrlPath.tests.typeChecking.accepted.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };
      httpsHostPathUrl = {
        target = optionTypes.httpsHostPathUrl;
        tests.typeChecking = {
          # every valid httpHostPathUrl starting with 'https' instead of 'http' becomes a httpsHostPathUrl
          accepted.inputs =
            []
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpHostPathUrl.tests.typeChecking.accepted.inputs;
          # every invalid httpHostPathUrl that does not start with 'https' is also an invalid httpsHostPathUrl
          rejected.inputs =
            [""]
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpHostPathUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      httpxUrl = {
        target = optionTypes.httpxUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            ++ httpUrl.tests.typeChecking.accepted.inputs
            ++ httpsUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            ++ intersectLists
            httpUrl.tests.typeChecking.rejected.inputs
            httpsUrl.tests.typeChecking.rejected.inputs;
        };
      };
      httpUrl = {
        target = optionTypes.httpUrl;
        tests.typeChecking = let
          urlQueryFragments.valid = [
            "?query"
            "#fragment"
            "?query#fragment"
            "#fragment?actually-not-a-query"
            "#fragment/With-all_unencoded~ch?rs.Foo"
            "?/query?With-#all_unencoded~chars.Foo"
            "#query%20with%20%25-encoded%20spaces"
          ];
        in {
          accepted.inputs =
            []
            # httpUrl is a superset of httpHost(Path)Url
            ++ httpHostPathUrl.tests.typeChecking.accepted.inputs
            # every httpHostPathUrl with a fragment and or query appended is a valid httpUrl
            ++ mapCartesianProduct ({
              hostPathUrl,
              urlQueryFragment,
            }: "${hostPathUrl}${urlQueryFragment}") {
              hostPathUrl = httpHostPathUrl.tests.typeChecking.accepted.inputs;
              urlQueryFragment = urlQueryFragments.valid;
            };
          rejected.inputs =
            [""]
            # every concatenation of a valid httpHostPathUrl and an invalid fragment or query is an invalid httpUrl
            ++ mapCartesianProduct ({
              httpHostPathUrl,
              invalidUrlQueryFragment,
            }: "${httpHostPathUrl}${invalidUrlQueryFragment}") {
              httpHostPathUrl = httpHostPathUrl.tests.typeChecking.accepted.inputs;
              invalidUrlQueryFragment = [
                "?query%8Xwith%JKinvalid%G3char%3kencoding"
                "#fragment%8Xwith%JKinvalid%G3char%3kencoding"
                "?valid-query#fragment%8Xwith%JKinvalid%G3char%3kencoding"
                "?query with€unencoded`chars^"
                "#fragment with€unencoded`chars^"
                "?valid-query#fragment with€unencoded`chars^"
              ];
            }
            # every concatenation of an invalid httpHostPathUrl and a valid fragment or query is an invalid httpUrl
            ++ mapCartesianProduct ({
              invalidHttpHostPathUrl,
              urlQueryFragment,
            }: "${invalidHttpHostPathUrl}${urlQueryFragment}") {
              invalidHttpHostPathUrl = [
                "http://user@here@example.com"
                "ftp://example.com"
                "https://" # valid URL but invalid for the http scheme
                "https://user@" # valid URL but invalid for the http scheme
              ];
              urlQueryFragment = urlQueryFragments.valid;
            };
          inherit nonStringValuesRejected;
        };
      };
      httpsUrl = {
        target = optionTypes.httpsUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpUrl starting with 'https' instead of 'http' becomes a httpsUrl
            ++ map (
              url: let
                m = match "^http(.*)$" url;
              in
                if isList m
                then "https${head m}"
                else url
            )
            httpUrl.tests.typeChecking.accepted.inputs;
          rejected.inputs =
            [""]
            # every invalid httpUrl that does not start with 'https' is also an invalid httpsUrl
            ++ map (
              url: let
                m = match "^https(.*)$" url;
              in
                if isList m
                then "http${head m}"
                else url
            )
            httpUrl.tests.typeChecking.rejected.inputs;
          inherit nonStringValuesRejected;
        };
      };
      xftpUrl = {
        target = optionTypes.xftpUrl;
        tests.typeChecking = {
          accepted.inputs =
            []
            # every valid httpUrl starting with 'ftp' or 'sftp' instead of 'http' becomes a xftpUrl
            ++ mapCartesianProduct ({
              xftpUrlScheme,
              urlWithoutScheme,
            }: "${xftpUrlScheme}${urlWithoutScheme}") {
              xftpUrlScheme = ["ftp" "sftp"];
              urlWithoutScheme =
                map (
                  url: let
                    m = match "^http(.*)$" url;
                  in
                    if isList m
                    then head m
                    else url
                )
                httpUrl.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [""]
            # every invalid httpUrl that does not start with 'ftp' or 'sftp' is also an invalid xftpUrl
            ++ mapCartesianProduct ({
              xftpUrlScheme,
              urlWithoutScheme,
            }: "${xftpUrlScheme}${urlWithoutScheme}") {
              xftpUrlScheme = ["ftp" "sftp"];
              urlWithoutScheme =
                map (
                  url: let
                    m = match "^http(.*)$" url;
                  in
                    if isList m
                    then head m
                    else url
                )
                httpUrl.tests.typeChecking.rejected.inputs;
            };
          inherit nonStringValuesRejected;
        };
      };

      emailAddress = {
        target = optionTypes.emailAddress;
        tests.typeChecking = let
          localParts = {
            valid = [
              "user"
              "forname.surname"
              "!#$%&'*+-/=?^_`{|}~user.0815"
              "!!##\$\$%%&&''**++--//==??^^__``{{||}}~~uusseerr.00881155"
              "a.b"
            ];
            invalid = [
              ""
              " "
              "(comment)user"
              "user@domain"
              "user..sd"
              ".user"
              "user."
            ];
          };
          domainParts = {
            valid = [
              "domain"
              "domain.tld"
              "!#$%&'*+-/=?^_`{|}~domain.0815"
              "!!##\$\$%%&&''**++--//==??^^__``{{||}}~~doommaaiinn.00881155"
              "a.b"
            ];
            invalid = [
              ""
              " "
              "domain.tld(comment)"
              "user@domain"
              ".domain"
              "domain."
            ];
          };
        in {
          accepted.inputs = mapCartesianProduct ({
            localPart,
            domainPart,
          }: "${localPart}@${domainPart}") {
            localPart = localParts.valid;
            domainPart = domainParts.valid;
          };
          rejected.inputs =
            [""]
            # Any local/domain part (without '@') on their own is not a valid emailAddress
            ++ localParts.valid
            ++ filter (x: matchesRegex "^[^@]*$" x) localParts.invalid
            ++ domainParts.valid
            ++ filter (x: matchesRegex "^[^@]*$" x) domainParts.invalid
            # Any email address with an invalid local part is invalid
            ++ mapCartesianProduct ({
              invalidLocalPart,
              domainPart,
            }: "${invalidLocalPart}@${domainPart}") {
              invalidLocalPart = localParts.invalid;
              domainPart = domainParts.valid;
            }
            # Any email address with an invalid domain part is invalid
            ++ mapCartesianProduct ({
              localPart,
              invalidDomainPart,
            }: "${localPart}@${invalidDomainPart}") {
              localPart = localParts.valid;
              invalidDomainPart = domainParts.invalid;
            };
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
