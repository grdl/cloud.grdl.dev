terraform {
  backend "remote" {
    organization = "grdl"

    workspaces {
      name = "cloud-grdl-dev"
    }
  }
}
