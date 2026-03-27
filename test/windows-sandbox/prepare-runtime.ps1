#Requires -Version 7

[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Stage {
    param([string]$Message)
    Write-Host "[windows-runtime] $Message" -ForegroundColor Cyan
}

function Resolve-Architecture {
    if ($env:PROCESSOR_ARCHITECTURE -match "ARM64") {
        return "arm64"
    }

    return "x64"
}

$sandboxRoot = $PSScriptRoot
$assetsDir = Join-Path $sandboxRoot "assets"
New-Item -ItemType Directory -Force -Path $assetsDir | Out-Null

$arch = Resolve-Architecture
$existing = Get-ChildItem -Path $assetsDir -File -Filter "PowerShell-*-win-$arch.zip" |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($existing -and -not $Force) {
    Write-Stage "Runtime ZIP already present: $($existing.Name)"
    exit 0
}

Write-Stage "Resolving latest stable PowerShell release for $arch"
$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
if (-not $curl) {
    throw "curl.exe is required to resolve the latest stable PowerShell release"
}

$finalUri = (& $curl.Source --silent --show-error --location --output NUL --write-out "%{url_effective}" "https://aka.ms/powershell-release?tag=stable").Trim()

if ($finalUri -notmatch "/tag/(v(?<version>[^/]+))$") {
    throw "Failed to resolve stable PowerShell release from $finalUri"
}

$tag = $matches["version"]
$zipName = "PowerShell-$tag-win-$arch.zip"
$downloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$tag/$zipName"
$zipPath = Join-Path $assetsDir $zipName

if ($Force) {
    Get-ChildItem -Path $assetsDir -File -Filter "PowerShell-*-win-$arch.zip" | Remove-Item -Force
}

Write-Stage "Downloading $zipName"
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
Write-Stage "Saved runtime ZIP to $zipPath"
