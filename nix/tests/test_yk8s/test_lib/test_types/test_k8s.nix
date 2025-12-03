{
  lib,
  ctx,
  ...
}: let
  common = (import ./_common.nix) {inherit lib ctx;};
  inherit (lib) mapCartesianProduct;
  inherit (builtins) filter;
  inherit
    (common)
    mkPassthruTest
    nonStringValuesRejected
    nonAttrsValuesRejected
    reusableValues
    selectStringsByMaxLength
    yk8s-lib
    ;
  inherit
    (yk8s-lib.transform)
    matchesRegex
    ;
  optionTypes = import (ctx.importPath) {inherit lib;};

  optionTypeUnitTests = {
    meta = {
      name = "k8sOptionTypesUnitTests";
      targets = optionTypes;
      predicates = {
        "pass" = "accept";
        "fail" = "reject";
      };
    };
    units = rec {
      clusterName = {
        target = optionTypes.clusterName;
        tests.typeChecking = {
          accepted.inputs = [
            "managed-k8s"
            "devcluster"
            "1cluster1"
            "clusterNameWithCapitals"
            "cluster.name"
            "cluster-name-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            ""
            "cluster name with spaces"
          ];
        };
      };
      kubernetesVersions = {
        target = optionTypes.kubernetesVersions;
        tests.description = {
          twoKubernetesVersions = {
            params = [[[1 29] [1 30]]];
            text = "Kubernetes version (one of: 1.29.x, 1.30.x)";
          };
        };
        tests.typeChecking = {
          accepted = {
            params = [[[1 29] [1 30]]];
            inputs = [
              "1.29.0"
              "1.29.3"
              "1.29.12"
              "1.30.0"
              "1.30.4"
              "1.30.14"
            ];
          };
          rejected = {
            params = [[[1 29] [1 30]]];
            inputs = [
              ""
              "1"
              "1.29"
              "1.30"
              "1.31"
              "1.31.0"
              "1.31.3"
              "1.31.12"
              ".31.12"
              "-3.42"
              "1.29.3-alpha"
              "1.29.3+2ad73da"
            ];
          };
        };
      };
      quantity = {
        target = optionTypes.quantity;
        tests.typeChecking = {
          accepted.inputs = [
            "300"
            "3k"
            "50Ki"
            "2.6Gi"
            "2.66Gi"
            "2.666Gi"
            "4e30"
            "-1024"
            "-5Ti"
            "4."
            ".68"
            ".688"
            "4e-40"
          ];
          rejected.inputs = [
            ""
            "2.6666Gi" # more than three decimal places
            ".6888" # more than three decimal places
            "4.5.6m"
            "45GM"
            "1K"
            "4ki"
            "2.6 Gi"
          ];
          inherit nonStringValuesRejected;
        };
      };
      threshold = {
        target = optionTypes.threshold;
        tests.typeChecking = {
          accepted.inputs =
            # every percentage from 0 to 205 (and beyond) is a valid threshold
            map (x: "${toString x}%") (lib.range 0 205)
            # every quantity is also a valid threshold
            ++ quantity.tests.typeChecking.accepted.inputs;
          rejected.inputs = [
            ""
            " "
            "-0%"
            "-1%"
            "050%"
            "%"
            "50%4"
          ];
          inherit nonStringValuesRejected;
        };
      };
      serviceType = {
        target = optionTypes.serviceType;
        tests.typeChecking = {
          accepted.inputs = [
            "ClusterIP"
            "NodePort"
            "LoadBalancer"
            "ExternalName"
          ];
          rejected.inputs = [
            ""
            " "
            "foobar"
            "NodeIP"
            "Node"
          ];
          inherit nonStringValuesRejected;
        };
      };
      objectName = {
        target = optionTypes.objectName;
        tests.typeChecking = rec {
          accepted.inputs = [
            "calico-apiserver-78b49d765f-pdlns"
            "kube-proxy-kklwb"
          ];
          # NOTE: k8s subdomain labels and names must not exceed 63 and 253 characters respectively
          rfc1123SubdomainNamesAccepted.inputs = selectStringsByMaxLength 253 reusableValues.rfc1123SubdomainNames;
          rfc1123SubdomainLabelsAccepted.inputs = selectStringsByMaxLength 63 reusableValues.rfc1123SubdomainLabels;
          rfc1035SubdomainLabelsAccepted.inputs = selectStringsByMaxLength 63 reusableValues.rfc1035SubdomainLabels;
          rejected.inputs = [
            ""
            "foo..bar"
            "-foobar"
            ".foobar"
            "names%with+special~chars"
            "names-with-CAPITALS"
            "Capitalname"
            "capitalName"
            "name/with-a-slash"
            "name-ending-with-a-dash-"
            "-name-starting-with-a-dash-"
            # NOTE: k8s subdomain labels and names must not exceed 63 and 253 characters respectively
            "label-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaa"
            "subdomain-name-with-254-charaters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          inherit nonStringValuesRejected;
        };
      };
      namespaceName = {
        target = optionTypes.namespaceName;
        tests.typeChecking = {
          accepted.inputs = ["kube-system"];

          # namespaceName is a subset of objectName (subdomain labels)
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];

          inherit nonStringValuesRejected;
        };
      };
      storageClassName = {
        target = optionTypes.storageClassName;
        tests.typeChecking = {
          accepted.inputs = ["csi-sc-cinderplugin"];

          # storageClassName is equal to objectName
          inherit (objectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      secretName = {
        target = optionTypes.secretName;
        tests.typeChecking = {
          accepted.inputs = ["sh.helm.release.v1.calico.v1"];

          # secretName is equal to objectName
          inherit (objectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      serviceName = {
        target = optionTypes.serviceName;
        tests.typeChecking = {
          accepted.inputs = ["kube-dns"];

          # serviceName is a subset of objectName
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];
          rfc1123SubdomainLabelsRejected.inputs = ["1name"];

          inherit nonStringValuesRejected;
        };
      };
      ingressClassName = {
        target = optionTypes.ingressClassName;
        tests.typeChecking = {
          accepted.inputs = ["haproxy-prod"];

          # ingressClassName is equal to objectName
          inherit (objectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      issuerName = {
        target = optionTypes.issuerName;
        tests.typeChecking = {
          accepted.inputs = ["selfsigned-issuer"];

          # issuerName is equal to objectName
          inherit (objectName.tests.typeChecking) rfc1123SubdomainNamesAccepted;
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;

          inherit nonStringValuesRejected;
        };
      };
      podContainerName = {
        target = optionTypes.podContainerName;
        tests.typeChecking = {
          accepted.inputs = ["kube-state-metrics"];

          # namespaceName is a subset of objectName (subdomain labels)
          inherit (objectName.tests.typeChecking) rfc1123SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rfc1035SubdomainLabelsAccepted;
          inherit (objectName.tests.typeChecking) rejected;
          rfc1123SubdomainNamesRejected.inputs = ["dotted.name"];

          inherit nonStringValuesRejected;
        };
      };
      labelPrefix = {
        target = optionTypes.labelPrefix;
        tests.typeChecking = {
          # every rfc1123SubdomainName that does not exceed 253 characters is a valid labelPrefix
          accepted.inputs =
            [
              "k8s-app"
              "app.kubernetes.io"
              "dotted-prefix-with-253-characters-aaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaa"
            ]
            ++ selectStringsByMaxLength 253 reusableValues.rfc1123SubdomainNames;
          rejected.inputs = [
            ""
            " "
            "prefix-with-trailing-slash/"
            "prefix-with-two-trailing-slashes//"
            "prefix-with-a/slash"
            "prefix&with+disallowed#chars"
            "prefix with spaces"
            "dotted-prefix-with-254-characters-aaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaaaaaaaaaaaaaaaaaa"
          ];

          inherit nonStringValuesRejected;
        };
      };
      labelValue = {
        target = optionTypes.labelValue;
        tests.typeChecking = {
          accepted.inputs = [
            ""
            "090f35a2-4dfd-426e-8ece-48bf15d08a8f"
            "openstack-cinder-csi-2.30.0"
            "calico-apiserver"
            "value"
            "ValueA"
            "1value1"
            "a"
            "1"
            "foo-BAR_baz.01"
            "foo---bar..__baz"
            "value-with-63-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
          ];
          rejected.inputs = [
            " "
            "_value_starting-with-an-underscore"
            "-value_starting-with-a-dash"
            ".value_starting-with-a-dot"
            "value_ending-with-an-underscore_"
            "value_ending-with-a-dash-"
            "value_ending-with-a-dot."
            "value_with/slash"
            "value_with space"
            "value_with+disa!!owed%ch&rs"
            "value-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            "value=foo"
          ];

          inherit nonStringValuesRejected;
        };
      };
      label = {
        target = optionTypes.label;
        tests.typeChecking = let
          labelNames = {
            valid = [
              "name"
              "NameA"
              "1name1"
              "a"
              "1"
              "foo-BAR_baz.01"
              "foo---bar..__baz"
              "name-with-63-characters-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
            ];
            invalid = [
              ""
              " "
              "_name_starting-with-an-underscore"
              "-name_starting-with-a-dash"
              ".name_starting-with-a-dot"
              "name_ending-with-an-underscore_"
              "name_ending-with-a-dash-"
              "name_ending-with-a-dot."
              "name-ending-with-slash/"
              "/name-starting-with-slash"
              "name-with/slash"
              "name-with/two/slashes"
              "name-with space"
              "name_with+disa!!owed%ch&rs"
              "name-with-64-characters-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
              "name=value"
            ];
          };
        in {
          accepted.inputs =
            ["k8s-app" "app.kubernetes.io/name"]
            # every labelName on its own is a label
            ++ labelNames.valid
            # every concatenation with '/' of labelPrefix and labelName is a label
            ++ mapCartesianProduct ({
              labelPrefix,
              labelName,
            }: "${labelPrefix}/${labelName}") {
              labelPrefix = labelPrefix.tests.typeChecking.accepted.inputs;
              labelName = labelNames.valid;
            };
          rejected.inputs =
            []
            # every invalid labelName on its own (containing no single slash) is an invalid label
            ++ filter (x: ! matchesRegex "^[^/]+[/][^/]+$" x) labelNames.invalid
            # every concatenation with '/' of an invalid labelPrefix and valid labelName is an invalid label
            ++ mapCartesianProduct ({
              invalidLabelPrefix,
              labelName,
            }: "${invalidLabelPrefix}/${labelName}") {
              invalidLabelPrefix = labelPrefix.tests.typeChecking.rejected.inputs;
              labelName = labelNames.valid;
            }
            # every concatenation with '/' of an valid labelPrefix and invalid labelName is an invalid label
            ++ mapCartesianProduct ({
              labelPrefix,
              invalidLabelName,
            }: "${labelPrefix}/${invalidLabelName}") {
              labelPrefix = labelPrefix.tests.typeChecking.accepted.inputs;
              invalidLabelName = labelNames.invalid;
            };

          inherit nonStringValuesRejected;
        };
      };
      labelStr = {
        target = optionTypes.labelStr;
        tests.typeChecking = {
          accepted.inputs =
            [
              "k8s-app=kube-dns"
              "app.kubernetes.io/name=snapshot-controller"
              "label-with-empty-value="
              "label/with-empty-value="
            ]
            # every concatenation with '=' of an label and labelValue is a label
            ++ mapCartesianProduct ({
              label,
              labelValue,
            }: "${label}=${labelValue}") {
              label = label.tests.typeChecking.accepted.inputs;
              labelValue = labelValue.tests.typeChecking.accepted.inputs;
            };
          rejected.inputs =
            [
              ""
              " "
              "="
              "label-without-value"
              "label/without-value"
              "=value-with-empty-label"
            ]
            # every concatenation with '=' of an invalid label and valid labelValue is an invalid labelStr
            ++ mapCartesianProduct ({
              invalidLabel,
              labelValue,
            }: "${invalidLabel}=${labelValue}") {
              invalidLabel = label.tests.typeChecking.rejected.inputs;
              labelValue = labelValue.tests.typeChecking.accepted.inputs;
            }
            # every concatenation with '=' of an valid label and invalid labelValue is an invalid label
            ++ mapCartesianProduct ({
              label,
              invalidLabelValue,
            }: "${label}=${invalidLabelValue}") {
              label = label.tests.typeChecking.accepted.inputs;
              invalidLabelValue = labelValue.tests.typeChecking.rejected.inputs;
            };

          inherit nonStringValuesRejected;
        };
      };
      labelAttrs = {
        target = optionTypes.labelAttrs;
        tests.typeChecking = {
          accepted.inputs = [
            {}
            {"foo" = "bar";}
            {
              "k8s-app" = "kube-dns";
              "app.kubernetes.io/name" = "snapshot-controller";
              "label-with-empty-value" = "";
              "label/with-empty-value" = "";
            }
            # any mapping of a label and labelValue is a valid labelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (name: value: {inherit name value;})
                label.tests.typeChecking.accepted.inputs
                labelValue.tests.typeChecking.accepted.inputs
              )
            )
          ];
          rejected.inputs = [
            {"" = "foo";}
            {" " = "foo";}
            # any mapping of an invalid label and valid labelValue is an invalid labelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (invalidLabel: labelValue: {
                  name = invalidLabel;
                  value = labelValue;
                })
                label.tests.typeChecking.rejected.inputs
                labelValue.tests.typeChecking.accepted.inputs
              )
            )
            # any mapping of a valid label and invalid labelValue is an invalid labelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (label: invalidLabelValue: {
                  name = label;
                  value = invalidLabelValue;
                })
                label.tests.typeChecking.accepted.inputs
                labelValue.tests.typeChecking.rejected.inputs
              )
            )
            # any mapping of an invalid label and invalid labelValue is an invalid labelAttrs
            (
              lib.listToAttrs (
                lib.zipListsWith
                (invalidLabel: invalidLabelValue: {
                  name = invalidLabel;
                  value = invalidLabelValue;
                })
                label.tests.typeChecking.rejected.inputs
                labelValue.tests.typeChecking.rejected.inputs
              )
            )
          ];

          inherit nonAttrsValuesRejected;
        };
      };
      taintStr = {
        target = optionTypes.taintStr;
        tests.typeChecking = {
          accepted.inputs =
            [
              "node-role.kubernetes.io/control-plane:NoSchedule"
              "foo=bar:NoExecute"
              "foo=:PreferNoSchedule"
            ]
            # every concatenation of a label, labelValue and taintEffect is a taintStr
            ++ mapCartesianProduct ({
              label,
              labelValue,
              taintEffect,
            }: "${label}=${labelValue}:${taintEffect}") {
              label = label.tests.typeChecking.accepted.inputs;
              labelValue = labelValue.tests.typeChecking.accepted.inputs;
              taintEffect = ["NoExecute" "NoSchedule" "PreferNoSchedule"];
            };
          # NOTE: Not adding the concatenations of label, labelValue and taintEffect here because this results in a huge amount of items
          rejected.inputs = [
            ""
            " "
            "taint-without-effect="
            "taint-with-empty-effect=value:"
            "=value-without-name-and-effect"
          ];

          inherit nonStringValuesRejected;
        };
      };
      durationStr = {
        target = optionTypes.durationStr;
        tests.typeChecking = {
          accepted.inputs = [
            "0s"
            "13s"
            "539s"
            "20m5s"
            "34h45m55s711ms3ns"
            "45m34h55s"
            "40h7s"
            "19272936413s"
          ];
          rejected.inputs = [
            ""
            "12"
            "01s"
            "45mm"
            "-5m"
            "m"
            "8d5h"
          ];
          inherit nonStringValuesRejected;
        };
      };
      imageRef = {
        target = optionTypes.imageRef;
        tests.typeChecking = {
          accepted.inputs = [
            "quay.io/calico/apiserver:v3.28.1"
            "quay.io/calico/apiserver@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "quay.io/calico/apiserver:v3.28.1@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "foo"
            "foo/bar"
            "foo:latest"
            "foo/bar:latest"
          ];
          rejected.inputs = [
            ""
            "quay.io/calico/"
            "quay.io/calico/apiserver@sha256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf:v3.28.1"
            "quay.io/calico/apiserver@SHA256:31beed2d8ba912a04cc3d1de935b7e9d4136b120892905c938e41b1533ed1dcf"
            "_foo"
          ];
          inherit nonStringValuesRejected;
        };
      };
    };
  };
in
  mkPassthruTest optionTypeUnitTests
