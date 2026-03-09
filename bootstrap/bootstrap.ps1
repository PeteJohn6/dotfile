#Requires -Version 7
# Bootstrap script for Windows
# Installs Scoop and just via package manager, downloads dotter to local bin/

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log($msg)  { Write-Host "[bootstrap] $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Warning "[bootstrap] $msg" }
function Err($msg)  { Write-Error "[bootstrap] $msg"; exit 1 }

function Test-DotterBinary {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path -PathType Leaf)) {
        return $null
    }

    try {
        $version = & $Path --version 2>$null
        if ([string]::IsNullOrWhiteSpace($version)) {
            return $null
        }
        return $version.Trim()
    }
    catch {
        return $null
    }
}

function Get-AssetUrls {
    param(
        [Parameter(Mandatory = $true)]$ReleaseInfo
    )

    @(
        $ReleaseInfo.assets |
            ForEach-Object { $_.browser_download_url } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Resolve-DotterAssetUrl {
    param(
        [Parameter(Mandatory = $true)][string[]]$AssetUrls,
        [Parameter(Mandatory = $true)][string]$Arch
    )

    $bestUrl = $null
    $bestScore = [int]::MinValue

    foreach ($url in $AssetUrls) {
        $name = [IO.Path]::GetFileName($url).ToLowerInvariant()
        if ($name -match '\.(sha256|sha512|sig|asc|txt)$') {
            continue
        }
        if ($name -notmatch 'windows') {
            continue
        }
        if ($name -notmatch 'dotter') {
            continue
        }
        if ($name -notmatch '\.exe$') {
            continue
        }

        $score = 50
        switch ($Arch) {
            'arm64' {
                if ($name -match 'arm64|aarch64') { $score = 100 }
                elseif ($name -match 'x64|x86_64|amd64') { $score = 80 }
                else { continue }
            }
            default {
                if ($name -match 'x64|x86_64|amd64') { $score = 100 }
                elseif ($name -match 'arm64|aarch64') { $score = 70 }
                else { continue }
            }
        }

        if ($score -gt $bestScore) {
            $bestScore = $score
            $bestUrl = $url
        }
    }

    if ([string]::IsNullOrWhiteSpace($bestUrl)) {
        $list = ($AssetUrls | ForEach-Object { "  - $_" }) -join "`n"
        Err "Failed to match a Windows dotter asset for arch '$Arch'. Available assets:`n$list"
    }

    return $bestUrl
}

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
$dotterPath = "bin\dotter.exe"
$dotterVersion = Test-DotterBinary -Path $dotterPath
if ($dotterVersion) {
    Log "dotter already exists: $dotterVersion"
} else {
    if (Test-Path $dotterPath) {
        Warn "Existing bin\dotter.exe is invalid, re-downloading..."
        Remove-Item -Path $dotterPath -Force
    }

    Log "Downloading dotter to bin\..."

    try {
        # Fetch latest version from GitHub
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/SuperCuber/dotter/releases/latest" -ErrorAction Stop
        $releaseVersion = $releaseInfo.tag_name -replace '^v', ''
        if ([string]::IsNullOrWhiteSpace($releaseVersion)) {
            Err "Failed to resolve dotter release version"
        }
        Log "Latest dotter version: v$releaseVersion"

        $assetUrls = Get-AssetUrls -ReleaseInfo $releaseInfo
        if ($assetUrls.Count -eq 0) {
            Err "No release assets returned by GitHub API"
        }

        $arch = if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64') { 'arm64' } else { 'x64' }
        $dotterUrl = Resolve-DotterAssetUrl -AssetUrls $assetUrls -Arch $arch
        Log "Selected dotter asset: $([IO.Path]::GetFileName($dotterUrl))"

        $tmpPath = "bin\dotter.exe.tmp"
        if (Test-Path $tmpPath) {
            Remove-Item -Path $tmpPath -Force
        }
        Invoke-WebRequest -Uri $dotterUrl -OutFile $tmpPath -ErrorAction Stop

        $tmpFile = Get-Item $tmpPath -ErrorAction Stop
        if ($tmpFile.Length -lt 102400) {
            Remove-Item -Path $tmpPath -Force -ErrorAction SilentlyContinue
            Err "Downloaded dotter binary is unexpectedly small ($($tmpFile.Length) bytes)"
        }

        Move-Item -Path $tmpPath -Destination $dotterPath -Force
        $dotterVersion = Test-DotterBinary -Path $dotterPath
        if (-not $dotterVersion) {
            Err "Downloaded file is not a valid dotter binary"
        }

        Log "dotter downloaded successfully: $dotterVersion"
    }
    catch {
        Err "Failed to download dotter: $_"
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
Write-Host "  - dotter: $(& bin\dotter.exe --version)"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Run 'just install' to install packages"
Write-Host "  2. Run 'just stow' to deploy dotfiles"
Write-Host "  3. Or run 'just up' to do everything at once"
