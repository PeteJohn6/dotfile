#Requires -Version 7
$listFile = Join-Path $PSScriptRoot "..\packages\packages.list"

function Parse-Packages {
    Get-Content $listFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $main = ($_ -split '\|')[0]
        $raw = ($main -split '@')[0].Trim()
        if ($raw -match '^([^\(\)\s]+)\(([^\(\)\s]+)\)$') {
            $pkg = $matches[1]; $cli = $matches[2]
        } else {
            $pkg = $raw; $cli = $raw
        }
        $tag = if ($main -match '@(\w+)') { $matches[1] } else { $null }
        if (-not $tag -or $tag -eq 'windows') {
            [PSCustomObject]@{ Pkg = $pkg; Cli = $cli }
        }
    }
}

function Ensure-ScoopBucket {
    param([string]$Bucket)
    $known = scoop bucket list 2>&1 | Select-String -Pattern "^\s*$Bucket\s" -Quiet
    if (-not $known) {
        Write-Host "[install] Adding scoop bucket: $Bucket"
        scoop bucket add $Bucket
    } else {
        Write-Host "[install] Scoop bucket already added: $Bucket"
    }
}

function Get-MappedPackageName {
    param([string]$Package)
    # Scoop names match packages.list names; extend here if needed
    return $Package
}

function Install-ScoopPackage {
    param([string]$Package)
    $mapped = Get-MappedPackageName $Package
    Write-Host "[install] Installing: $mapped"
    $output = scoop install $mapped 2>&1 | Out-String
    Write-Host $output.Trim()
    if ($LASTEXITCODE -ne 0 -and $output -notmatch "already installed") {
        return $false
    }
    return $true
}

# --- Main logic ---

Ensure-ScoopBucket "extras"

$packages = @(Parse-Packages)
Write-Host "[install] Installing $($packages.Count) package(s)..."
Write-Host ""

$succeeded = 0
$skipped = 0
$failed = 0
$skippedPkgs = @()
$failedPkgs = @()

foreach ($entry in $packages) {
    if (Get-Command $entry.Cli -ErrorAction SilentlyContinue) {
        Write-Host "[install] Skipping: $($entry.Pkg) (already satisfied: $($entry.Cli))"
        $skipped++; $skippedPkgs += $entry.Pkg
        continue
    }
    if (Install-ScoopPackage $entry.Pkg) {
        $succeeded++
    } else {
        Write-Host "[install] WARN: Failed to install: $($entry.Pkg)"
        $failed++; $failedPkgs += $entry.Pkg
    }
}

Write-Host ""
Write-Host "[install] =========================================="
Write-Host "[install] Install complete: $succeeded succeeded, $skipped skipped, $failed failed"
if ($skipped -gt 0) {
    Write-Host "[install] Skipped packages: $($skippedPkgs -join ' ')"
}
if ($failed -gt 0) {
    Write-Host "[install] Failed packages: $($failedPkgs -join ' ')"
}
Write-Host "[install] =========================================="

if ($failed -gt 0) {
    exit 1
}
