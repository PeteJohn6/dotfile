#Requires -Version 7
$listFile = Join-Path $PSScriptRoot "..\packages\packages.list"
$currentPlatform = 'windows'
$supportedPlatforms = @('windows', 'macos', 'linux')

function Throw-ParseError {
    param(
        [int]$LineNumber,
        [string]$Message
    )

    throw "[install] ERROR: Failed to parse ${listFile}:${LineNumber}: $Message"
}

function Test-PlatformMatch {
    param(
        [string[]]$Platforms,
        [string]$CurrentPlatform
    )

    if (-not $Platforms -or $Platforms.Count -eq 0) {
        return $true
    }

    return $Platforms -contains $CurrentPlatform
}

function Parse-MainEntry {
    param(
        [string]$Main,
        [int]$LineNumber
    )

    $main = $Main.Trim()
    $platforms = @()

    if (-not $main) {
        return [PSCustomObject]@{
            Pkg = ''
            Cli = ''
            Platforms = @()
        }
    }

    $selectorMatch = [regex]::Match($main, '@([A-Za-z0-9_-]+(?:,[A-Za-z0-9_-]+)*)$')
    if ($selectorMatch.Success) {
        $selector = $selectorMatch.Groups[1].Value
        $platforms = @($selector.Split(','))
        foreach ($platform in $platforms) {
            if ($platform -notin $supportedPlatforms) {
                Throw-ParseError -LineNumber $LineNumber -Message "unsupported platform '$platform' in selector"
            }
        }

        $main = $main.Substring(0, $selectorMatch.Index).Trim()
    }

    if ($main -match '@') {
        Throw-ParseError -LineNumber $LineNumber -Message "unsupported selector syntax; expected @platform[,platform...] without spaces"
    }

    if ($main -match '^([^\(\)\s]+)\(([^\(\)\s]+)\)$') {
        return [PSCustomObject]@{
            Pkg = $matches[1]
            Cli = $matches[2]
            Platforms = $platforms
        }
    }

    if ($main -match '^[^\(\)\s]+$') {
        return [PSCustomObject]@{
            Pkg = $main
            Cli = $main
            Platforms = $platforms
        }
    }

    Throw-ParseError -LineNumber $LineNumber -Message "invalid package entry syntax: '$main'"
}

function Parse-Packages {
    $lineNumber = 0

    Get-Content $listFile | ForEach-Object {
        $lineNumber++
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }

        $segments = $_ -split '\|', 2
        if ($segments.Count -gt 1) {
            $aliasPart = (($segments[1] -split '#', 2)[0]).Trim()
            if ($aliasPart -match '(^|\s)@') {
                Throw-ParseError -LineNumber $lineNumber -Message "platform selectors must appear before | aliases"
            }
        }

        $parsed = Parse-MainEntry -Main $segments[0] -LineNumber $lineNumber
        if (-not $parsed.Pkg) { return }
        if (Test-PlatformMatch -Platforms $parsed.Platforms -CurrentPlatform $currentPlatform) {
            [PSCustomObject]@{
                Pkg = $parsed.Pkg
                Cli = $parsed.Cli
            }
        }
    }
}

function Ensure-ScoopBucket {
    param([string]$Bucket)
    $known = scoop bucket list 2>&1 | Select-String -Pattern "^\s*$Bucket\s" -Quiet
    if (-not $known) {
        Write-Host "[pre-install:scoop] Adding scoop bucket: $Bucket"
        scoop bucket add $Bucket
    } else {
        Write-Host "[pre-install:scoop] Scoop bucket already added: $Bucket"
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

function Run-PreInstall {
    Write-Host "[install] Running pre-install steps..."
    Ensure-ScoopBucket "extras"
    Write-Host "[pre-install:scoop] Pre-install complete"
}

# --- Main logic ---

Run-PreInstall

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
