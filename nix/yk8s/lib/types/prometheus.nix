{lib}: let
  common = (import ./_common) {inherit lib;};
  inherit
    (common)
    attrsOf'
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
}
