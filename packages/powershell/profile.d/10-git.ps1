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
function gitco { git checkout @args }
function gitcm { git commit @args }
function gitp { git push @args }
function gitpl { git pull @args }
function gitwt { git worktree @args }

# Git worktree interactive selector (switch between worktrees)
function gitwts {
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

  function Get-RelativePath([string]$BasePath, [string]$TargetPath) {
    try {
      $base = (Resolve-Path -LiteralPath $BasePath).Path
      $target = (Resolve-Path -LiteralPath $TargetPath).Path
      $baseUri = [Uri]((Join-Path $base '.') + [IO.Path]::DirectorySeparatorChar)
      $targetUri = [Uri]$target
      $rel = $baseUri.MakeRelativeUri($targetUri).ToString()
      return [Uri]::UnescapeDataString($rel).Replace('/', [IO.Path]::DirectorySeparatorChar)
    } catch {
      return $TargetPath
    }
  }

  $pwdPath = (Get-Location).Path

  # Build lines as: branch<TAB>relative-path<TAB>absolute-path
  # (Keep absolute path as a hidden 3rd field for preview/cd.)
  $items = git worktree list --porcelain |
    ForEach-Object {
      if ($_ -match '^worktree\s+(.*)$') { $script:wt = $Matches[1]; return }
      if ($_ -match '^branch\s+(.*)$') {
        $b = $Matches[1] -replace '^refs/heads/',''
        $rel = Get-RelativePath $pwdPath $script:wt
        "$b`t$rel`t$script:wt"
        $script:wt = $null
        return
      }
      if ($_ -match '^detached$') {
        $b = '(detached)'
        $rel = Get-RelativePath $pwdPath $script:wt
        "$b`t$rel`t$script:wt"
        $script:wt = $null
        return
      }
    }

  if (-not $items) {
    Write-Host "gitwts: no worktrees found" -ForegroundColor Yellow
    return
  }

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
      --preview="git -C {3} --no-pager status -sb 2> NUL & echo. & git -C {3} --no-pager log -n 30 --oneline --decorate --graph"

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
