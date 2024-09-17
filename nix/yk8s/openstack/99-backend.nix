{
  lib,
  config,
  ...
}: {
  terraform.backend =
    if config.var.gitlab_backend
    then {"http" = {};}
    else {
      "local" = {
        path = "terraform.tfstate";
      };
    };
}
