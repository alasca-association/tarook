{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s)
    attrsOf'
    ;
  k8s = types.yk8s.k8s._regexes;
in rec {
  intervalStr = _mkRegexStrOptionType {
    name = "prometheusIntervalStr";
    description = "Prometheus interval string";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusDurationRE})$"];
  };
  labelName = _mkRegexStrOptionType {
    name = "prometheusLabelName";
    description = "Prometheus label name";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusLabelNameRE})$"];
  };
  timeoutStr = _mkRegexStrOptionType {
    name = "prometheusTimeoutStr";
    description = "Prometheus timeout string";
    matchAgainstAllOf = ["^(${k8s.coreos-monitoring.v1.prometheusDurationRE})$"];
  };
  # as per https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.RelabelConfig
  # without inter-field dependencies and constraints
  relabelConfig = attrsOf' {
    sourceLabels = lib.types.listOf labelName;
    separator = lib.types.str;
    targetLabel = labelName;
    regex = lib.types.nonEmptyStr;
    # NOTE: for some reason `types.ints.u64` is not made available
    modulus = lib.types.ints.unsigned;
    replacement = lib.types.nonEmptyStr;
    action = lib.types.nonEmptyStr;
  };
}
