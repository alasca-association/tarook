# Please note that if gitlab_backend is set to true in the config
# it will override this local backend configuration
terraform {
  backend "local" {
    path = "../../state/terraform/terraform.tfstate"
  }
}
