# cloud.grdl.dev
Provisioning and GitOps for cloud.grdl.dev cluster.



# Terraform

### Configuration

Create a `terraform.tfvars` file and populate it with necessary secrets. Look at `terraform.tfvars.template` for the list of required variabled.

`terraform.tfvars` file is gitignored, do not commit it.

### State and Terraform Cloud

If you use Terraform Cloud to store the state run `terraform login` first. 

If you don't want to use Terraform Cloud, remove the `backend.tf` file. This will set Terraform to use the default local state file.

When running locally, Terraform will create a `kube.config` file in the current directory. When using Terraform Cloud this won't happen so you need to download the `kube.config` file manually from Scaleway.

### Run

```
terraform init
terraform plan
terraform apply
```