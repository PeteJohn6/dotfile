#Requires -Version 7
$repoRoot = Split-Path -Parent $PSScriptRoot
$postDir = Join-Path $repoRoot "packages\post"

if (-not (Test-Path $postDir)) {
    Write-Host "[post] No post directory found, skipping"
    exit 0
}

$errors = 0
Get-ChildItem -Path $postDir -Filter "*.ps1" | ForEach-Object {
    Write-Host "[post] Running $($_.Name)..."
    try {
        & $_.FullName
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            Write-Host "[post] ERROR: $($_.Name) failed (exit code $LASTEXITCODE)"
            $script:errors++
        }
    } catch {
        Write-Host "[post] ERROR: $($_.Name) failed: $_"
        $script:errors++
    }
}

if ($errors -gt 0) {
    Write-Host "[post] WARNING: $errors script(s) had errors"
}

Write-Host "[post] All post-install scripts completed"
