# =============================================================================
# PowerShell Profile - Git Module
# =============================================================================
# Git shortcuts and utilities

# Guard: Return if git is not available
if (-not (Test-Command git)) {
    Write-Host "[profile.d/10-git.ps1] Skipping: 'git' command not found in PATH" -ForegroundColor Yellow
    return
}

# Lightweight git-prefixed helpers (avoid clobbering PowerShell default aliases like gl/gp/gcm)
function gits { git status @args }
function gitl { git log --oneline --decorate --graph @args }
function gitcm { git commit @args }
function gitp { git push @args }
function gitpl { git pull @args }
function gitwt { git worktree @args }

function Get-GitRelativePath {
    param(
        [Parameter(Mandatory)][string]$BasePath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    try {
        $base = [IO.Path]::GetFullPath($BasePath)
        $target = [IO.Path]::GetFullPath($TargetPath)
        $baseUri = [Uri]((Join-Path $base '.') + [IO.Path]::DirectorySeparatorChar)
        $targetUri = [Uri]$target
        $rel = $baseUri.MakeRelativeUri($targetUri).ToString()
        return [Uri]::UnescapeDataString($rel).Replace('/', [IO.Path]::DirectorySeparatorChar)
    } catch {
        return $TargetPath
    }
}

function Get-NormalizedPath {
    param([Parameter(Mandatory)][string]$Path)

    try {
        return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    } catch {
        return $Path.TrimEnd('\', '/')
    }
}

function Get-GitMainRoot {
    $commonDir = git rev-parse --path-format=absolute --git-common-dir 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }

    return Get-NormalizedPath (Split-Path -Parent (($commonDir | Select-Object -First 1).Trim()))
}

function Get-GitBranchItems {
    git for-each-ref `
        --sort=-committerdate `
        --format="%(refname:short)`t%(HEAD)`t%(upstream:short)`t%(committerdate:relative)`t%(subject)" `
        refs/heads
}

function Get-GitWorktreeItems {
    $currentRoot = git rev-parse --path-format=absolute --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    $currentRoot = Get-NormalizedPath (($currentRoot | Select-Object -First 1).Trim())

    $mainRoot = Get-GitMainRoot
    if (-not $mainRoot) { return @() }

    $pwdPath = (Get-Location).Path
    $items = @()
    $worktreePath = $null

    foreach ($line in (git worktree list --porcelain)) {
        if ($line -match '^worktree\s+(.*)$') {
            $worktreePath = Get-NormalizedPath $Matches[1]
            continue
        }

        if ($line -match '^branch\s+(.*)$' -and $worktreePath) {
            $branch = $Matches[1] -replace '^refs/heads/', ''
            $items += [PSCustomObject]@{
                Branch = $branch
                RelativePath = Get-GitRelativePath $pwdPath $worktreePath
                Path = $worktreePath
                Exists = Test-Path -LiteralPath $worktreePath -PathType Container
                IsMain = $worktreePath -ieq $mainRoot
                IsCurrent = $worktreePath -ieq $currentRoot
            }
            $worktreePath = $null
            continue
        }

        if ($line -match '^detached$' -and $worktreePath) {
            $items += [PSCustomObject]@{
                Branch = '(detached)'
                RelativePath = Get-GitRelativePath $pwdPath $worktreePath
                Path = $worktreePath
                Exists = Test-Path -LiteralPath $worktreePath -PathType Container
                IsMain = $worktreePath -ieq $mainRoot
                IsCurrent = $worktreePath -ieq $currentRoot
            }
            $worktreePath = $null
        }
    }

    return $items
}

function gitwtc {
<#
.SYNOPSIS
Create a Git worktree under the main repository's .tree directory.

.DESCRIPTION
Creates a new worktree at <main-repo>/.tree/<branch> even when invoked from a
linked worktree. Existing local branches are attached directly; missing local
branches are created with `git worktree add -b`. On success, changes the
current location to the new worktree path.

.EXAMPLE
gitwtc feature/example

.EXAMPLE
gitwtc bugfix/login
#>
  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "gitwtc: not inside a Git repository" -ForegroundColor Yellow
    return
  }

  if ($args.Count -ne 1) {
    Write-Host "gitwtc: usage: gitwtc <branch>" -ForegroundColor Yellow
    return
  }

  $branch = [string]$args[0]

  git check-ref-format --branch $branch *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "gitwtc: invalid branch name: $branch" -ForegroundColor Red
    return
  }

  $mainRoot = Get-GitMainRoot
  if (-not $mainRoot) {
    Write-Host "gitwtc: failed to resolve main repository root" -ForegroundColor Red
    return
  }

  $treeRoot = Join-Path $mainRoot '.tree'
  $targetPath = Get-NormalizedPath (Join-Path $treeRoot (($branch -split '/') -join [IO.Path]::DirectorySeparatorChar))
  if (Test-Path -LiteralPath $targetPath) {
    Write-Host "gitwtc: target path already exists: $targetPath" -ForegroundColor Red
    return
  }

  $targetParent = Split-Path -Parent $targetPath
  if ($targetParent) {
    try {
      New-Item -ItemType Directory -Path $targetParent -Force -ErrorAction Stop *> $null
    } catch {
      Write-Host "gitwtc: failed to create parent directory: $targetParent" -ForegroundColor Red
      return
    }
  }

  git show-ref --verify --quiet "refs/heads/$branch" *> $null
  $branchExists = ($LASTEXITCODE -eq 0)

  if ($branchExists) {
    git worktree add -- $targetPath $branch
  } else {
    git worktree add -b $branch -- $targetPath
  }
  if ($LASTEXITCODE -ne 0) { return }

  Set-Location -LiteralPath $targetPath
  Write-Host ("gitwtc -> " + (Get-Location).Path) -ForegroundColor Green
}

function gitco {
<#
.SYNOPSIS
Check out a Git branch directly or through an interactive selector.

.DESCRIPTION
When called with arguments, passes them through to `git checkout` unchanged.
When called without arguments, requires fzf, lists local branches ordered by
recent commit activity, previews branch history, and checks out the selected
branch.

.EXAMPLE
gitco

.EXAMPLE
gitco feature/example
#>
  if ($args.Count -gt 0) {
    git checkout @args
    return
  }

  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "gitco: not inside a Git repository" -ForegroundColor Yellow
    return
  }

  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "gitco: fzf not found in PATH" -ForegroundColor Red
    return
  }

  $preview = 'git --no-pager branch -vv --list "{1}" 2> NUL & echo. & git --no-pager log -n 30 --oneline --decorate --graph "{1}" 2> NUL'
  $items = @(Get-GitBranchItems)
  if (-not $items) {
    Write-Host "gitco: no branches found" -ForegroundColor Yellow
    return
  }

  $selected = $items |
    fzf `
      --height=40% `
      --layout=reverse `
      --border `
      --prompt='branch> ' `
      --delimiter="`t" `
      --with-nth=2,1,3,4,5 `
      --header='CURRENT  |  BRANCH  |  UPSTREAM  |  AGE  |  SUBJECT' `
      --preview-window='right,60%,wrap' `
      --preview=$preview

  if (-not $selected) {
    Write-Host "gitco: cancelled" -ForegroundColor DarkGray
    return
  }

  $branch = ($selected -split "`t")[0]
  if (-not $branch) {
    Write-Host "gitco: invalid branch selection" -ForegroundColor Red
    return
  }

  git checkout $branch
}

# Git worktree interactive selector (switch between worktrees)
function gitwts {
<#
.SYNOPSIS
Interactively switch to another Git worktree.

.DESCRIPTION
Lists Git worktrees in fzf, previews status and recent history for the selected
entry, and changes the current location to the selected worktree path.

.EXAMPLE
gitwts
#>
  # Must be inside a git repo
  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "gitwts: not inside a Git repository" -ForegroundColor Yellow
    return
  }

  # Ensure fzf exists
  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "gitwts: fzf not found in PATH" -ForegroundColor Red
    return
  }

  $items = Get-GitWorktreeItems |
    ForEach-Object { "$($_.Branch)`t$($_.RelativePath)`t$($_.Path)" }

  if (-not $items) {
    Write-Host "gitwts: no worktrees found" -ForegroundColor Yellow
    return
  }

  $preview = 'if exist "{3}\NUL" (git -C "{3}" --no-pager status -sb 2> NUL & echo. & git -C "{3}" --no-pager log -n 30 --oneline --decorate --graph) else (echo worktree path missing: {3})'

  # Use a non-fullscreen "dropdown" style list and a preview pane.
  # Preview shows a short decorated graph log (and a 1-line status header).
  $selected = $items |
    fzf `
      --height=40% `
      --layout=reverse `
      --border `
      --prompt='worktree> ' `
      --delimiter="`t" `
      --with-nth=1,2 `
      --header='BRANCH  |  PATH' `
      --preview-window='right,60%,wrap' `
      --preview=$preview

  if (-not $selected) {
    Write-Host "gitwts: cancelled" -ForegroundColor DarkGray
    return
  }

  $path = ($selected -split "`t")[2]
  if (-not (Test-Path -LiteralPath $path)) {
    Write-Host "gitwts: path does not exist: $path" -ForegroundColor Red
    return
  }

  Set-Location -LiteralPath $path
  Write-Host ("gitwts -> " + (Get-Location).Path) -ForegroundColor Green
}

