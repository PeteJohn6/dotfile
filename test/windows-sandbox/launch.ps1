#Requires -Version 7

[CmdletBinding()]
param(
    [ValidateSet("Logon", "Full")]
    [string]$Mode = "Full",
    [switch]$ValidateOnly,
    [switch]$NoWait,
    [switch]$KeepOpen,
    [switch]$StopExisting,
    [int]$TimeoutSeconds = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Stage {
    param([string]$Message)
    Write-Host "[windows-sandbox] $Message" -ForegroundColor Cyan
}

function Test-PowerShellSyntax {
    param([Parameter(Mandatory = $true)][string]$Path)

    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $messages = $errors | ForEach-Object { $_.Message }
        throw "PowerShell syntax validation failed for '$Path': $($messages -join '; ')"
    }
}

function Escape-XmlValue {
    param([Parameter(Mandatory = $true)][string]$Value)
    [System.Security.SecurityElement]::Escape($Value)
}

function Resolve-Architecture {
    if ($env:PROCESSOR_ARCHITECTURE -match "ARM64") {
        return "arm64"
    }

    return "x64"
}

function Resolve-PowerShellZip {
    param(
        [Parameter(Mandatory = $true)][string]$AssetsDir,
        [Parameter(Mandatory = $true)][string]$Arch
    )

    $matches = Get-ChildItem -Path $AssetsDir -File -Filter "PowerShell-*-win-$Arch.zip" |
        Sort-Object Name -Descending

    if (-not $matches) {
        throw "Missing PowerShell ZIP in $AssetsDir. Run 'just --justfile test/justfile windows-runtime-prepare' first."
    }

    return $matches[0]
}

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -Path $Path -Raw | ConvertFrom-Json -AsHashtable
    }
    catch {
        return $null
    }
}

function Write-HostState {
    param(
        [Parameter(Mandatory = $true)][string]$LogsDir,
        [Parameter(Mandatory = $true)][hashtable]$State
    )

    $hostStatePath = Join-Path $LogsDir "host-state.json"
    $State | ConvertTo-Json -Depth 6 | Set-Content -Path $hostStatePath -Encoding utf8NoBOM
}

function Get-WsbBinary {
    $cachedBinary = Get-Variable -Name WsbBinary -Scope Script -ValueOnly -ErrorAction SilentlyContinue
    if (-not $cachedBinary) {
        $command = Get-Command wsb -ErrorAction SilentlyContinue
        if (-not $command) {
            throw "wsb.exe is not available. Windows Sandbox CLI is required on this host."
        }

        $script:WsbBinary = $command.Source
        $cachedBinary = $script:WsbBinary
    }

    return $cachedBinary
}

function Invoke-Wsb {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [switch]$IgnoreExitCode
    )

    $output = & (Get-WsbBinary) @Arguments 2>&1 | Out-String
    $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
    $trimmedOutput = $output.Trim()

    if (-not $IgnoreExitCode -and $exitCode -ne 0) {
        $details = if ($trimmedOutput) { $trimmedOutput } else { "(no output)" }
        throw "wsb $($Arguments -join ' ') failed with exit code $exitCode. Output: $details"
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output = $trimmedOutput
    }
}

