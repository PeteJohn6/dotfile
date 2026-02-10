#Requires -Version 7

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
    Write-Host "[post:nvim] Neovim not installed, skipping"
    exit 0
}

Write-Host "[post:nvim] Bootstrapping lazy.nvim..."
nvim --headless +qa

Write-Host "[post:nvim] Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa
Write-Host "[post:nvim] Neovim plugins installed"
