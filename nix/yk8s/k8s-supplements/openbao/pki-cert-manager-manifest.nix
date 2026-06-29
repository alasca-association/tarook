{
  namespace,
  caIssuerKind,
  caName,
  certIssuerName,
  certName,
  certIpAddresses,
  certDnsNames,
}: let
  common_labels = {
    "managed-by": "tarook";
  };
in [
  {
    "apiVersion" = "cert-manager.io/v1";
    # TODO: Do we need kind=ClusterIssuer here?
    "kind" = caIssuerKind;
    "metadata" = {
      "namespace" = namespace;
      "name" = caName;
      "labels" = common_labels;
    };
    # TODO: Review spec
    "spec" = {
      "selfSigned" = {};
    };
  }
  {
    "apiVersion" = "cert-manager.io/v1";
    "kind" = "Certificate";
    "metadata" = {
      "namespace" = namespace;
      "name" = caName;
      "labels" = common_labels;
    };
    # TODO: Review spec
    "spec" = {
      "issuerRef" = {
        "kind" = caIssuerKind;
        "name" = caName;
      };
      "secretName" = caName;
      "commonName" = caName;
      "isCA" = true;
    };
  }
  {
    "apiVersion" = "cert-manager.io/v1";
    "kind" = "Issuer";
    "metadata" = {
      "namespace" = namespace;
      "name" = certIssuerName;
      "labels" = common_labels;
    };
    "spec" = {
      "ca" = {
        "secretName" = caName;
      };
    };
  }
  {
    "apiVersion" = "cert-manager.io/v1";
    "kind" = "Certificate";
    "metadata" = {
      "namespace" = namespace;
      "name" = certName;
      "labels" = common_labels;
    };
    "spec" = {
      "issuerRef" = {
        "name" = certIssuerName;
      };
      "secretName" = certName;
      "duration" = "72h";
      "renewBefore" = "24h";
      "ipAddresses" = certIpAddresses;
      "dnsNames" = certDnsNames;
    };
  }
]