function gitwtr {
<#
.SYNOPSIS
Interactively remove a Git linked worktree.

.DESCRIPTION
Lists removable Git worktrees in fzf, excludes the main worktree and the current
worktree, prompts for confirmation, and runs `git worktree remove` on the
selected path without forcing dirty or locked worktrees.

.EXAMPLE
gitwtr
#>
  git rev-parse --is-inside-work-tree *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "gitwtr: not inside a Git repository" -ForegroundColor Yellow
    return
  }

  if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    Write-Host "gitwtr: fzf not found in PATH" -ForegroundColor Red
    return
  }

  $items = Get-GitWorktreeItems |
    Where-Object { -not $_.IsMain -and -not $_.IsCurrent } |
    ForEach-Object { "$($_.Branch)`t$($_.RelativePath)`t$($_.Path)`t$($_.Exists)" }

  if (-not $items) {
    Write-Host "gitwtr: no removable worktrees found" -ForegroundColor Yellow
    return
  }

  $preview = 'if exist "{3}\NUL" (git -C "{3}" --no-pager status -sb 2> NUL & echo. & git -C "{3}" --no-pager log -n 30 --oneline --decorate --graph) else (echo worktree path missing: {3})'
  $selected = $items |
    fzf `
      --height=40% `
      --layout=reverse `
      --border `
      --prompt='remove-worktree> ' `
      --delimiter="`t" `
      --with-nth=1,2 `
      --header='BRANCH  |  PATH' `
      --preview-window='right,60%,wrap' `
      --preview=$preview

  if (-not $selected) {
    Write-Host "gitwtr: cancelled" -ForegroundColor DarkGray
    return
  }

  $parts = $selected -split "`t"
  $path = $parts[2]
  $relPath = $parts[1]
  if (-not $path) {
    Write-Host "gitwtr: invalid worktree selection" -ForegroundColor Red
    return
  }

  $confirm = Read-Host "Remove worktree $relPath? [y/N]"
  if ($confirm -notmatch '^(?i:y|yes)$') {
    Write-Host "gitwtr: cancelled" -ForegroundColor DarkGray
    return
  }

  git worktree remove -- $path
  if ($LASTEXITCODE -ne 0) { return }

  Write-Host "gitwtr: removed $path" -ForegroundColor Green
}
