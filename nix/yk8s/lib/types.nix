{lib}: let
  decimalOctetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])";
  ipv4AddrRE = "(${decimalOctetRE}\.){3}${decimalOctetRE}";
in {
  ipv4Addr = lib.types.strMatching "^${ipv4AddrRE}$";
  ipv4Cidr = lib.types.strMatching "^${ipv4AddrRE}/([0-9]|[12][0-9]|3[0-2])$";
  # as per https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/quantity/
  k8sQuantity = let
    quantity = "(${signedNumber})(${suffix})";
    digit = "[0-9]";
    digits = "${digit}+";
    number = "(${digits})|(${digits})[.](${digits})|(${digits})[.]|[.](${digits})";
    sign = "[+-]";
    signedNumber = "(${number})|(${sign})(${number})";
    suffix = "(${binarySI})|(${decimalExponent})|(${decimalSI})?"; # decimalSI may be empty
    binarySI = "Ki|Mi|Gi|Ti|Pi|Ei";
    decimalSI = "m|k|M|G|T|P|E";
    decimalExponent = "e(${signedNumber})|E(${signedNumber})";
  in
    lib.types.strMatching "^(${quantity})$";
  # as per https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types
  k8sServiceType = lib.types.enum [
    "ClusterIP"
    "NodePort"
    "LoadBalancer"
    "ExternalName"
  ];
}
