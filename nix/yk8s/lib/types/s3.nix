{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    s3
    ;
in {
  bucketName = mkRegexStrOptionType {
    name = "s3BucketName";
    description = "S3 bucket name";
    matchAgainstAllOf = [
      "^(${s3.bucket.name.RE})$"
    ];
    matchAgainstNoneOf = s3.bucket.name.prefix.negativeREs;
  };

  bucketNamePrefix = mkRegexStrOptionType {
    name = "s3BucketNamePrefix";
    description = "S3 bucket name prefix";
    matchAgainstAllOf = [
      "^(${s3.bucket.name.prefix.RE})$"
    ];
    matchAgainstNoneOf = s3.bucket.name.prefix.negativeREs;
  };
}
