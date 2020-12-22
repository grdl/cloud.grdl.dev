
terraform {
  required_version = ">= 0.14"
  required_providers {
    cloudflare = {
      source = "terraform-providers/cloudflare"
    }
    local = {
      source = "hashicorp/local"
    }
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
}
