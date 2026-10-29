# ==============================================================================
# Automated Azure Deployment Script for Azure-Jenkins CI/CD Project
# ==============================================================================
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Title)
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " [STEP] $Title" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Msg)
    Write-Host "  [OK] $Msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "  [WARN] $Msg" -ForegroundColor Yellow
}

$workDir = $PSScriptRoot
Set-Location $workDir

# -------------------------------------------------------------
# 1. Check Azure Authentication
# -------------------------------------------------------------
Write-Step "1. Verifying Azure Authentication"
$accountInfo = $null
try {
    $rawAccount = az account show 2>$null
    if ($rawAccount) {
        $accountInfo = $rawAccount | ConvertFrom-Json
    }
} catch {}

if (-not $accountInfo) {
    Write-Host "You are not logged in to Azure CLI. Launching browser login..." -ForegroundColor Yellow
    az login
    $accountInfo = az account show | ConvertFrom-Json
}

$subId = $accountInfo.id
$subName = $accountInfo.name
Write-Success "Logged in to Azure Subscription: $subName ($subId)"

# -------------------------------------------------------------
# 2. Check Prerequisites: SSH Key and Public IP
# -------------------------------------------------------------
Write-Step "2. Checking SSH Keys and Network Configuration"

$sshKeyPath = "$HOME\.ssh\id_rsa.pub"
$sshPrivKeyPath = "$HOME\.ssh\id_rsa"
if (-not (Test-Path $sshKeyPath)) {
    Write-Warn "SSH key not found at $sshKeyPath. Generating new 4096-bit RSA SSH key pair..."
    if (-not (Test-Path "$HOME\.ssh")) {
        New-Item -ItemType Directory -Path "$HOME\.ssh" -Force | Out-Null
    }
    ssh-keygen -t rsa -b 4096 -f $sshPrivKeyPath -N '""'
    Write-Success "Generated SSH key at $sshKeyPath"
} else {
    Write-Success "Using existing SSH public key: $sshKeyPath"
}

# Normalize path with forward slashes for Terraform
$tfSshKeyPath = $sshKeyPath -replace '\\', '/'

Write-Host "Detecting your current public IP address..." -ForegroundColor Gray
$publicIp = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 10).Trim()
$adminCidr = "$publicIp/32"
Write-Success "Detected public IP: $publicIp (NSG rule: $adminCidr)"

# -------------------------------------------------------------
# 3. Generate terraform.tfvars
# -------------------------------------------------------------
Write-Step "3. Configuring Terraform Variables"

$tfvarsContent = @"
subscription_id     = "$subId"
admin_ip_cidr       = "$adminCidr"
ssh_public_key_path = "$tfSshKeyPath"
project_name        = "azure-jenkins-cicd"
location            = "Central India"
vm_size             = "Standard_B1s"
admin_username      = "azureuser"
"@

$tfvarsPath = Join-Path $workDir "terraform\terraform.tfvars"
Set-Content -Path $tfvarsPath -Value $tfvarsContent -Force
Write-Success "Generated terraform/terraform.tfvars successfully."

# -------------------------------------------------------------
# 4. Provision Azure Infrastructure via Terraform
# -------------------------------------------------------------
Write-Step "4. Provisioning Infrastructure on Azure (Terraform)"

Push-Location "terraform"
try {
    Write-Host "Running terraform init..." -ForegroundColor Gray
    terraform init

    Write-Host "Running terraform apply..." -ForegroundColor Yellow
    terraform apply -auto-approve

    $vmIp = (terraform output -raw vm_public_ip 2>$null).Trim()
    $siteUrl = (terraform output -raw website_url 2>$null).Trim()
} finally {
    Pop-Location
}

if (-not $vmIp) {
    throw "Failed to retrieve VM Public IP from Terraform outputs."
}

Write-Success "Azure VM provisioned successfully!"
Write-Host "  -> VM Public IP: $vmIp" -ForegroundColor Cyan
Write-Host "  -> Website URL:  $siteUrl" -ForegroundColor Cyan

# -------------------------------------------------------------
# 5. Deploy Website to Azure VM
# -------------------------------------------------------------
Write-Step "5. Deploying Web Application to Azure VM"

Write-Host "Waiting for VM SSH daemon and cloud-init to finish booting (approx. 25-35s)..." -ForegroundColor Yellow
$maxAttempts = 15
$attempt = 1
$connected = $false

while ($attempt -le $maxAttempts) {
    Write-Host "  [Attempt $attempt/$maxAttempts] Checking SSH connection to azureuser@$vmIp..." -ForegroundColor Gray
    $sshTest = & ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -i $sshPrivKeyPath azureuser@$vmIp "echo connected" 2>$null
    if ($sshTest -match "connected") {
        $connected = $true
        Write-Success "SSH connection established!"
        break
    }
    Start-Sleep -Seconds 8
    $attempt++
}

if (-not $connected) {
    throw "Could not establish SSH connection to Azure VM ($vmIp). Please verify security group rules and try again."
}

Write-Host "Copying web application and deployment script to VM via SCP..." -ForegroundColor Gray
scp -o StrictHostKeyChecking=accept-new -i $sshPrivKeyPath "app/index.html" "azureuser@${vmIp}:/tmp/index.html"
scp -o StrictHostKeyChecking=accept-new -i $sshPrivKeyPath "scripts/deploy.sh" "azureuser@${vmIp}:/tmp/deploy.sh"

Write-Host "Executing deployment script on VM..." -ForegroundColor Gray
ssh -o StrictHostKeyChecking=accept-new -i $sshPrivKeyPath "azureuser@$vmIp" "chmod +x /tmp/deploy.sh && /tmp/deploy.sh"

Write-Success "Website deployed to /var/www/html/ and Nginx reloaded on Azure VM!"

# -------------------------------------------------------------
# 6. Open Live Site in Browser
# -------------------------------------------------------------
Write-Step "6. Deployment Complete!"
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " YOUR APPLICATION IS LIVE ON MICROSOFT AZURE!" -ForegroundColor Green
Write-Host " Public URL: $siteUrl" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""

Start-Process $siteUrl

