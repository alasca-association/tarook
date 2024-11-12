{lib}: let
  decimalOctetRE = "(25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])";
  ipv4AddrRE = "(${decimalOctetRE}\.){3}${decimalOctetRE}";
  ipv6SegmentRE = "[0-9a-fA-F]{1,4}";
  ipv6AddrRE =
    "("
    + "(${ipv6SegmentRE}:){7,7}${ipv6SegmentRE}|" # 1:2:3:4:5:6:7:8
    + "(${ipv6SegmentRE}:){1,7}:|" # 1::                                 1:2:3:4:5:6:7::
    + "(${ipv6SegmentRE}:){1,6}:${ipv6SegmentRE}|" # 1::8               1:2:3:4:5:6::8   1:2:3:4:5:6::8
    + "(${ipv6SegmentRE}:){1,5}(:${ipv6SegmentRE}){1,2}|" # 1::7:8             1:2:3:4:5::7:8   1:2:3:4:5::8
    + "(${ipv6SegmentRE}:){1,4}(:${ipv6SegmentRE}){1,3}|" # 1::6:7:8           1:2:3:4::6:7:8   1:2:3:4::8
    + "(${ipv6SegmentRE}:){1,3}(:${ipv6SegmentRE}){1,4}|" # 1::5:6:7:8         1:2:3::5:6:7:8   1:2:3::8
    + "(${ipv6SegmentRE}:){1,2}(:${ipv6SegmentRE}){1,5}|" # 1::4:5:6:7:8       1:2::4:5:6:7:8   1:2::8
    + "${ipv6SegmentRE}:((:${ipv6SegmentRE}){1,6})|" # 1::3:4:5:6:7:8     1::3:4:5:6:7:8   1::8
    + ":((:${ipv6SegmentRE}){1,7}|:)|" # ::2:3:4:5:6:7:8    ::2:3:4:5:6:7:8  ::8       ::
    + "fe80:(:${ipv6SegmentRE}){0,4}%[0-9a-zA-Z]{1,}|" # fe80::7:8%eth0     fe80::7:8%1  (link-local IPv6 addresses with zone index)
    + "::(ffff(:0{1,4}){0,1}:){0,1}${ipv4AddrRE}|" # ::255.255.255.255  ::ffff:255.255.255.255  ::ffff:0:255.255.255.255 (IPv4-mapped IPv6 addresses and IPv4-translated addresses)
    + "(${ipv6SegmentRE}:){1,4}:${ipv4AddrRE}" # 2001:db8:3:4::192.0.2.33  64:ff9b::192.0.2.33 (IPv4-Embedded IPv6 Address)
    + ")";
in {
  ipv4Addr = lib.types.strMatching "^${ipv4AddrRE}$";
  ipv4Cidr = lib.types.strMatching "^${ipv4AddrRE}/([0-9]|[12][0-9]|3[0-2])$";
  ipv6Addr = lib.types.strMatching "^${ipv6AddrRE}$";
  ipv6Cidr = lib.types.strMatching "^${ipv6AddrRE}/([0-9]|[1-9][0-9]|1[01][0-9]|12[0-8]$";
  k8sSize = lib.types.strMatching "[1-9][0-9]*(\\.[0-9]+)?([KMGT]i)?";
  k8sCpus = lib.types.strMatching "[1-9][0-9]*m?";
  k8sServiceType = lib.types.strMatching "ClusterIP|NodeIP|LoadBalancer";
}
