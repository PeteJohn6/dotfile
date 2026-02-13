# =============================================================================
# PowerShell Profile - Utilities Module
# =============================================================================
# Provides common helper functions for all profile modules

# Test-Command: Check if a command exists in PATH
function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Cache directory for storing completions and other generated files
$script:ProfileCache = Join-Path (Split-Path -Parent $PROFILE.CurrentUserAllHosts) 'cache'
if (-not (Test-Path $script:ProfileCache)) {
    New-Item -ItemType Directory $script:ProfileCache | Out-Null
}