function Get-RunningSandboxIds {
    $result = Invoke-Wsb -Arguments @("list", "--raw")
    if ([string]::IsNullOrWhiteSpace($result.Output)) {
        return @()
    }

    $payload = $result.Output | ConvertFrom-Json -AsHashtable
    return @(
        $payload.WindowsSandboxEnvironments |
            ForEach-Object {
                if ($_ -is [hashtable]) {
                    "$($_.Id)"
                } elseif ($_.PSObject.Properties["Id"]) {
                    "$($_.Id)"
                } else {
                    "$_"
                }
            } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Stop-SandboxSessions {
    param([string[]]$SessionIds = @())

    foreach ($sessionId in @($SessionIds | Sort-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($sessionId)) {
            continue
        }

        Invoke-Wsb -Arguments @("stop", "--id", $sessionId) -IgnoreExitCode | Out-Null
    }
}

function Wait-ForSessionsToStop {
    param(
        [string[]]$SessionIds = @(),
        [int]$TimeoutSeconds = 30
    )

    if (-not $SessionIds) {
        return @()
    }

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $runningIds = @(Get-RunningSandboxIds)
        $remaining = @($SessionIds | Where-Object { $_ -in $runningIds })
        if ($remaining.Count -eq 0) {
            return @()
        }

        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)

    $runningIds = @(Get-RunningSandboxIds)
    return @($SessionIds | Where-Object { $_ -in $runningIds })
}

function Wait-ForSandboxId {
    param(
        [string[]]$BaselineSessionIds = @(),
        [Parameter(Mandatory = $true)][string]$LogsDir,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$Mode,
        [int]$TimeoutSeconds = 90
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $runningIds = @(Get-RunningSandboxIds)
        $newIds = @($runningIds | Where-Object { $_ -notin $BaselineSessionIds })

        if ($newIds.Count -eq 1) {
            return $newIds[0]
        }

        if ($newIds.Count -gt 1) {
            throw "Multiple new sandbox sessions appeared unexpectedly: $($newIds -join ', ')"
        }

        Write-HostState -LogsDir $LogsDir -State @{
            run_id = $RunId
            mode = $Mode
            phase = "waiting_for_sandbox_id"
            detail = "waiting for wsb start to surface a new sandbox id"
            sandbox_id = $null
            active_session_ids = $runningIds
            terminal = $false
            success = $false
            updated_at = (Get-Date).ToString("o")
        }
        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for a new Windows Sandbox session id"
}

function Wait-ForExecProbe {
    param(
        [Parameter(Mandatory = $true)][string]$SandboxId,
        [Parameter(Mandatory = $true)][ValidateSet("System", "ExistingLogin")][string]$RunAs,
        [Parameter(Mandatory = $true)][string]$ProbePath,
        [Parameter(Mandatory = $true)][string]$ProbeCommand,
        [Parameter(Mandatory = $true)][string]$WaitingPhase,
        [Parameter(Mandatory = $true)][string]$ReadyPhase,
        [Parameter(Mandatory = $true)][string]$WaitingDetail,
        [Parameter(Mandatory = $true)][string]$ReadyDetail,
        [Parameter(Mandatory = $true)][string]$LogsDir,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$Mode,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastCliError = $null

    while ((Get-Date) -lt $deadline) {
        $runningIds = @(Get-RunningSandboxIds)
        if ($SandboxId -notin $runningIds) {
            throw "Sandbox session $SandboxId exited while waiting for $RunAs guest command readiness"
        }

        $result = Invoke-Wsb -Arguments @(
            "exec"
            "--id"
            $SandboxId
            "--run-as"
            $RunAs
            "--command"
            $ProbeCommand
        ) -IgnoreExitCode

        if ($result.ExitCode -eq 0 -and (Test-Path $ProbePath -PathType Leaf)) {
            Write-HostState -LogsDir $LogsDir -State @{
                run_id = $RunId
                mode = $Mode
                phase = $ReadyPhase
                detail = $ReadyDetail
                sandbox_id = $SandboxId
                active_session_ids = $runningIds
                terminal = $false
                success = $false
                updated_at = (Get-Date).ToString("o")
            }
            Write-Stage "Observed state: $ReadyPhase"
            return
        }

        $lastCliError = if ($result.Output) {
            $result.Output
        } else {
            "wsb exec exited with code $($result.ExitCode)"
        }

        Write-HostState -LogsDir $LogsDir -State @{
            run_id = $RunId
            mode = $Mode
            phase = $WaitingPhase
            detail = "$WaitingDetail Last CLI result: $lastCliError"
            sandbox_id = $SandboxId
            active_session_ids = $runningIds
            terminal = $false
            success = $false
            updated_at = (Get-Date).ToString("o")
        }
        Start-Sleep -Seconds 2
    }

    throw "Timed out waiting for $RunAs guest command readiness. Last CLI result: $lastCliError"
}

function Start-SandboxConnection {
    param([Parameter(Mandatory = $true)][string]$SandboxId)

    Start-Process -FilePath (Get-WsbBinary) -ArgumentList @("connect", "--id", $SandboxId) | Out-Null
}

function Start-GuestExecJob {
    param(
        [Parameter(Mandatory = $true)][string]$SandboxId,
        [Parameter(Mandatory = $true)][ValidateSet("ExistingLogin", "System")][string]$RunAs,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$LogsDir
    )

    $outputPath = Join-Path $LogsDir "guest-exec.output.log"
    foreach ($path in @($outputPath)) {
        if (Test-Path $path -PathType Leaf) {
            Remove-Item -Path $path -Force
        }
    }

    $arguments = @(
        "exec"
        "--id"
        $SandboxId
        "--run-as"
        $RunAs
        "--command"
        $Command
    )

    return Start-Job -ScriptBlock {
        param(
            [string]$WsbBinary,
            [string[]]$Arguments,
            [string]$OutputPath
        )

        $ErrorActionPreference = "Continue"
        try {
            $output = & $WsbBinary @Arguments 2>&1 | Out-String
            $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
            $trimmedOutput = $output.Trim()
        }
        catch {
            $exitCode = 1
            $trimmedOutput = $_.Exception.Message
        }

        Set-Content -Path $OutputPath -Value $trimmedOutput -Encoding utf8NoBOM
        [pscustomobject]@{
            ExitCode = $exitCode
            Output = $trimmedOutput
        }
    } -ArgumentList (Get-WsbBinary), $arguments, $outputPath
}

function Get-GuestExecJobResult {
    param([Parameter(Mandatory = $true)][System.Management.Automation.Job]$GuestExecJob)

    $records = @(Receive-Job -Job $GuestExecJob -Keep -ErrorAction SilentlyContinue)
    foreach ($record in $records) {
        if ($record.PSObject.Properties["ExitCode"]) {
            return @{
                ExitCode = [int]$record.ExitCode
                Output = [string]$record.Output
            }
        }
    }

    $reason = $GuestExecJob.ChildJobs[0].JobStateInfo.Reason
    return @{
        ExitCode = 1
        Output = if ($reason) { $reason.Message } else { "(no output)" }
    }
}

function Get-FileText {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path -PathType Leaf)) {
        return $null
    }

    $text = Get-Content -Path $Path -Raw
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    return $text.Trim()
}

function Wait-ForGuestTerminalState {
    param(
        [Parameter(Mandatory = $true)][string]$SandboxId,
        [Parameter(Mandatory = $true)][System.Management.Automation.Job]$GuestExecJob,
        [Parameter(Mandatory = $true)][string]$LogsDir,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$Mode,
        [int]$TimeoutSeconds = 300
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $bootstrapProbePath = Join-Path $LogsDir "bootstrap-probe.txt"
    $guestStatePath = Join-Path $LogsDir "sandbox-state.json"
    $outputPath = Join-Path $LogsDir "guest-exec.output.log"
    $lastRenderedPhase = $null

    while ((Get-Date) -lt $deadline) {
        $runningIds = @(Get-RunningSandboxIds)
        $guestState = Read-JsonFile -Path $guestStatePath
        $guestExecJobResult = if ($GuestExecJob.State -in @("Completed", "Failed", "Stopped")) {
            Get-GuestExecJobResult -GuestExecJob $GuestExecJob
        } else {
            $null
        }

        if ($guestState) {
            $phase = $guestState.phase
            $detail = $guestState.detail
        } elseif (Test-Path $bootstrapProbePath -PathType Leaf) {
            $phase = "bootstrap_command_reached"
            $detail = "sandbox-bootstrap.ps1 reached its first probe point"
        } elseif ($GuestExecJob.State -in @("Running", "NotStarted")) {
            $phase = "guest_command_running"
            $detail = "guest command is running but no guest state has been reported yet"
        } else {
            $phase = "guest_command_exited"
            $detail = "guest command exited before any guest state was reported"
        }

        Write-HostState -LogsDir $LogsDir -State @{
            run_id = $RunId
            mode = $Mode
            phase = $phase
            detail = $detail
            sandbox_id = $SandboxId
            active_session_ids = $runningIds
            guest_exec_exit_code = if ($guestExecJobResult) { $guestExecJobResult.ExitCode } else { $null }
            terminal = $false
            success = $false
            updated_at = (Get-Date).ToString("o")
        }

        if ($phase -ne $lastRenderedPhase) {
            Write-Stage "Observed state: $phase"
            $lastRenderedPhase = $phase
        }

        if ($guestState -and $guestState.terminal) {
            if ($GuestExecJob.State -notin @("Completed", "Failed", "Stopped")) {
                $null = Wait-Job -Job $GuestExecJob -Timeout 5
                $guestExecJobResult = if ($GuestExecJob.State -in @("Completed", "Failed", "Stopped")) {
                    Get-GuestExecJobResult -GuestExecJob $GuestExecJob
                } else {
                    $null
                }
            }

            if ($guestState.success) {
                Write-Stage "Sandbox reached terminal success state: $($guestState.phase)"
                return @{
                    guest_state = $guestState
                    active_session_ids = $runningIds
                    guest_exec_exit_code = if ($guestExecJobResult) { $guestExecJobResult.ExitCode } else { $null }
                }
            }

            throw "Sandbox failed in phase '$($guestState.phase)': $($guestState.detail)"
        }

        if ($SandboxId -notin $runningIds) {
            throw "Sandbox session $SandboxId exited before a terminal guest state was written"
        }

        if ($guestExecJobResult -and -not $guestState) {
            $loggedOutput = Get-FileText -Path $outputPath
            $details = if ($loggedOutput) {
                $loggedOutput
            } elseif ($guestExecJobResult.Output) {
                $guestExecJobResult.Output
            } else {
                "(no output)"
            }

            throw "Guest command exited before any guest state was written. wsb exec exit code $($guestExecJobResult.ExitCode). Output: $details"
        }

        Start-Sleep -Seconds 2
    }

    $guestState = Read-JsonFile -Path $guestStatePath
    $lastPhase = if ($guestState) { $guestState.phase } elseif (Test-Path $bootstrapProbePath -PathType Leaf) { "bootstrap_command_reached" } else { "no_guest_signal" }
    throw "Timed out waiting for sandbox terminal state in mode '$Mode' (last observed phase: $lastPhase)"
}

$sandboxRoot = $PSScriptRoot
$testRoot = Split-Path -Parent $sandboxRoot
$repoRoot = (Resolve-Path (Join-Path $testRoot "..")).Path
$assetsDir = Join-Path $sandboxRoot "assets"
$logsDir = Join-Path $sandboxRoot "logs"
$generatedDir = Join-Path $sandboxRoot "generated"
$templatePath = Join-Path $sandboxRoot "sandbox.wsb.tmpl"
$generatedConfigPath = Join-Path $generatedDir "windows-sandbox.wsb"

foreach ($path in @($assetsDir, $logsDir, $generatedDir)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
}

foreach ($path in @(
    $PSCommandPath,
    (Join-Path $assetsDir "sandbox-bootstrap.ps1"),
    (Join-Path $assetsDir "run-harness.ps1"),
    (Join-Path $sandboxRoot "prepare-runtime.ps1")
)) {
    Test-PowerShellSyntax -Path $path
}

if (-not (Test-Path $templatePath -PathType Leaf)) {
    throw "Missing Windows Sandbox template: $templatePath"
}

$null = Get-WsbBinary
$arch = Resolve-Architecture
$zip = Resolve-PowerShellZip -AssetsDir $assetsDir -Arch $arch
$template = Get-Content -Path $templatePath -Raw
$configText = $template.
    Replace("__REPO_ROOT__", (Escape-XmlValue -Value $repoRoot)).
    Replace("__ASSETS_DIR__", (Escape-XmlValue -Value $assetsDir)).
    Replace("__LOGS_DIR__", (Escape-XmlValue -Value $logsDir))

$configDocument = [xml]$configText
Set-Content -Path $generatedConfigPath -Value $configText -Encoding utf8NoBOM
$configArgument = $configDocument.OuterXml

Write-Stage "Resolved runtime ZIP: $($zip.Name)"
Write-Stage "Generated Windows Sandbox config: $generatedConfigPath"

if ($ValidateOnly) {
    Write-Stage "Static validation completed"
    exit 0
}

Get-ChildItem -Path $logsDir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
$runId = [guid]::NewGuid().Guid
$effectiveTimeoutSeconds = if ($TimeoutSeconds -gt 0) { $TimeoutSeconds } elseif ($Mode -eq "Full") { 900 } else { 300 }
$existingSessionIds = @(Get-RunningSandboxIds)

if ($NoWait) {
    throw "-NoWait is not supported by the current wsb CLI driver. Keep the waited mode until detached guest execution is redesigned."
}

if ($StopExisting) {
    if ($existingSessionIds.Count -gt 0) {
        Write-Stage "Stopping existing Windows Sandbox session(s): $($existingSessionIds -join ', ')"
        Stop-SandboxSessions -SessionIds $existingSessionIds
        Write-HostState -LogsDir $logsDir -State @{
            run_id = $runId
            mode = $Mode
            phase = "stop_existing_complete"
            detail = "stopped existing Windows Sandbox session(s): $($existingSessionIds -join ', ')"
            sandbox_id = $null
            active_session_ids = @(Get-RunningSandboxIds)
            terminal = $true
            success = $true
            updated_at = (Get-Date).ToString("o")
        }
    } else {
        Write-Stage "No active Windows Sandbox sessions to stop"
        Write-HostState -LogsDir $logsDir -State @{
            run_id = $runId
            mode = $Mode
            phase = "stop_existing_noop"
            detail = "no active Windows Sandbox sessions were running"
            sandbox_id = $null
            active_session_ids = @()
            terminal = $true
            success = $true
            updated_at = (Get-Date).ToString("o")
        }
    }

    exit 0
}

if ($existingSessionIds.Count -gt 0) {
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "launch_blocked_existing_session"
        detail = "an active Windows Sandbox session already exists; close it before launching a new disposable run"
        sandbox_id = $null
        active_session_ids = $existingSessionIds
        terminal = $true
        success = $false
        updated_at = (Get-Date).ToString("o")
    }

    throw "Active Windows Sandbox session detected ($($existingSessionIds -join ', ')). This harness supports only one Sandbox instance at a time."
}

$sandboxId = $null
$guestExecJob = $null
$finalSuccess = $false
$finalDetail = $null
$finalGuestPhase = $null

try {
    Write-Stage "Logs directory: $logsDir"
    Write-Stage "Launching Windows Sandbox in $Mode mode via wsb CLI"
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "launching"
        detail = "starting Windows Sandbox session via wsb start"
        sandbox_id = $null
        active_session_ids = @()
        terminal = $false
        success = $false
        updated_at = (Get-Date).ToString("o")
    }

    Invoke-Wsb -Arguments @("start", "--config", $configArgument) | Out-Null
    $sandboxId = Wait-ForSandboxId -BaselineSessionIds $existingSessionIds -LogsDir $logsDir -RunId $runId -Mode $Mode
    Write-Stage "Sandbox session id: $sandboxId"
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "sandbox_started"
        detail = "Windows Sandbox session started successfully"
        sandbox_id = $sandboxId
        active_session_ids = @(Get-RunningSandboxIds)
        terminal = $false
        success = $false
        updated_at = (Get-Date).ToString("o")
    }

    Wait-ForExecProbe -SandboxId $sandboxId -RunAs "System" -ProbePath (Join-Path $logsDir "system-exec-probe.txt") -ProbeCommand "cmd.exe /c echo system-exec-ready > C:\logs\system-exec-probe.txt" -WaitingPhase "waiting_for_system_exec" -ReadyPhase "system_exec_ready" -WaitingDetail "waiting for System guest command execution to become available." -ReadyDetail "System guest command execution is available." -LogsDir $logsDir -RunId $runId -Mode $Mode -TimeoutSeconds ([Math]::Min(120, $effectiveTimeoutSeconds))

    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "connecting_user_session"
        detail = "starting a Windows Sandbox remote session so ExistingLogin commands have a live user context"
        sandbox_id = $sandboxId
        active_session_ids = @(Get-RunningSandboxIds)
        terminal = $false
        success = $false
        updated_at = (Get-Date).ToString("o")
    }
    Write-Stage "Connecting to sandbox user session"
    Start-SandboxConnection -SandboxId $sandboxId

    Wait-ForExecProbe -SandboxId $sandboxId -RunAs "ExistingLogin" -ProbePath (Join-Path $logsDir "existing-login-probe.txt") -ProbeCommand "cmd.exe /c echo existing-login-ready > C:\logs\existing-login-probe.txt" -WaitingPhase "waiting_for_existing_login" -ReadyPhase "existing_login_ready" -WaitingDetail "waiting for an active sandbox user session." -ReadyDetail "ExistingLogin guest command execution is available." -LogsDir $logsDir -RunId $runId -Mode $Mode -TimeoutSeconds ([Math]::Min(180, $effectiveTimeoutSeconds))

    $guestCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\harness\sandbox-bootstrap.ps1 -Mode $Mode"
    $guestExecJob = Start-GuestExecJob -SandboxId $sandboxId -RunAs "ExistingLogin" -Command $guestCommand -LogsDir $logsDir
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "guest_command_submitted"
        detail = "submitted sandbox-bootstrap.ps1 via wsb exec under ExistingLogin"
        sandbox_id = $sandboxId
        active_session_ids = @(Get-RunningSandboxIds)
        guest_exec_job_id = $guestExecJob.Id
        terminal = $false
        success = $false
        updated_at = (Get-Date).ToString("o")
    }

    $result = Wait-ForGuestTerminalState -SandboxId $sandboxId -GuestExecJob $guestExecJob -LogsDir $logsDir -RunId $runId -Mode $Mode -TimeoutSeconds $effectiveTimeoutSeconds
    $finalSuccess = $true
    $finalGuestPhase = $result.guest_state.phase
    $finalDetail = "sandbox guest reported terminal success in phase '$finalGuestPhase'"
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "terminal_success"
        detail = $finalDetail
        sandbox_id = $sandboxId
        active_session_ids = @($result.active_session_ids)
        guest_phase = $finalGuestPhase
        guest_exec_exit_code = $result.guest_exec_exit_code
        terminal = $true
        success = $true
        updated_at = (Get-Date).ToString("o")
    }
}
catch {
    $finalSuccess = $false
    $finalDetail = $_.Exception.Message
    Write-HostState -LogsDir $logsDir -State @{
        run_id = $runId
        mode = $Mode
        phase = "terminal_failure"
        detail = $finalDetail
        sandbox_id = $sandboxId
        active_session_ids = @(Get-RunningSandboxIds)
        guest_exec_exit_code = if ($guestExecJob -and $guestExecJob.State -in @("Completed", "Failed", "Stopped")) { (Get-GuestExecJobResult -GuestExecJob $guestExecJob).ExitCode } else { $null }
        terminal = $true
        success = $false
        updated_at = (Get-Date).ToString("o")
    }
    throw
}
finally {
    if (-not $KeepOpen) {
        $activeSessionIds = @(Get-RunningSandboxIds)
        if ($sandboxId -and $sandboxId -in $activeSessionIds) {
            Write-HostState -LogsDir $logsDir -State @{
                run_id = $runId
                mode = $Mode
                phase = "closing_sandbox_session"
                detail = "closing disposable Windows Sandbox session after terminal state"
                sandbox_id = $sandboxId
                active_session_ids = $activeSessionIds
                terminal = $false
                success = $false
                updated_at = (Get-Date).ToString("o")
            }
            Stop-SandboxSessions -SessionIds @($sandboxId)
            $remainingSessionIds = @(Wait-ForSessionsToStop -SessionIds @($sandboxId))
            Write-Stage "Closed Windows Sandbox session $sandboxId"
        } else {
            $remainingSessionIds = @()
        }

        Write-HostState -LogsDir $logsDir -State @{
            run_id = $runId
            mode = $Mode
            phase = "session_closed_after_terminal"
            detail = if ($finalDetail) { "closed disposable Windows Sandbox session after terminal state: $finalDetail" } else { "closed disposable Windows Sandbox session after terminal state" }
            sandbox_id = $sandboxId
            active_session_ids = if ($null -ne $remainingSessionIds) { $remainingSessionIds } else { @(Get-RunningSandboxIds) }
            guest_phase = $finalGuestPhase
            guest_exec_exit_code = if ($guestExecJob -and $guestExecJob.State -in @("Completed", "Failed", "Stopped")) { (Get-GuestExecJobResult -GuestExecJob $guestExecJob).ExitCode } else { $null }
            terminal = $true
            success = $finalSuccess
            updated_at = (Get-Date).ToString("o")
        }
    }
}
