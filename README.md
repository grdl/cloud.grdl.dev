# cloud.grdl.dev

Provisioning and GitOps for cloud.grdl.dev cluster.


# Terraform

### Variables

Decrypt the variables file with:
```
sops -d --output terraform.auto.tfvars terraform.auto.tfvars.enc
```

### State and Terraform Cloud

If you use Terraform Cloud to store the state run `terraform login` first. 

If you don't want to use Terraform Cloud, remove the `backend.tf` file. This will set Terraform to use the default local state file.

### Run

```
terraform init
terraform plan
terraform apply
```

# Helm

### Requirements

```
helm
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/zendesk/helm-secrets
helmfile
```

### Install Helm charts

```
helmfile sync
```

