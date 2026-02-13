# =============================================================================
# PowerShell Profile - Main Entry Point
# =============================================================================

# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Import Chocolatey Profile for tab-completion support
# See https://ch0.co/tab-completion for details
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# === Auto-load profile.d modules ===
# Modules are loaded in alphabetical order (numeric prefix determines sequence)
$profileDir = Join-Path $PSScriptRoot 'profile.d'
if (Test-Path $profileDir) {
    $loadedModules = @()
    $failedModules = @()

    Get-ChildItem -Path $profileDir -Filter '*.ps1' -File |
        Sort-Object Name |
        ForEach-Object {
            try {
                . $_.FullName
                $loadedModules += $_.Name
            } catch {
                $failedModules += $_.Name
                Write-Warning "Failed to load profile module: $($_.Name) - $_"
            }
        }

    # Display profile load summary (only in debug mode)
    if ($env:PROFILE_DEBUG) {
        Write-Host "`n[PowerShell Profile]" -ForegroundColor Cyan
        Write-Host "  Location: " -NoNewline -ForegroundColor DarkGray
        Write-Host $PSScriptRoot -ForegroundColor White

        if ($loadedModules.Count -gt 0) {
            Write-Host "  Loaded modules: " -NoNewline -ForegroundColor DarkGray
            Write-Host ($loadedModules -join ', ') -ForegroundColor Green
        }

        if ($failedModules.Count -gt 0) {
            Write-Host "  Failed modules: " -NoNewline -ForegroundColor DarkGray
            Write-Host ($failedModules -join ', ') -ForegroundColor Red
        }

        Write-Host ""  # Blank line for spacing
    }
}
