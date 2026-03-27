#Requires -Version 7
# Bootstrap script for Windows
# Installs Scoop, just, and dotter via Scoop

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

# Check if Scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Log "Scoop not found. Installing Scoop..."

    # Set execution policy for current user
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    if ($currentPolicy -eq 'Restricted' -or $currentPolicy -eq 'Undefined') {
        Log "Setting execution policy to RemoteSigned for CurrentUser..."
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
        }
        catch {
            Warn "Unable to persist CurrentUser execution policy cleanly; continuing with effective policy '$((Get-ExecutionPolicy))'. Details: $($_.Exception.Message)"
        }
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

# Install dotter
if (Get-Command dotter.exe -ErrorAction SilentlyContinue) {
    Log "dotter already installed: $(dotter.exe --version)"
}
else {
    Log "Installing dotter via Scoop..."
    try {
        scoop install dotter
        Log "dotter installed: $(dotter.exe --version)"
    }
    catch {
        Err "Failed to install dotter: $_"
    }
}

# Setup local.toml from default template
Write-Host ""
$defaultFile = ".dotter\default\windows.toml"

if (Test-Path ".dotter\local.toml") {
    Log "local.toml already exists, showing diff:"
    $existing = Get-Content ".dotter\local.toml" -Raw
    $default = Get-Content $defaultFile -Raw
    if ($existing -ne $default) {
        Write-Host "--- Default template ---"
        Get-Content $defaultFile
        Write-Host ""
        Write-Host "--- Current local.toml ---"
        Get-Content ".dotter\local.toml"
    } else {
        Log "Files are identical"
    }
}
else {
    Copy-Item $defaultFile ".dotter\local.toml"
    Log "Copied $defaultFile -> .dotter\local.toml"
}

Write-Host ""
Log "=========================================="
Log "Bootstrap complete!"
Log "=========================================="
Log "Installed tools:"
Write-Host "  - just: $(just --version)"
Write-Host "  - dotter: $(dotter.exe --version)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run 'just install' to install packages"
Write-Host "  2. Run 'just stow' to deploy dotfiles"
Write-Host "  3. Or run 'just up' to do everything at once"
