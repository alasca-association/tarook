{lib, ...}: {
  yk8s.terraform.modules = lib.singleton {
    provider.openstack = {};
  };
}
