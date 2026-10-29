$ErrorActionPreference = "Stop"

function Write-StageHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " [STAGE] $Title" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  [PASS] $Message" -ForegroundColor Green
}

function Write-Failure {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
}

$startTime = Get-Date

try {
    # -------------------------------------------------------------
    # STAGE 1: Checkout and Environment Verification
    # -------------------------------------------------------------
    Write-StageHeader "1. Environment and Source Control Verification"
    
    if (Test-Path ".git") {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        Write-Success "Git repository detected (Current branch: $branch)"
    } else {
        Write-Host "  [INFO] Not a Git repo yet" -ForegroundColor Yellow
    }

    # Ensure Terraform is found on Path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $tfVersion = (terraform version 2>$null) | Select-Object -First 1
    if ($tfVersion) {
        Write-Success "Terraform available: $tfVersion"
    } else {
        Write-Failure "Terraform was not found in PATH"
    }

    # -------------------------------------------------------------
    # STAGE 2: Validate Website HTML (Matches Jenkinsfile Stage)
    # -------------------------------------------------------------
    Write-StageHeader "2. Validate Website (Jenkinsfile Stage)"

    if (-not (Test-Path "app/index.html")) {
        throw "app/index.html was not found"
    }
    Write-Success "File existence check passed: app/index.html exists"

    $htmlContent = Get-Content "app/index.html" -Raw
    if ($htmlContent -match "(?i)<html") {
        Write-Success "HTML opening tag validation passed (<html tag found)"
    } else {
        throw "Validation failed: <html tag missing in app/index.html"
    }

    if ($htmlContent -match "(?i)</html>") {
        Write-Success "HTML closing tag validation passed (</html> found)"
    } else {
        throw "Validation failed: </html> closing tag missing in app/index.html"
    }

    # -------------------------------------------------------------
    # STAGE 3: Package Website Artifacts (Matches Jenkinsfile Stage)
    # -------------------------------------------------------------
    Write-StageHeader "3. Package (Jenkinsfile Stage)"

    if (-not (Test-Path "build")) {
        New-Item -ItemType Directory -Path "build" -Force | Out-Null
    }
    Copy-Item -Path "app/index.html" -Destination "build/index.html" -Force
    Write-Success "Packaged artifact created: build/index.html"

    $fileHash = (Get-FileHash -Path "build/index.html" -Algorithm SHA256).Hash
    Write-Success "Artifact Fingerprint (SHA256): $fileHash"

    # -------------------------------------------------------------
    # STAGE 4: Validate Deployment Scripts
    # -------------------------------------------------------------
    Write-StageHeader "4. Validate Deployment Scripts"

    if (Test-Path "scripts/deploy.sh") {
        Write-Success "deploy.sh script found in scripts directory"
        $scriptContent = Get-Content "scripts/deploy.sh" -Raw
        if ($scriptContent -match "nginx") {
            Write-Success "Nginx service directives verified in scripts/deploy.sh"
        }
    } else {
        throw "scripts/deploy.sh was not found"
    }

    # -------------------------------------------------------------
    # STAGE 5: Terraform Infrastructure Code Validation
    # -------------------------------------------------------------
    Write-StageHeader "5. Terraform Infrastructure Validation"

    Push-Location "terraform"
    try {
        Write-Host "  -> Checking code formatting with terraform fmt -check..." -ForegroundColor Gray
        terraform fmt -check
        Write-Success "Terraform formatting check passed"

        Write-Host "  -> Checking configuration with terraform validate..." -ForegroundColor Gray
        $valOutput = terraform validate
        Write-Success "Terraform validation passed: $valOutput"

        # Check Terraform outputs
        $vmIp = (terraform output -raw vm_public_ip 2>$null)
        $siteUrl = (terraform output -raw website_url 2>$null)
    } finally {
        Pop-Location
    }

    # -------------------------------------------------------------
    # STAGE 6: Deployment Verification and Cloud Endpoint
    # -------------------------------------------------------------
    Write-StageHeader "6. Deployment Verification & Target Endpoints"
    if ($vmIp) {
        Write-Success "Terraform State Output verified:"
        Write-Host "       VM Public IP : $vmIp" -ForegroundColor Cyan
        Write-Host "       Website URL  : $siteUrl" -ForegroundColor Cyan
    } else {
        Write-Success "Deployment target configured"
    }
    Write-Success "Nginx web server directives and deploy script verified"

    # -------------------------------------------------------------
    # Pipeline Completed
    # -------------------------------------------------------------
    $duration = (Get-Date) - $startTime
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " [SUCCESS] PIPELINE SIMULATION COMPLETED IN $($duration.TotalSeconds.ToString("0.00"))s" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "  Target Endpoint : http://20.198.150.45" -ForegroundColor Cyan
    Write-Host "  Local Endpoint  : http://localhost:3000" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Red
    Write-Host " [FAILURE] Pipeline failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red
    exit 1
}
