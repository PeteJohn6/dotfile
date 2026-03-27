#Requires -Version 7

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoMount,
    [Parameter(Mandatory = $true)][string]$LogsDir,
    [Parameter(Mandatory = $true)][string]$Workspace
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Stage {
    param([string]$Message)
    Write-Host "[sandbox-run] $Message" -ForegroundColor Cyan
}

function Invoke-Robocopy {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination,
        [Parameter(Mandatory = $true)][string]$LogPath
    )

    $dirExcludes = @(
        Join-Path $Source ".git"
        Join-Path $Source ".tree"
        Join-Path $Source "bin"
        Join-Path $Source ".vscode"
        Join-Path $Source ".idea"
        Join-Path $Source "test\windows-sandbox\logs"
        Join-Path $Source "test\windows-sandbox\generated"
    )

    $fileExcludes = @(
        Join-Path $Source ".dotter\local.toml"
        Join-Path $Source ".dotter\cache.toml"
        Join-Path $Source ".DS_Store"
        Join-Path $Source "Thumbs.db"
        Join-Path $Source "desktop.ini"
        Join-Path $Source "packages\nvim\lazy-lock.json"
    )

    $args = @(
        $Source
        $Destination
        "/MIR"
        "/R:2"
        "/W:1"
        "/NFL"
        "/NDL"
        "/NP"
        "/TEE"
        "/LOG:$LogPath"
        "/XD"
    ) + $dirExcludes + @("/XF") + $fileExcludes

    & robocopy @args
    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        throw "robocopy failed with exit code $exitCode"
    }
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogsDir
    )

    $logPath = Join-Path $LogsDir "$Name.log"
    Write-Stage "Running $Name"
    Push-Location $WorkingDirectory
    try {
        $output = & $FilePath @ArgumentList 2>&1
        $exitCode = if ($null -ne $LASTEXITCODE) { $LASTEXITCODE } else { 0 }
        if ($null -ne $output) {
            $null = $output | Tee-Object -FilePath $logPath
        } else {
            Set-Content -Path $logPath -Value "" -Encoding utf8NoBOM
        }
    }
    finally {
        Pop-Location
    }

    return $exitCode
}

function Resolve-JustExecutable {
    $command = Get-Command just -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $scoopShim = Join-Path $HOME "scoop\shims\just.exe"
    if (Test-Path $scoopShim -PathType Leaf) {
        $env:PATH = "$(Split-Path $scoopShim -Parent);$env:PATH"
        return $scoopShim
    }

    throw "Unable to locate just.exe after bootstrap"
}

function Write-StatusFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Data
    )

    $Data | ConvertTo-Json -Depth 5 | Set-Content -Path $Path -Encoding utf8NoBOM
}

New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null
$transcriptPath = Join-Path $LogsDir "transcript.txt"
$sandboxStatePath = Join-Path $LogsDir "sandbox-state.json"
$statusPath = Join-Path $LogsDir "status.json"
$summaryPath = Join-Path $LogsDir "summary.txt"

function Write-SandboxState {
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
        source = "stage1"
        terminal = $Terminal
        success = $Success
        exit_code = $ExitCode
        updated_at = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 3 | Set-Content -Path $sandboxStatePath -Encoding utf8NoBOM
}

$status = [ordered]@{
    succeeded = $false
    repo_mount = $RepoMount
    workspace = $Workspace
    bootstrap_exit_code = $null
    just_up_exit_code = $null
    failed_step = $null
    timestamp = (Get-Date).ToString("o")
}

Start-Transcript -Path $transcriptPath -Force | Out-Null

try {
    Write-SandboxState -Phase "stage1_started" -Detail "run-harness.ps1 started"

    if (-not (Test-Path $RepoMount -PathType Container)) {
        Write-SandboxState -Phase "repo_mount_missing" -Detail "repo mount is missing: $RepoMount" -Terminal $true -ExitCode 30
        throw "Missing repo mount: $RepoMount"
    }

    if (Test-Path $Workspace) {
        Remove-Item -Path $Workspace -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $Workspace | Out-Null
    Write-SandboxState -Phase "repo_copying" -Detail "copying repository into sandbox workspace"
    Write-Stage "Copying repository into sandbox workspace"
    Invoke-Robocopy -Source $RepoMount -Destination $Workspace -LogPath (Join-Path $LogsDir "workspace-copy.log")

    $bootstrapPath = Join-Path $Workspace "bootstrap\bootstrap.ps1"
    $currentPwsh = Join-Path $PSHOME "pwsh.exe"
    Write-SandboxState -Phase "bootstrap_running" -Detail "running bootstrap/bootstrap.ps1"
    $status.bootstrap_exit_code = Invoke-LoggedCommand -Name "bootstrap" -FilePath $currentPwsh -ArgumentList @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $bootstrapPath) -WorkingDirectory $Workspace -LogsDir $LogsDir
    if ($status.bootstrap_exit_code -ne 0) {
        $status.failed_step = "bootstrap"
        Write-SandboxState -Phase "bootstrap_failed" -Detail "bootstrap/bootstrap.ps1 exited with code $($status.bootstrap_exit_code)" -Terminal $true -ExitCode $status.bootstrap_exit_code
        throw "bootstrap failed with exit code $($status.bootstrap_exit_code)"
    }

    $justExe = Resolve-JustExecutable
    Write-SandboxState -Phase "just_up_running" -Detail "running just up"
    $status.just_up_exit_code = Invoke-LoggedCommand -Name "just-up" -FilePath $justExe -ArgumentList @("up") -WorkingDirectory $Workspace -LogsDir $LogsDir
    if ($status.just_up_exit_code -ne 0) {
        $status.failed_step = "just-up"
        Write-SandboxState -Phase "just_up_failed" -Detail "just up exited with code $($status.just_up_exit_code)" -Terminal $true -ExitCode $status.just_up_exit_code
        throw "just up failed with exit code $($status.just_up_exit_code)"
    }

    $status.succeeded = $true
    Write-SandboxState -Phase "full_success" -Detail "bootstrap and just up completed successfully" -Terminal $true -Success $true
    "SUCCESS: bootstrap and just up completed" | Set-Content -Path $summaryPath -Encoding utf8NoBOM
    Write-Stage "Sandbox test run completed successfully"
}
catch {
    if (-not $status.failed_step) {
        $status.failed_step = "setup"
    }

    if (-not (Test-Path $sandboxStatePath -PathType Leaf) -or -not ((Get-Content -Path $sandboxStatePath -Raw | ConvertFrom-Json).terminal)) {
        Write-SandboxState -Phase "stage1_failed" -Detail $_.Exception.Message -Terminal $true -ExitCode 1
    }
    "FAILED: $($_.Exception.Message)" | Set-Content -Path $summaryPath -Encoding utf8NoBOM
    Write-Error $_
}
finally {
    Write-StatusFile -Path $statusPath -Data $status
    Stop-Transcript | Out-Null
    Write-Host ""
    Write-Host "Logs written to: $LogsDir" -ForegroundColor Yellow
    Write-Host "Summary file: $summaryPath" -ForegroundColor Yellow
}
