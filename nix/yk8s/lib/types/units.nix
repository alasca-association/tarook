{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s.units._regexes)
    isoiec80000
    ;
in {
  _regexes = {
    # as per ISO/IEC 80000
    isoiec80000 = {
      bytes = {
        power10RE = "[0-9]+.[0-9]+([kMGTPEZYRQ]B)|[1-9][0-9]*([kMGTPEZYRQ]B)";
        power2RE = "[0-9]+.[0-9]+([KMGTPEZY]iB)|[1-9][0-9]*([KMGTPEZY]iB)";
      };
    };
  };

  bytesPower10 = _mkRegexStrOptionType {
    name = "bytesPower10";
    description = "Bytes with units based on powers of 10";
    matchAgainstAllOf = ["^(${isoiec80000.bytes.power10RE})$"];
  };
  bytesPower2 = _mkRegexStrOptionType {
    name = "bytesPower2";
    description = "Bytes with units based on powers of 2";
    matchAgainstAllOf = ["^(${isoiec80000.bytes.power2RE})$"];
  };
}
