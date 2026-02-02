#Requires -Version 7
# post.ps1 - Run all post-installation scripts

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Say($msg) { Write-Host "[post] $msg" -ForegroundColor Cyan }
function Ok($msg) { Write-Host "✔ $msg" -ForegroundColor Green }
function Err($msg) { Write-Host "✘ $msg" -ForegroundColor Red }

$postDir = $PSScriptRoot
Say "Running post-installation scripts from $postDir"

# Find all .ps1 scripts except post.ps1 itself
$scripts = Get-ChildItem -Path $postDir -Filter "*.ps1" |
    Where-Object { $_.Name -ne "post.ps1" }

if ($scripts.Count -eq 0) {
    Say "No post-installation scripts found"
    exit 0
}

Say "Found $($scripts.Count) script(s) to run"

# Run each script
foreach ($script in $scripts) {
    Say "Running: $($script.Name)"
    try {
        & $script.FullName
        Ok "Completed: $($script.Name)"
    } catch {
        Err "Failed: $($script.Name) - $_"
    }
}

Ok "All post-installation scripts completed"
