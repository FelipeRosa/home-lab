terraform {
  cloud {
    organization = "fsgr"
    workspaces {
      name = "local-personal"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config-local"
  config_context = "default"
}
