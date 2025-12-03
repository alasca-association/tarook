{lib}: let
  types = (import ./.) {inherit lib;};

  inherit
    (types.yk8s.strings)
    _mkRegexStrOptionType
    _nonEmptyNonSpacedStr
    ;
  inherit
    (types.yk8s.networking)
    _mkRfc1123SubdomainNameType
    _mkRfc1035SubdomainLabelType
    _mkRfc1123SubdomainLabelType
    ;
  inherit
    (types.yk8s.networking._regexes)
    rfc1123
    rfc9293
    ;
  inherit (types.yk8s._regexes) golang;

  oci = types.yk8s.oci._regexes;
  k8s = types.yk8s.k8s._regexes;
in rec {
  # as per Kubernetes documentation
  _regexes = {
    # https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/
    # TODO: enforce quantity is lower than 2^63-1
    quantityRE = let
      quantityRE_ = "(${signedNumberRE})(${suffixRE})";
      DIGIT = "[0-9]";
      digitsRE = "${DIGIT}+";
      decimalPlaceDigitsRE = "${DIGIT}{1,3}"; # constrain to max 3 decimal places
      numberRE = "(${digitsRE})|(${digitsRE})[.](${decimalPlaceDigitsRE})|(${digitsRE})[.]|[.](${decimalPlaceDigitsRE})";
      SIGN = "[+-]";
      signedNumberRE = "(${numberRE})|${SIGN}(${numberRE})";
      suffixRE = "(${binarySiRE})|(${decimalExponentRE})|(${decimalSiRE})?"; # decimalSI may be empty
      binarySiRE = "Ki|Mi|Gi|Ti|Pi|Ei";
      decimalSiRE = "m|k|M|G|T|P|E";
      decimalExponentRE = "e(${signedNumberRE})|E(${signedNumberRE})";
    in
      quantityRE_;

    # https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#syntax-and-character-set
    labelPrefixRE = "(${rfc1123.subdomainNameRE})";
    # TODO: enforce length<=63 (positive lookaheads are not supported unfortunately)
    labelNameRE = "([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]";
    labelRE = "((${k8s.labelPrefixRE})[/])?(${k8s.labelNameRE})";
    # TODO: enforce length<=63 (positive lookaheads are not supported unfortunately)
    labelValueRE = "(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?";

    # https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration
    taintEffectRE = "(NoExecute|NoSchedule|PreferNoSchedule)";

    # as per https://kubernetes.io/docs/concepts/containers/images/#image-names
    imageRefRE = lib.concatStrings [
      "((${rfc1123.subdomainNameRE})([:]${rfc9293.portNumberRE})?[/])?" # domain/ or domain:port/
      "(${oci.dist1.imageNameRE})" # image-name
      "([:](${oci.dist1.imageTagRE}))?" # optional :image-tag
      "([@](${oci.format1.imageDigestStrRE}))?" # optional @digest
    ];

    # as per servicemonitors.monitoring.coreos.com Kubernetes CRD v1
    coreos-monitoring = {
      v1 = let
        # https://github.com/prometheus-operator/prometheus-operator/blob/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml#L260 (interval, scrapeTimeout)
        prometheusIntervalRE = "0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?";
      in {
        prometheusDurationRE = prometheusIntervalRE;
        # https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api-reference/api.md#monitoring.coreos.com/v1.LabelName
        prometheusLabelNameRE = "[a-zA-Z0-9_]+";
      };
    };
  };

  clusterName = _nonEmptyNonSpacedStr;
  kubernetesVersions = versions: let
    inherit (builtins) concatStringsSep foldl' length map typeOf;
  in
    assert lib.assertMsg
    (typeOf versions == "list")
    "kubernetesVersions: versions must be a list, not ${typeOf versions}";
    assert lib.assertMsg
    (length versions > 0)
    "kubernetesVersions: versions must contain at least one item";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (typeOf x == "list")) true versions)
    "kubernetesVersions: versions must provide each version as a list";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (length x == 2)) true versions)
    "kubernetesVersions: versions must only contain major and minor version";
      _mkRegexStrOptionType {
        name = "kubernetesVersions";
        description = ''
          Kubernetes version (one of: ${
            concatStringsSep ", " (
              map (
                vv: "${concatStringsSep "." (map (v: toString v) vv)}.x"
              )
              versions
            )
          })'';
        # build a single regular expression to match the specified combinations of
        #  major and minor version plus any patch version
        #  Example: [[1 30] [1 31]] -> [ "^((1[.]30)|(1[.]31))[.][0-9]+$" ]
        matchAgainstAllOf = [
          "^(${
            concatStringsSep "|" (
              map (vv: "(${
                concatStringsSep "[.]" (map (v: toString v) vv)
              })")
              versions
            )
          })[.][0-9]+$"
        ];
      };
  quantity = _mkRegexStrOptionType {
    name = "k8sQuantity";
    description = "Kubernetes quantity";
    matchAgainstAllOf = ["^(${k8s.quantityRE})$"];
  };
  threshold = _mkRegexStrOptionType {
    name = "k8sThreshold";
    description = "Kubernetes threshold";
    matchAgainstAllOf = ["^(${k8s.quantityRE}|(0|[1-9][0-9]*)%)$"];
  };
  # as per https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  serviceType = lib.types.enum [
    "ClusterIP"
    "NodePort"
    "LoadBalancer"
    "ExternalName"
  ];

  # as per https://kubernetes.io/docs/reference/kubernetes-api/
  # and https://kubernetes.io/docs/concepts/overview/working-with-objects/names
  # NOTE: Although capitals are valid as per the RFCs, Kubernetes rejects them
  # NOTE: k8sObjectName is an unspecific type and should be avoided if possible
  objectName = lib.types.oneOf [
    (_mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  namespaceName = lib.types.oneOf [
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  storageClassName = lib.types.oneOf [
    (_mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  secretName = lib.types.oneOf [
    (_mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  serviceName = _mkRfc1035SubdomainLabelType {rejectCapitals = true;};
  ingressClassName = lib.types.oneOf [
    (_mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  issuerName = lib.types.oneOf [
    (_mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  podContainerName = lib.types.oneOf [
    (_mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (_mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  labelPrefix = _mkRegexStrOptionType {
    name = "k8sLabelPrefix";
    description = "Kubernetes label prefix";
    matchAgainstAllOf = [
      "^(${k8s.labelPrefixRE})$"

      # length<=253 (WORKAROUND: This should have been encoded in k8s.labelPrefixRE with positive lookaheads but these are unsupported)
      "^.{0,253}$"
    ];
  };
  labelValue = _mkRegexStrOptionType {
    name = "k8sLabelValue";
    description = "Kubernetes label value";
    matchAgainstAllOf = [
      "^(${k8s.labelValueRE})$"

      # length<=63 (WORKAROUND: This should have been encoded in k8s.labelValueRE with positive lookaheads but these are unsupported)
      "^.{0,63}$"
    ];
  };
  label = _mkRegexStrOptionType {
    name = "k8sLabel";
    description = "Kubernetes label";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})$"

      # prefixLength<=253, nameLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE with positive lookaheads but these are unsupported)
      "^([^/]{0,253}[/])?([^/]{0,63})$"
    ];
  };
  labelStr = _mkRegexStrOptionType {
    name = "k8sLabelStr";
    description = "Kubernetes label string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})=(${k8s.labelValueRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=]{0,253}[/])?([^/=]{0,63})[=]([^=]{0,63})$"
    ];
  };
  labelAttrs = lib.mkOptionType {
    name = "k8sLabelAttrs";
    description = "attribute set of Kubernetes label-value pairs";
    descriptionClass = "noun";
    check = x:
      builtins.isAttrs x
      && (
        lib.attrsets.foldlAttrs (
          acc: l: v:
            acc && label.check l && labelValue.check v
        )
        true
        x
      );
  };

  taintStr = _mkRegexStrOptionType {
    name = "k8sTaintStr";
    description = "Kubernetes taint string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})(=(${k8s.labelValueRE}))?:(${k8s.taintEffectRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=:]{0,253}[/])?([^/=:]{0,63})([=][^=:]{0,63})?([:][^:]+)$"
    ];
  };
  # as per https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-duration
  durationStr = _mkRegexStrOptionType {
    name = "k8sDurationStr";
    description = "Kubernetes duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };
  imageRef = _mkRegexStrOptionType {
    name = "k8sImageRef";
    description = "Kubernetes container image reference";
    matchAgainstAllOf = ["^(${k8s.imageRefRE})$"];
  };
}
