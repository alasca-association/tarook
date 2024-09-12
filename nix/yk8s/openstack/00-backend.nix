{
  lib,
  config,
  ...
}: {
  yk8s.terraform.modules = lib.singleton {
    terraform.backend =
      if config.yk8s.terraform.gitlab_backend
      then {
        "http" = rec {
          address = config.yk8s.terraform.gitlab.backend_address;
          lock_address = "${address}/lock";
          unlock_address = "${address}/lock";
          lock_method = "POST";
          unlock_method = "DELETE";
          retry_wait_min = 5;
        };
      }
      else {
        "local" = {
          path = "terraform.tfstate";
        };
      };
  };
}
