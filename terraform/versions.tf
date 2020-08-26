
terraform {
  required_version = ">= 0.13"
  required_providers {
    cloudflare = {
      source = "terraform-providers/cloudflare"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    local = {
      source = "hashicorp/local"
    }
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
}
