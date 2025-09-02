{lib}: let
  common = (import ./_common.nix) {inherit lib;};
  inherit
    (common)
    mkRegexStrOptionType
    k8s
    ;
in rec {
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
}
