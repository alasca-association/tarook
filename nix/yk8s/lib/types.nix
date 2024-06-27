{lib}: let
  decimalOctetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])";
  ipv4AddrRE = "(${decimalOctetRE}\.){3}${decimalOctetRE}";
in {
  ipv4Addr = lib.types.strMatching "^${ipv4AddrRE}$";
  ipv4Cidr = lib.types.strMatching "^${ipv4AddrRE}/([0-9]|[12][0-9]|3[0-2])$";
  k8sSize = lib.types.strMatching "[1-9][0-9]*([KMGT]i)?";
  k8sCpus = lib.types.strMatching "[1-9][0-9]*m?";
  k8sServiceType = lib.types.strMatching "ClusterIP|NodeIP|LoadBalancer";
}
