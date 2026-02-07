#Requires -Version 7
$repoRoot = Split-Path -Parent $PSScriptRoot
$postDir = Join-Path $repoRoot "packages\post"

if (-not (Test-Path $postDir)) {
    Write-Host "[post] No post directory found, skipping"
    exit 0
}

Get-ChildItem -Path $postDir -Filter "*.ps1" | ForEach-Object {
    Write-Host "[post] Running $($_.Name)..."
    & $_.FullName
}

Write-Host "[post] All post-install scripts completed"
