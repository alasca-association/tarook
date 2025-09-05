{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s.networking._regexes)
    rfc952
    rfc3513
    ;
in rec {
  _regexes = rec {
    # as per https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
    # (without the prefix and suffix specifics)
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
  bucketName = _mkRegexStrOptionType {
    name = "s3BucketName";
    description = "S3 bucket name";
    matchAgainstAllOf = [
      "^(${_regexes.bucket.name.RE})$"
    ];
    matchAgainstNoneOf = _regexes.bucket.name.prefix.negativeREs;
  };

  bucketNamePrefix = _mkRegexStrOptionType {
    name = "s3BucketNamePrefix";
    description = "S3 bucket name prefix";
    matchAgainstAllOf = [
      "^(${_regexes.bucket.name.prefix.RE})$"
    ];
    matchAgainstNoneOf = _regexes.bucket.name.prefix.negativeREs;
  };
}
