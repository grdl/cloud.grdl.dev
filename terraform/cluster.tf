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

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "2.6.3"
  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true

# TODO: Move values into a separate yaml file

  values = [
  <<-EOT
  # Don't use the Helm v2 hook to install CRDs when running Helm v3
  installCRDs: false
  dex:
    enabled: false
  configs:
    secret:
      argocdServerAdminPassword: "${bcrypt(var.argo_password)}"
      extra:
        sopsKey: |
          ${indent(8, var.argo_sops_key)}

  # Use our custom argocd image with sops and helm-secrets installed
  repoServer:
    image:
      repository: grdl/argocd
      tag: v1.7.4

    # Init container imports the sopsKey PGP key from secret into argocd's keyring.
    initContainers:
    - name: import-sops-key
      image: grdl/argocd:v1.7.4
      command: ['gpg', '--import', '/home/argocd/argocd-secret/sopsKey']  
      volumeMounts:
      - name: argocd-secret
        mountPath: /home/argocd/argocd-secret
        readOnly: true
      - name: keyring
        mountPath: /home/argocd/.gnupg

    volumeMounts:
    - name: keyring
      mountPath: /home/argocd/.gnupg

    volumes:
    - name: argocd-secret
      secret:
        secretName: argocd-secret
    - name: keyring
      emptyDir: {}
  
  # Define the app-of-apps to bootstrap other apps in the cluster
  # See https://argoproj.github.io/argo-cd/operator-manual/cluster-bootstrapping/
  server:
    additionalApplications:
    - name: app-of-apps
      namespace: argocd
      additionalLabels: {}
      additionalAnnotations: {}
      project: default
      source:
        repoURL: https://github.com/grdl/cloud.grdl.dev.git
        targetRevision: HEAD
        path: applications
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
  EOT
  ]
}
