# =============================================================================
# PowerShell Profile - Docker Module
# =============================================================================
# Docker utilities and interactive container management with fzf

# Guard: Return if docker is not available
if (-not (Test-Command docker)) {
    Write-Host "[profile.d/20-docker.ps1] Skipping: 'docker' command not found in PATH" -ForegroundColor Yellow
    return
}

# === fzf-powered interactive functions ===
# Naming convention: dockerf* => fzf-powered

# 1. Enter an interactive shell in a running container
function dockerfshell
{
    <#
    .SYNOPSIS
        Select a running Docker container via fzf and open a shell (PowerShell or bash)
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerfshell: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sel = docker ps --format "{{.ID}}\t{{.Names}}\t{{.Image}}" |
        fzf `
            --height=40% `
            --layout=reverse `
            --border `
            --prompt='container> ' `
            --delimiter="`t" `
            --with-nth=1,2,3 `
            --header="Select a running container (ID | NAME | IMAGE)" `
            --preview-window='right,60%,wrap' `
            --preview "docker logs {1} --tail 50" `
            --ansi

    if (-not $sel) { return }
    $id = ($sel -split "`t")[0]

    # Try PowerShell first; if unavailable, fall back to bash
    docker exec $id pwsh -c 'exit' 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        docker exec -it $id pwsh
    } else {
        docker exec -it $id bash
    }
}

# 2. View logs of one or more containers (including stopped ones)
function dockerflogs
{
    <#
    .SYNOPSIS
        Select one or more containers and display their logs
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerflogs: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sels = docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" |
        fzf --header="Select container(s) to show logs" --multi --bind "enter:accept" --ansi

    if (-not $sels) { return }
    $ids = $sels -split "`n" | ForEach-Object { ($_ -split "`t")[0] }
    foreach ($id in $ids)
    {
        Write-Host "`n=== Logs for $id ===" -ForegroundColor Cyan
        docker logs $id --tail 100
    }
}

# 3. Remove one or more images (docker image rm, fzf)
function dockerfrmi
{
    <#
    .SYNOPSIS
        Select one or more Docker images and remove them
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerfrmi: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sels = docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" |
        fzf --header="Select image(s) to remove (docker image rm)" --multi --ansi

    if (-not $sels) { return }
    $ids = $sels -split "`n" | ForEach-Object { ($_ -split "`t")[1] }
    docker image rm $ids
}

# 4. Remove one or more containers (forced, fzf)
function dockerfrm
{
    <#
    .SYNOPSIS
        Select one or more containers and remove them (forced)
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerfrm: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sels = docker container ls -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" |
        fzf --header="Select container(s) to remove (forced)" --multi --ansi

    if (-not $sels) { return }
    $ids = $sels -split "`n" | ForEach-Object { ($_ -split "`t")[0] }
    docker container rm -f $ids
}

# 5. Run a new interactive container from a local image (fzf)
function dockerfrun
{
    <#
    .SYNOPSIS
        Select a local image via fzf and start an interactive container
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerfrun: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sel = docker image ls --format "{{.Repository}}:{{.Tag}}\t{{.ID}}" |
        fzf --header="Select image to run" --ansi

    if (-not $sel) { return }
    $repoTag = ($sel -split "`t")[0]
    docker run -it --rm $repoTag bash
}

# 6. Execute an arbitrary command in a running container (fzf)
function dockerfexec
{
    <#
    .SYNOPSIS
        Select a running Docker container via fzf and execute any command inside it
    #>
    if (-not (Test-Command fzf)) {
        Write-Host "dockerfexec: fzf not found in PATH" -ForegroundColor Red
        return
    }

    $sel = docker ps --format "{{.ID}}\t{{.Names}}\t{{.Image}}" |
        fzf --header="Select a container to exec into" --ansi

    if (-not $sel) { return }
    $id = ($sel -split "`t")[0]

    # Prompt for the command to run
    $cmd = Read-Host "Enter the command to run inside container $id"
    if (-not $cmd) { return }

    # Run it interactively
    docker exec -it $id $cmd
}

# === Docker completion caching ===
# Generate and cache docker completion (30-day validity)
$compFile = Join-Path $script:ProfileCache 'docker_completion.ps1'

# Check if cache needs regeneration
$needRegen = -not (Test-Path $compFile)
if (-not $needRegen) {
    # Regenerate if cache is older than 30 days
    $ageDays = ((Get-Date) - (Get-Item $compFile).LastWriteTime).TotalDays
    if ($ageDays -gt 30) { $needRegen = $true }
}

if ($needRegen) {
    try {
        docker completion powershell | Set-Content -Encoding UTF8 $compFile
    } catch {
        # Silently fail - completion is optional
    }
}

# Load cached completion if available
if (Test-Path $compFile) { . $compFile }
