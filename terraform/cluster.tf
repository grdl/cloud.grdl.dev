# Create Scaleway provider
provider "scaleway" {
  access_key      = var.scaleway_access_key
  secret_key      = var.scaleway_secret_key
  organization_id = var.scaleway_organization_id
  zone            = var.scaleway_zone
  region          = var.scaleway_region
}

# Create Scaleway Kubernetes cluster
resource "scaleway_k8s_cluster_beta" "cluster" {
  name             = "cloud.grdl.dev-cluster"
  description      = "cloud.grdl.dev cluster"
  version          = "1.18.8"
  cni              = "flannel"
  enable_dashboard = false
  ingress          = "nginx"
  tags             = []
}

# Create Scaleway Kubernetes cluster pool
resource "scaleway_k8s_pool_beta" "pool" {
  cluster_id = scaleway_k8s_cluster_beta.cluster.id
  name = "default pool"
  node_type   = var.scaleway_node_type
  size        = var.scaleway_cluster_size
  autoscaling = false
  autohealing = true
}

# Create Cloudflare provider
provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

# Get zone (domain) id
data "cloudflare_zones" "zone" {
  filter {
    name = "grdl.dev"
  }
}

# Create root CNAME pointing to wildard DNS taken from created Kubernetes cluster
resource "cloudflare_record" "k8s_cname_root" {
  zone_id = data.cloudflare_zones.zone.zones[0].id
  name    = var.domain_name
  value   = trimprefix(scaleway_k8s_cluster_beta.cluster.wildcard_dns, "*.")
  type    = "CNAME"
}

# Create wildcard CNAME pointing to wildard DNS taken from created Kubernetes cluster
resource "cloudflare_record" "k8s_cname_wildard" {
  zone_id = data.cloudflare_zones.zone.zones[0].id
  name    = join(".", ["*", var.domain_name])
  value   = trimprefix(scaleway_k8s_cluster_beta.cluster.wildcard_dns, "*.")
  type    = "CNAME"
}

# Create Helm provider
provider "helm" {
  kubernetes {
    host  = scaleway_k8s_cluster_beta.cluster.kubeconfig[0].host
    token = scaleway_k8s_cluster_beta.cluster.kubeconfig[0].token
    cluster_ca_certificate = base64decode(
      scaleway_k8s_cluster_beta.cluster.kubeconfig[0].cluster_ca_certificate
    )
    load_config_file = false
  }
}

# Create ArgoCD Helm release
resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "2.6.0"
  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true

  # We're using Helm 3 so we don't need to explicitly install CRDs
  set {
    name  = "installCRDs"
    value = false
  }
  
  # We don't need Dex
  set {
    name  = "dex.enabled"
    value = false
  }

  # Change the default argo admin password
  set {
    name = "configs.secret.argocdServerAdminPassword"
    value = bcrypt(var.argo_password)
  }  
}
