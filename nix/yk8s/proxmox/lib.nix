{lib, ...}:
# Available at yk8s-lib.proxmox
{
  mkIpConfig = {
    ipv4_address,
    subnet_cidr,
    ipv4_gateway_address,
  }: let
    inherit (builtins) elemAt;
    inherit (lib.strings) concatLines splitString;
    hostbits = elemAt (splitString "/" subnet_cidr) 1;
  in "ip=${ipv4_address}/${hostbits},gw=${ipv4_gateway_address}";
}
