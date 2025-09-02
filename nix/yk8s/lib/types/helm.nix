{lib}: let
  common = (import ./_common) {inherit lib;};
  inherit
    (common)
    httpxUrlType
    mkRegexStrOptionType
    relativeUrlPathType
    helm
    ;
in {
  # as per https://v3.helm.sh/docs/topics/chart_repository/
  helmChartRepoUrl = httpxUrlType;
  helmChartReleaseName = mkRegexStrOptionType {
    name = "helmChartReleaseName";
    description = "Helm chart release name";
    matchAgainstAllOf = [
      "^(${helm.v3.chartReleaseNameRE})$"

      # 1<=length<=53 (WORKAROUND: This should have been encoded in helm.v3.chartReleaseNameRE with positive lookaheads but these are unsupported)
      "^.{1,53}$"
    ];
  };
  helmChartVersion = mkRegexStrOptionType {
    name = "helmChartVersion";
    description = "Helm chart version (Semantic version 2 string or OCI image tag)";
    matchAgainstAllOf = ["^(${helm.v3.chartVersionRE})$"];
  };
  helmChartRef = relativeUrlPathType;
}
