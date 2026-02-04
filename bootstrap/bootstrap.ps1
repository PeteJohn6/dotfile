#Requires -Version 7
# Bootstrap script for Windows
# Installs Scoop and just via package manager, downloads dotter to local bin/

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log($msg)  { Write-Host "[bootstrap] $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Warning "[bootstrap] $msg" }
function Err($msg)  { Write-Error "[bootstrap] $msg"; exit 1 }

Log "Starting bootstrap process..."

# Navigate to repository root (parent of script directory)
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot
Log "Working directory: $repoRoot"
Write-Host ""

# Setup bin directory
Log "Setting up bin\ directory..."
if (-not (Test-Path "bin")) {
    New-Item -ItemType Directory -Force -Path "bin" | Out-Null
}

# Add to .gitignore if not already present
if (Test-Path ".gitignore") {
    $gitignoreLines = Get-Content ".gitignore" -ErrorAction SilentlyContinue
    if ($gitignoreLines -notcontains "bin/") {
        Add-Content -Path ".gitignore" -Value "bin/"
        Log "Added bin/ to .gitignore"
    }
}
else {
    Set-Content -Path ".gitignore" -Value "bin/"
    Log "Created .gitignore and added bin/"
}

# Check if Scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log "Scoop not found. Installing Scoop..."

    # Set execution policy for current user
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'Undefined') {
        Log "Setting execution policy to RemoteSigned for CurrentUser..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    }

    # Install Scoop
    try {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Log "Scoop installed successfully"
    }
    catch {
        Err "Failed to install Scoop: $_"
    }
}
else {
    Log "Scoop is already installed ($(scoop --version))"
}

# Install just
if (Get-Command just -ErrorAction SilentlyContinue) {
    Log "just already installed: $(just --version)"
}
else {
    Log "Installing just via Scoop..."
    try {
        scoop install just
        Log "just installed: $(just --version)"
    }
    catch {
        Err "Failed to install just: $_"
    }
}

# Download dotter to bin/
if (Test-Path "bin\dotter.exe") {
    Log "dotter already exists: $(& bin\dotter.exe --version)"
}
else {
    Log "Downloading dotter to bin\..."

    try {
        # Fetch latest version from GitHub
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/SuperCuber/dotter/releases/latest"
        $dotterVersion = $releaseInfo.tag_name -replace '^v', ''

        Log "Latest dotter version: v$dotterVersion"

        # Download dotter binary for Windows
        $dotterUrl = "https://github.com/SuperCuber/dotter/releases/download/v${dotterVersion}/dotter-windows-x64.exe"

        Invoke-WebRequest -Uri $dotterUrl -OutFile "bin\dotter.exe"

        Log "dotter downloaded successfully: $(& bin\dotter.exe --version)"
    }
    catch {
        Err "Failed to download dotter: $_"
    }
}

Write-Host ""
Log "=========================================="
Log "Bootstrap complete!"
Log "=========================================="
Log "Installed tools:"
Write-Host "  - just: $(just --version)"
Write-Host "  - dotter: $(& bin\dotter.exe --version)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run 'just install' to install packages"
Write-Host "  2. Run 'just stow' to deploy dotfiles"
Write-Host "  3. Or run 'just up' to do everything at once"
