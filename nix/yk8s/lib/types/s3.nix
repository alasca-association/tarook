{lib}: let
  common = (import ./_common) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    s3
    ;
in {
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
