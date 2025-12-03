{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    ;
  inherit
    (types.yk8s.networking)
    httpxUrl
    relativeUrlPath
    ;
  inherit (types.yk8s.version._regexes) semver;
  oci = types.yk8s.oci._regexes;
in rec {
  # as per Helm documentation and source code
  _regexes = {
    v3 = let
      # https://github.com/helm/helm/blob/v3.16.2/pkg/chartutil/validate_name.go#L36
      # TODO: enforce 1<=length<=53 (positive lookaheads are not supported unfortunately)
      chartutilValidNameRE = "[a-z0-9]([-a-z0-9]*[a-z0-9])?([.][a-z0-9]([-a-z0-9]*[a-z0-9])?)*";

      # https://helm.sh/docs/topics/charts/#charts-and-versioning
      # (not to be confused with https://helm.sh/docs/chart_best_practices/conventions/#version-numbers)
      # NOTE: not clearly specified but OCI image tags are valid as well
      versionNumberRE = semver.v2.versionStrRE;
      ociImageTagRE = oci.dist1.imageTagRE;
    in {
      chartReleaseNameRE = chartutilValidNameRE;
      chartVersionRE = "(${versionNumberRE})|(${ociImageTagRE})";
    };
  };
  # as per https://v3.helm.sh/docs/topics/chart_repository/
  chartRepoUrl = httpxUrl;
  chartReleaseName = _mkRegexStrOptionType {
    name = "helmChartReleaseName";
    description = "Helm chart release name";
    matchAgainstAllOf = [
      "^(${_regexes.v3.chartReleaseNameRE})$"

      # 1<=length<=53 (WORKAROUND: This should have been encoded in helm.v3.chartReleaseNameRE with positive lookaheads but these are unsupported)
      "^.{1,53}$"
    ];
  };
  chartVersion = _mkRegexStrOptionType {
    name = "helmChartVersion";
    description = "Helm chart version (Semantic version 2 string or OCI image tag)";
    matchAgainstAllOf = ["^(${_regexes.v3.chartVersionRE})$"];
  };
  chartRef = relativeUrlPath;
}
