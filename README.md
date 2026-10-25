# Automated Deployment of a Web Application using CI/CD, Terraform, Azure, and Jenkins

## Project status
Starter template. Review configuration and complete the setup steps before provisioning resources or enabling deployment.

## Architecture
GitHub -> Jenkins -> validate/package HTML -> SSH deployment -> Azure Linux VM running Nginx.
Terraform provisions the Azure resource group, network, subnet, public IP, network interface, security group, and VM.

## Prerequisites
- Azure subscription with permission to create resources
- Azure CLI
- Terraform 1.5+
- Git and GitHub
- Jenkins with Pipeline and SSH Agent/Credentials support
- SSH key pair
- An Azure region and VM size available to your subscription

## 1. Authenticate to Azure
Run locally:
```bash
az login
az account show
```
Copy your subscription ID from the account output. Never commit credentials or private keys.

## 2. Prepare an SSH key
On Windows, use PowerShell:
```powershell
ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\id_rsa
```
If a key already exists, do not overwrite it. The public key is `id_rsa.pub`; keep `id_rsa` private.

Find your public IP and set the SSH rule in `terraform.tfvars` to your public IPv4 address followed by `/32`. Do not use `0.0.0.0/0` for SSH.

## 3. Configure Terraform
From the `terraform` directory, create a local `terraform.tfvars` file (it is ignored by Git):
```hcl
subscription_id     = "YOUR-AZURE-SUBSCRIPTION-ID"
admin_ip_cidr       = "YOUR-PUBLIC-IP/32"
ssh_public_key_path = "C:/Users/YOUR-WINDOWS-USERNAME/.ssh/id_rsa.pub"
```
Use forward slashes in Windows paths. Confirm the VM size and region are available before applying.
Terraform expands `~` in the default SSH key path; you can also provide an absolute path.

Then run:
```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```
`terraform validate` rejects an empty subscription ID and prevents SSH access from
`0.0.0.0/0`. Review the plan and charges before approving.
Save the `vm_public_ip` output for deployment configuration.

## 4. Configure Jenkins
Create a Pipeline job that uses this repository and its `Jenkinsfile`.
The Jenkins agent needs `git`, `ssh`, `scp`, and a POSIX shell. The sample Jenkinsfile uses `sh`, so it is intended for a Linux-based Jenkins agent. If Jenkins runs natively on Windows, use a Linux agent or adapt the pipeline steps.

In Jenkins Credentials, add an SSH Username with private key credential:
- ID: `azure-vm-ssh-key`
- Username: the value of `admin_username` (default `azureuser`)
- Private key: contents of your private SSH key

Configure these job environment variables:
- `AZURE_VM_HOST`: the VM public IP
- `DEPLOY_TO_AZURE`: set to `true` only after SSH connectivity and credentials are verified

Allow outbound SSH from the Jenkins agent and ensure the VM NSG permits SSH only from the required trusted source IP. Do not expose Jenkins itself publicly without appropriate protection.

## 5. Triggering builds
Configure a GitHub webhook only if the Jenkins endpoint is securely reachable from GitHub. Otherwise configure Jenkins Poll SCM. Commit a harmless change to `app/index.html` and confirm the job runs.

## 6. Verify the website
Open the `website_url` Terraform output in a browser after deployment.

## 7. Clean up
When finished, from the same Terraform directory run:
```bash
terraform destroy
```
Review the destroy plan before confirming. Check the Azure portal for any remaining resources and charges.

## 8. Local verification
Before provisioning Azure resources, confirm that:
- `app/index.html` opens in a browser
- `terraform fmt -check` and `terraform validate` pass from the `terraform` directory
- the Jenkins agent has `git`, `grep`, `mkdir`, `cp`, `scp`, and `ssh`
- the deployment stage remains disabled until `AZURE_VM_HOST` and the Jenkins SSH credential are configured

## Security and cost notes
- Cloud resources can incur charges; check current Azure pricing and subscription limits.
- SSH is restricted by `admin_ip_cidr`; replace the example with your own public IP `/32`.
- Do not commit Terraform state, `terraform.tfvars`, credentials, private keys, or other secrets.
- This is an educational HTTP demo, not a production-hardened deployment.
