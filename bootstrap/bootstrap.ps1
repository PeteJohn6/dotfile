#Requires -Version 7
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Log($msg)  { Write-Host "[bootstrap] $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Warning $msg }
function Err($msg)  { Write-Error $msg; exit 1 }

# Ensure Chocolatey is installed

# Ensure scoop packages are installed

# install justfile and dotter by scoop

