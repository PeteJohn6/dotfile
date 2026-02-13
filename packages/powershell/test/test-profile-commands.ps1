# =============================================================================
# PowerShell Profile Diagnostic Script
# =============================================================================
# This script tests whether profile modules can load and which prerequisites
# are available in the system PATH.

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PowerShell Profile Diagnostics" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# === Check Prerequisites ===
Write-Host "[1] Checking Prerequisites" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor DarkGray

$prerequisites = @('git', 'docker', 'fzf', 'starship')
$available = @{}

foreach ($cmd in $prerequisites) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    $available[$cmd] = [bool]$found

    if ($found) {
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "$cmd " -NoNewline
        Write-Host "found at: $($found.Source)" -ForegroundColor DarkGray
    } else {
        Write-Host "  [MISSING] " -NoNewline -ForegroundColor Red
        Write-Host "$cmd not found in PATH" -ForegroundColor Red
    }
}

# === Test Test-Command Helper ===
Write-Host "`n[2] Testing Test-Command Helper Function" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor DarkGray

# Script is now in test/ folder, so go up one level to find profile.d
$repoRoot = Split-Path $PSScriptRoot -Parent
$utilsPath = Join-Path $repoRoot 'profile.d\05-utils.ps1'
if (Test-Path $utilsPath) {
    try {
        . $utilsPath
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "05-utils.ps1 loaded successfully" -ForegroundColor White

        # Test the Test-Command function
        $testResult = Test-Command 'pwsh'
        Write-Host "  [OK] " -NoNewline -ForegroundColor Green
        Write-Host "Test-Command function works (test returned: $testResult)" -ForegroundColor White
    } catch {
        Write-Host "  [ERROR] " -NoNewline -ForegroundColor Red
        Write-Host "Failed to load 05-utils.ps1: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [ERROR] " -NoNewline -ForegroundColor Red
    Write-Host "05-utils.ps1 not found at: $utilsPath" -ForegroundColor Red
}

# === Test Individual Profile Modules ===
Write-Host "`n[3] Testing Profile Modules" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor DarkGray

$profileDir = Join-Path $repoRoot 'profile.d'
$moduleResults = @()

if (Test-Path $profileDir) {
    Get-ChildItem -Path $profileDir -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            $moduleName = $_.Name
            Write-Host "`n  Testing: " -NoNewline -ForegroundColor DarkGray
            Write-Host $moduleName -ForegroundColor White

            try {
                # Create a new scope to test loading
                & {
                    . $_.FullName
                }

                Write-Host "    [OK] " -NoNewline -ForegroundColor Green
                Write-Host "Module loaded without errors" -ForegroundColor White
                $moduleResults += [PSCustomObject]@{
                    Module = $moduleName
                    Status = 'OK'
                    Error = $null
                }
            } catch {
                Write-Host "    [ERROR] " -NoNewline -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                $moduleResults += [PSCustomObject]@{
                    Module = $moduleName
                    Status = 'ERROR'
                    Error = $_.Exception.Message
                }
            }
        }
}

# === Check Available Functions ===
Write-Host "`n[4] Checking for Expected Functions" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor DarkGray

# Now load the full profile to check what functions are available
Write-Host "`n  Loading full profile..." -ForegroundColor DarkGray
$profilePath = Join-Path $repoRoot 'Microsoft.PowerShell_profile.ps1'

try {
    # Enable debug output for testing
    $env:PROFILE_DEBUG = 1
    . $profilePath
} catch {
    Write-Host "  [ERROR] Failed to load main profile: $_" -ForegroundColor Red
}

# Check for expected functions
$expectedFunctions = @('gitwt', 'gitwts', 'gits', 'gitl')
if ($available['docker']) {
    $expectedFunctions += @(
        'dockerfshell',
        'dockerflogs',
        'dockerfrmi',
        'dockerfrm',
        'dockerfrun',
        'dockerfexec'
    )
}
Write-Host "`n  Checking for expected functions:" -ForegroundColor DarkGray

foreach ($func in $expectedFunctions) {
    $found = Get-Command $func -ErrorAction SilentlyContinue
    if ($found) {
        Write-Host "    [OK] " -NoNewline -ForegroundColor Green
        Write-Host "$func " -NoNewline
        Write-Host "($($found.CommandType))" -ForegroundColor DarkGray
    } else {
        Write-Host "    [MISSING] " -NoNewline -ForegroundColor Red
        Write-Host $func -ForegroundColor Red
    }
}

# === Summary ===
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$missingPrereqs = $prerequisites | Where-Object { -not $available[$_] }
if ($missingPrereqs.Count -gt 0) {
    Write-Host "`nMissing Prerequisites: " -NoNewline -ForegroundColor Yellow
    Write-Host ($missingPrereqs -join ', ') -ForegroundColor Red
    Write-Host "  -> This may prevent some profile modules from loading" -ForegroundColor DarkGray
}

$failedMods = $moduleResults | Where-Object { $_.Status -eq 'ERROR' }
if ($failedMods.Count -gt 0) {
    Write-Host "`nFailed Modules:" -ForegroundColor Yellow
    $failedMods | ForEach-Object {
        Write-Host "  - $($_.Module): " -NoNewline -ForegroundColor Red
        Write-Host $_.Error -ForegroundColor DarkGray
    }
}

if ($missingPrereqs.Count -eq 0 -and $failedMods.Count -eq 0) {
    Write-Host "`n  All checks passed! " -ForegroundColor Green
    Write-Host "  If commands are still missing, check PATH or restart PowerShell." -ForegroundColor DarkGray
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
