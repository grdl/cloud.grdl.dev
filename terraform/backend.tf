# This file tells terraform to use terraform cloud as the state storage.
# Remove it if you want to use a local state. 

terraform {
  backend "remote" {
    organization = "grdl"

    workspaces {
      name = "cloud-grdl-dev"
    }
  }
}
