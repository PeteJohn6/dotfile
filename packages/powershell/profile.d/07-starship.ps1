# =============================================================================
# PowerShell Profile - Starship Module
# =============================================================================
# Initialize the Starship prompt when the binary is available.

if (-not (Test-Command starship)) {
    return
}

Invoke-Expression (&starship init powershell)
