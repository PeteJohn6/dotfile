#Requires -Version 7
$listFile = Join-Path $PSScriptRoot "..\packages\packages.list"

function Parse-Packages {
    Get-Content $listFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        $main = ($_ -split '\|')[0]
        $pkg = ($main -split '@')[0].Trim()
        $tag = if ($main -match '@(\w+)') { $matches[1] } else { $null }
        if (-not $tag -or $tag -eq 'windows') { $pkg }
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
$failed = 0

foreach ($pkg in $packages) {
    if (Install-ScoopPackage $pkg) {
        $succeeded++
    } else {
        Write-Host "[install] WARN: Failed to install: $pkg"
        $failed++
    }
}

Write-Host ""
Write-Host "[install] =========================================="
Write-Host "[install] Install complete: $succeeded succeeded, $failed failed"
Write-Host "[install] =========================================="

if ($failed -gt 0) {
    exit 1
}
