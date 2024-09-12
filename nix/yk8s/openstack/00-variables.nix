{lib, ...}: {
  yk8s.terraform.modules = lib.singleton {
    variable.keypair.type = "string";
  };
}
