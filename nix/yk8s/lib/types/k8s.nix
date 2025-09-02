{lib}: let
  common = (import ./_common) {inherit lib;};
  inherit
    (common)
    nonEmptyNonSpacedStr
    mkRegexStrOptionType
    k8s
    mkRfc1123SubdomainNameType
    mkRfc1035SubdomainLabelType
    mkRfc1123SubdomainLabelType
    golang
    ;
in rec {
  k8sClusterName = nonEmptyNonSpacedStr;
  k8sVersion = versions: let
    inherit (builtins) concatStringsSep foldl' length map typeOf;
  in
    assert lib.assertMsg
    (typeOf versions == "list")
    "k8sVersion: versions must be a list, not ${typeOf versions}";
    assert lib.assertMsg
    (length versions > 0)
    "k8sVersion: versions must contain at least one item";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (typeOf x == "list")) true versions)
    "k8sVersion: versions must provide each version as a list";
    assert lib.assertMsg
    (foldl' (acc: x: acc && (length x == 2)) true versions)
    "k8sVersion: versions must only contain major and minor version";
      mkRegexStrOptionType {
        name = "k8sVersion";
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
  k8sQuantity = mkRegexStrOptionType {
    name = "k8sQuantity";
    description = "Kubernetes quantity";
    matchAgainstAllOf = ["^(${k8s.quantityRE})$"];
  };
  k8sThreshold = mkRegexStrOptionType {
    name = "k8sThreshold";
    description = "Kubernetes threshold";
    matchAgainstAllOf = ["^(${k8s.quantityRE}|(0|[1-9][0-9]*)%)$"];
  };
  # as per https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  k8sServiceType = lib.types.enum [
    "ClusterIP"
    "NodePort"
    "LoadBalancer"
    "ExternalName"
  ];

  # as per https://kubernetes.io/docs/reference/kubernetes-api/
  # and https://kubernetes.io/docs/concepts/overview/working-with-objects/names
  # NOTE: Although capitals are valid as per the RFCs, Kubernetes rejects them
  # NOTE: k8sObjectName is an unspecific type and should be avoided if possible
  k8sObjectName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sNamespaceName = lib.types.oneOf [
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sStorageClassName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sSecretName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sServiceName = mkRfc1035SubdomainLabelType {rejectCapitals = true;};
  k8sIngressClassName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sIssuerName = lib.types.oneOf [
    (mkRfc1123SubdomainNameType {
      rejectCapitals = true;
      enforceMaxLength253_63 = true;
    })
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sPodContainerName = lib.types.oneOf [
    (mkRfc1123SubdomainLabelType {
      rejectCapitals = true;
      enforceMaxLength63 = true;
    })
    (mkRfc1035SubdomainLabelType {rejectCapitals = true;})
  ];
  k8sLabelPrefix = mkRegexStrOptionType {
    name = "k8sLabelPrefix";
    description = "Kubernetes label prefix";
    matchAgainstAllOf = [
      "^(${k8s.labelPrefixRE})$"

      # length<=253 (WORKAROUND: This should have been encoded in k8s.labelPrefixRE with positive lookaheads but these are unsupported)
      "^.{0,253}$"
    ];
  };
  k8sLabelValue = mkRegexStrOptionType {
    name = "k8sLabelValue";
    description = "Kubernetes label value";
    matchAgainstAllOf = [
      "^(${k8s.labelValueRE})$"

      # length<=63 (WORKAROUND: This should have been encoded in k8s.labelValueRE with positive lookaheads but these are unsupported)
      "^.{0,63}$"
    ];
  };
  k8sLabel = mkRegexStrOptionType {
    name = "k8sLabel";
    description = "Kubernetes label";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})$"

      # prefixLength<=253, nameLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE with positive lookaheads but these are unsupported)
      "^([^/]{0,253}[/])?([^/]{0,63})$"
    ];
  };
  k8sLabelStr = mkRegexStrOptionType {
    name = "k8sLabelStr";
    description = "Kubernetes label string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})=(${k8s.labelValueRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=]{0,253}[/])?([^/=]{0,63})[=]([^=]{0,63})$"
    ];
  };
  k8sLabelAttrs = lib.mkOptionType {
    name = "k8sLabelAttrs";
    description = "attribute set of Kubernetes label-value pairs";
    descriptionClass = "noun";
    check = x:
      builtins.isAttrs x
      && (
        lib.attrsets.foldlAttrs (
          acc: label: value:
            acc && k8sLabel.check label && k8sLabelValue.check value
        )
        true
        x
      );
  };

  k8sTaintStr = mkRegexStrOptionType {
    name = "k8sTaintStr";
    description = "Kubernetes taint string";
    matchAgainstAllOf = [
      "^(${k8s.labelRE})(=(${k8s.labelValueRE}))?:(${k8s.taintEffectRE})$"

      # prefixLength<=253, nameLength<=63, valueLength<=63 (WORKAROUND: This should have been encoded in k8s.labelRE/labelValueRE with positive lookaheads but these are unsupported)
      "^([^/=:]{0,253}[/])?([^/=:]{0,63})([=][^=:]{0,63})?([:][^:]+)$"
    ];
  };
  # as per https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-duration
  k8sDurationStr = mkRegexStrOptionType {
    name = "k8sDurationStr";
    description = "Kubernetes duration string";
    matchAgainstAllOf = ["^(${golang.unsignedIntDurationStrRE})$"];
  };
  k8sImageRef = mkRegexStrOptionType {
    name = "k8sImageRef";
    description = "Kubernetes container image reference";
    matchAgainstAllOf = ["^(${k8s.imageRefRE})$"];
  };
}
