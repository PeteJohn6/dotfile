[CmdletBinding()]
param(
    [ValidateSet("Logon", "Full")]
    [string]$Mode = "Full"
)

$ErrorActionPreference = "Stop"

$logsDir = "C:\logs"
$probePath = Join-Path $logsDir "bootstrap-probe.txt"
$bootstrapLog = Join-Path $logsDir "sandbox-bootstrap.log"
$statePath = Join-Path $logsDir "sandbox-state.json"
$runtimeRoot = "C:\Runtime\PowerShell\7"
$repoMount = "C:\repo-ro"
$workspace = "C:\workspace"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    "$timestamp $Message" | Out-File -FilePath $bootstrapLog -Append -Encoding utf8
}

function Write-State {
    param(
        [string]$Phase,
        [string]$Detail,
        [bool]$Terminal = $false,
        [bool]$Success = $false,
        [int]$ExitCode = 0
    )

    @{
        phase = $Phase
        detail = $Detail
        mode = $Mode
        source = "stage0"
        terminal = $Terminal
        success = $Success
        exit_code = $ExitCode
        updated_at = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 3 | Set-Content -Path $statePath -Encoding utf8
}

function Read-State {
    if (-not (Test-Path $statePath -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -Path $statePath -Raw | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
"reached-bootstrap-command $(Get-Date -Format o)" | Out-File -FilePath $probePath -Encoding utf8

Write-Log "bootstrap start"
Write-Log "mode=$Mode"
Write-Log "whoami=$(whoami)"
Write-Log "pwd=$((Get-Location).Path)"
Write-State -Phase "bootstrap_command_reached" -Detail "stage-0 bootstrap command reached the sandbox user session"

$arch = if ($env:PROCESSOR_ARCHITECTURE -match "ARM64") { "arm64" } else { "x64" }
$zip = Get-ChildItem -Path "C:\harness" -File -Filter "PowerShell-*-win-$arch.zip" |
    Sort-Object Name -Descending |
    Select-Object -First 1

if (-not $zip) {
    Write-Log "runtime ZIP missing in C:\harness for arch=$arch"
    Write-State -Phase "runtime_zip_missing" -Detail "no matching PowerShell ZIP found in C:\harness" -Terminal $true -ExitCode 20
    exit 20
}

$pwsh = Join-Path $runtimeRoot "pwsh.exe"
if (-not (Test-Path $pwsh)) {
    Write-Log "expanding ZIP from $($zip.FullName) to $runtimeRoot"
    Write-State -Phase "runtime_expanding" -Detail "expanding $($zip.Name) to $runtimeRoot"
    New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null
    Expand-Archive -Path $zip.FullName -DestinationPath $runtimeRoot -Force
}

if (-not (Test-Path $pwsh)) {
    Write-Log "pwsh.exe still missing after extraction"
    Write-State -Phase "runtime_missing_pwsh" -Detail "pwsh.exe is missing after ZIP expansion" -Terminal $true -ExitCode 21
    exit 21
}

$env:PATH = "$runtimeRoot;$env:PATH"
Write-Log "pwsh ready: $pwsh"
Write-State -Phase "pwsh_ready" -Detail "side-loaded pwsh.exe is ready at $pwsh"

if ($Mode -eq "Logon") {
    Write-Log "logon-mode complete"
    Write-State -Phase "logon_mode_complete" -Detail "CLI-driven stage-0 validation completed successfully" -Terminal $true -Success $true
    exit 0
}

$runHarness = "C:\harness\run-harness.ps1"
if (-not (Test-Path $runHarness)) {
    Write-Log "run-harness missing: $runHarness"
    Write-State -Phase "run_harness_missing" -Detail "missing guest harness script: $runHarness" -Terminal $true -ExitCode 22
    exit 22
}

Write-State -Phase "handoff_to_stage1" -Detail "launching run-harness.ps1 under pwsh"
& $pwsh -NoLogo -NoProfile -File $runHarness -RepoMount $repoMount -LogsDir $logsDir -Workspace $workspace *>> $bootstrapLog
$code = $LASTEXITCODE
Write-Log "pwsh finished exit=$code"
if ($code -eq 0) {
    Write-State -Phase "full_mode_complete" -Detail "stage-1 completed successfully" -Terminal $true -Success $true
} else {
    $currentState = Read-State
    if (-not ($currentState -and $currentState.terminal)) {
    Write-State -Phase "full_mode_failed" -Detail "stage-1 exited with code $code" -Terminal $true -ExitCode $code
    }
}
exit $code
