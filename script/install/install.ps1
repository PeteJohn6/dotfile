#Requires -Version 7
# install.ps1 - Install packages from lists/windows.list via scoop

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Say($msg) { Write-Host "[install] $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "✔ $msg" -ForegroundColor Green }
function Err($msg) { Write-Error $msg; exit 1 }

# Ensure scoop is installed
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Err "scoop not found. Run bootstrap/bootstrap.ps1 first."
}

Say "Using scoop: $(scoop --version)"

# Update scoop
Say "Updating scoop..."
scoop update

# Read and install packages
$listFile = "lists/windows.list"
if (-not (Test-Path $listFile)) {
    Err "Package list not found: $listFile"
}

Say "Reading packages from $listFile"
$packages = @()
Get-Content $listFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith('#')) {
        # Remove inline comments
        $pkg = ($line -split '#')[0].Trim()
        if ($pkg) {
            $packages += $pkg
        }
    }
}

if ($packages.Count -eq 0) {
    Say "No packages to install"
    exit 0
}

Say "Installing $($packages.Count) packages: $($packages -join ', ')"

# Install packages (idempotent - scoop handles already-installed)
foreach ($pkg in $packages) {
    if (scoop list $pkg 2>$null | Select-String -Pattern "^\s*$pkg\s") {
        Ok "Already installed: $pkg"
    } else {
        try {
            scoop install $pkg
            Ok "Installed: $pkg"
        } catch {
            Err "Failed to install: $pkg"
        }
    }
}

Ok "All packages installed successfully"
