{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  k8s = types.yk8s.k8s._regexes;
in {
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
}
