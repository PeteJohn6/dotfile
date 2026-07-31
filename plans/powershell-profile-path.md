# Deploy the Windows PowerShell profile to the path PowerShell actually loads

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document must be maintained in accordance with `PLANS.md` at the repository root.

## Trigger / Why This Needs an ExecPlan

This task changes the durable output of the Windows `stow` stage. A selected `powershell` package will be linked into a different user directory after this change, and `.dotter/cache.toml` will reconcile the old mapping to the new mapping on machines that have already deployed it. Repository policy therefore requires a checked-in ExecPlan before editing the mapping or its user-facing documentation.

No release tags exist in this repository as of 2026-07-31, so the OneDrive-specific mapping is not a released compatibility contract. The intended behavior is a direct replacement of that default, without a compatibility link or an automatic registry probe.

## Purpose / Big Picture

After this change, running `just stow` on a normal Windows PowerShell 7 installation deploys the repository profile to `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` and its ordered modules to `~/Documents/PowerShell/profile.d`. A newly opened PowerShell console can then load helpers such as `gits` and `gitwt` from the current-user, current-host profile that PowerShell reports through `$PROFILE.CurrentUserCurrentHost`.

The literal `~/Documents/PowerShell` target is the repository default, not a claim that every Windows machine stores Documents there. PowerShell profile locations vary by user and host, and Windows can redirect Documents through OneDrive or enterprise policy. Operators must inspect `$PROFILE.CurrentUserCurrentHost`; when it differs, they can override both repository source keys under `[files]` in the ignored machine-local `.dotter/local.toml`.

## Progress

- [x] (2026-07-31 07:07Z) Read `PLANS.md`, `docs/maintainer-workflow.md`, the container validation skill, the current Dotter configuration, package conventions, PowerShell guide, deployment guide, README, and machine-local Dotter state.
- [x] (2026-07-31 07:07Z) Confirmed PowerShell 7.6.3 reports `C:\Users\night\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`, Windows reports `C:\Users\night\Documents`, the cache still names OneDrive targets, and the repository has no release tags.
- [x] (2026-07-31 07:07Z) Created this ExecPlan before changing tracked deployment behavior.
- [x] (2026-07-31 07:09Z) Changed only the two PowerShell targets in `.dotter/windows.toml` from `~/OneDrive/Documents/PowerShell` to `~/Documents/PowerShell`.
- [x] (2026-07-31 07:09Z) Updated `README.md`, `docs/packages/powershell.md`, and `docs/dotter-and-just.md` with the default, the `$PROFILE.CurrentUserCurrentHost` lookup, and the two-key `.dotter/local.toml` override.
- [x] (2026-07-31 07:11Z) Ran `git diff --check` successfully and proved the merged TOML parses with `just dry`; reran the preview outside the sandbox so `~` resolved to `C:\Users\night`.
- [ ] Obtain a host preview limited to the PowerShell migration (blocked: real-user `just dry` also proposes `packages/git/.gitconfig` and reports that `C:\Users\night\.gitconfig` is an existing ordinary file).
- [ ] Run ordinary `just stow` in the real Windows user context, then verify the profile and module links, exported functions in a fresh TTY session, and the existing package diagnostic (not started because the preview stop condition was met).
- [x] (2026-07-31 07:15Z) Validated bootstrap and `just install && just stow && just post` in disposable container `dotfile-agent-20260731071220`, confirmed a subsequent container `just dry` was empty, and removed only that container.
- [x] (2026-07-31 07:16Z) Recorded all completed validation evidence and performed the final task-scoped diff and whole-worktree review; the Neovim status exactly matches the initial status and remains outside this task's edits.
- [x] (2026-07-31 08:32Z) Prepared the mapping, documentation, and this ExecPlan as an isolated PowerShell-path commit at the user's direction; host deployment remains pending behind the recorded `.gitconfig` conflict.

## Surprises & Discoveries

- Observation: The tracked PowerShell source files exist, but neither the current Documents target nor the legacy OneDrive target exists before deployment.
  Evidence: PowerShell 7.6.3 reports the Documents target via `$PROFILE.CurrentUserCurrentHost`; `Test-Path` checks will be repeated before deployment and recorded below.

- Observation: The worktree already contains modified, deleted, and untracked Neovim files plus `nvim.log`.
  Evidence: The initial `git status --short --untracked-files=all` lists only those pre-existing paths. They are an explicit boundary for this task and must remain untouched.

- Observation: Sandboxed Windows commands expose `$HOME` as `C:\Users\night` inside `pwsh`, but Dotter's home-directory lookup resolves `~` to `C:\Users\CodexSandboxOnline`.
  Evidence: The sandboxed `just dry` proposed removing every cached `C:\Users\night` mapping and adding every selected package under `C:\Users\CodexSandboxOnline`. It was discarded as validation evidence and the command was rerun outside the sandbox.

- Observation: The real-user preview contains one unrelated target operation in addition to the intended PowerShell migration.
  Evidence: `just dry` proposes `packages/git/.gitconfig -> C:\Users\night\.gitconfig`, then reports that the target already exists and is not a symlink. `Get-Item` confirms a 940-byte ordinary archive file with no `LinkType`. The preview shows no Neovim operations, but the plan's any-unrelated-operation stop condition still applies.

- Observation: Neither dry-run mutated host deployment state.
  Evidence: The new profile and `profile.d` targets remain absent, and `.dotter/cache.toml` still has six PowerShell entries under OneDrive and zero under the new Documents default.

- Observation: The disposable Unix workflow completes under the install script's existing best-effort package semantics even when apt lacks two desktop-list packages.
  Evidence: `just install` reported 14 succeeded, 3 skipped, and 2 failed (`nvm` and `uv` were unavailable from apt), then returned success so `just stow` and `just post` ran. Dotter deployed the selected container packages, the Neovim and tmux post hooks completed, and a subsequent `just dry` reported no pending operations.

## Decision Log

- Decision: Keep the PowerShell package on the PowerShell 7 current-user, current-host model and change only its default target directory.
  Rationale: PowerShell reports this host's actual profile as `C:\Users\night\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`; the repository currently targets a nonexistent OneDrive directory, so startup cannot load the package. Windows PowerShell 5.1 and VS Code use different host paths and are outside this task.
  Date/Author: 2026-07-31 / Codex

- Decision: Document `$PROFILE.CurrentUserCurrentHost` as the authoritative machine check and use a local `[files]` override for redirected Documents folders.
  Rationale: PowerShell's automatic `$PROFILE` value varies by user and host, while Dotter merges machine-local `[files]` last and lets an operator replace a source key's target. This handles OneDrive and enterprise redirection without repository code that guesses from the registry.
  Date/Author: 2026-07-31 / Codex

- Decision: Let ordinary `just stow` reconcile `.dotter/cache.toml`; do not call `just uninstall`, `just stow-force`, or manually edit cache state.
  Rationale: The normal deployment path owns target migration and is idempotent. Force or undeploy would broaden the mutation surface and could disturb unrelated selected packages.
  Date/Author: 2026-07-31 / Codex

- Decision: Do not modify `justfile`, bootstrap scripts, package selection, PowerShell source content, or tests.
  Rationale: The defect is the Windows Dotter target and its documentation. The stable command surface and profile behavior do not need to change.
  Date/Author: 2026-07-31 / Codex

- Decision: Do not run host `just stow` after the real-user preview reported the unrelated `.gitconfig` addition/conflict.
  Rationale: The approved plan explicitly makes any unrelated target change a stop condition. Temporarily changing package selection or using force would evade that boundary and expand machine-local mutations without approval. Disposable container validation can continue because it cannot affect the host targets.
  Date/Author: 2026-07-31 / Codex

- Decision: Commit the repository change before completing the machine-local deployment proof.
  Rationale: The user explicitly requested a task-scoped commit. The mapping, documentation, static checks, merged-config preview, and disposable Unix workflow evidence are complete; the remaining `.gitconfig` conflict blocks only mutation of this host and stays visible as unfinished acceptance work in this plan.
  Date/Author: 2026-07-31 / Codex

## Outcomes & Retrospective

The tracked mapping and documentation implementation is complete, static validation passes, and the disposable Unix `bootstrap -> install -> stow -> post` workflow passed with the install script's documented best-effort warnings for unavailable `nvm` and `uv` apt packages. The task-scoped tracked diff is limited to `.dotter/windows.toml`, `README.md`, `docs/dotter-and-just.md`, `docs/packages/powershell.md`, and this plan. Host deployment and runtime proof remain pending because the real-user preview also proposes an unrelated `.gitconfig` mapping that conflicts with an existing ordinary file. No host target or cache state was changed, and the pre-existing Neovim worktree state is unchanged.

## Context and Orientation

The repository's maintained user workflow is `bootstrap -> install -> stow -> post`. This task affects only `stow`, the stage that asks Dotter to deploy repository-managed configuration into user locations.

`.dotter/global.toml` defines shared packages and default symbolic-link behavior. The ignored `.dotter/local.toml` selects packages for one machine and includes `.dotter/windows.toml` on Windows. `.dotter/windows.toml` supplies Windows-specific targets. Dotter stores deployed source-to-target mappings in the ignored `.dotter/cache.toml` and uses them to reconcile a later normal deployment. Neither machine-local file is repository source of truth.

The `powershell` mapping has two source keys. `packages/powershell/Microsoft.PowerShell_profile.ps1` is the entrypoint that PowerShell runs at startup. `packages/powershell/profile.d` is a directory whose scripts are loaded in lexical order by that entrypoint. The existing targets hard-code `~/OneDrive/Documents/PowerShell`, but on the current machine PowerShell 7.6.3 reports its current-user, current-host profile under `~/Documents/PowerShell`.

PowerShell's `$PROFILE` automatic variable names the current-user, current-host file for the running host, and `$PROFILE.CurrentUserCurrentHost` makes that scope explicit. On Windows, Documents can be redirected, so an operator whose reported path differs from the repository default must set these exact keys in `.dotter/local.toml` after the `packages` and optional `[variables]` configuration:

    [files]
    "packages/powershell/Microsoft.PowerShell_profile.ps1" = "D:/Redirected/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
    "packages/powershell/profile.d" = "D:/Redirected/Documents/PowerShell/profile.d"

The target values above are examples; the first must equal `$PROFILE.CurrentUserCurrentHost`, and the second must be its sibling `profile.d` directory. Dotter expands `~` to the current Windows user's home, but an absolute path is clearest for a redirected location.

The worktree has unrelated Neovim changes. The implementation may read their status to protect them, but it must not edit, remove, format, deploy beyond what the preview already considers unchanged, or include them in task-specific diffs.

## Plan of Work

First, edit `.dotter/windows.toml` in the `[powershell.files]` section so both targets begin with `~/Documents/PowerShell`. Keep the source keys and all other packages unchanged.

Then update the Windows configuration guidance in `README.md`, the lifecycle and troubleshooting details in `docs/packages/powershell.md`, and the machine-local merge/validation guidance in `docs/dotter-and-just.md`. Each document must say that `~/Documents/PowerShell` is the default, not a universal detected path; direct the reader to `$PROFILE.CurrentUserCurrentHost`; and show a `[files]` override for both source keys when Documents is redirected.

After the tracked edits, run static checks and preview the exact user-facing deployment command. Review `just dry` output before writing user targets. It is acceptable only if deployment changes are limited to removal of the old OneDrive PowerShell targets and creation of the new Documents PowerShell targets. Existing selected-package entries that Dotter reports as unchanged are not migration changes. Any add, remove, or replace operation involving Neovim or another unrelated target is a stop condition. The real-user preview reached this stop condition because it also proposed adding `packages/git/.gitconfig` over an existing ordinary file, so host deployment is paused.

Once the preview is safe, run ordinary `just stow` in the real `C:\Users\night` context. Do not use force or uninstall. Verify the cache and filesystem links, then open a fresh TTY-backed PowerShell process so profile minimal-mode guards do not suppress module loading. Confirm `gits` and `gitwt` resolve as functions, and run `packages/powershell/test/test-profile-commands.ps1` as the existing package diagnostic.

Finally, follow `.agents/skills/container-for-unix-work/SKILL.md`. Use image `dotfile-agent-test:local`, create a unique `dotfile-agent-<timestamp>` container with the host repository mounted read-only at `/repo-ro`, initialize `/workspace`, run the bootstrap, and run `just install && just stow && just post` in `/workspace`. Remove only the container created for this task. Record all results in this plan and review the final task-scoped diff and whole-worktree status.

## Concrete Steps

All host commands run from `C:\Users\night\dotfile` unless stated otherwise.

Apply the tracked changes, then run:

    git diff --check
    git diff -- .dotter/windows.toml README.md docs/packages/powershell.md docs/dotter-and-just.md plans/powershell-profile-path.md
    just dry

The preview should name the legacy `C:\Users\night\OneDrive\Documents\PowerShell` entries as removals and the corresponding `C:\Users\night\Documents\PowerShell` entries as additions. It must not propose target changes for Neovim, Git, Starship, Alacritty, or WezTerm.

After approving the preview by inspection, run in the real user context:

    just stow

Then use PowerShell to check the current target and all expected symbolic links:

    $PROFILE.CurrentUserCurrentHost
    Test-Path -LiteralPath $PROFILE.CurrentUserCurrentHost
    Get-Item -LiteralPath $PROFILE.CurrentUserCurrentHost -Force | Select-Object FullName, LinkType, Target
    Get-ChildItem -LiteralPath (Join-Path (Split-Path $PROFILE.CurrentUserCurrentHost -Parent) 'profile.d') -Force | Select-Object Name, LinkType, Target

The profile path must exist, report `SymbolicLink`, and target `packages/powershell/Microsoft.PowerShell_profile.ps1` in this repository. Each managed file in `profile.d` must also be a symbolic link to the matching repository source. `.dotter/cache.toml` must contain Documents mappings and no PowerShell mapping containing `OneDrive`.

In a new TTY-backed PowerShell session, run:

    Get-Command gits, gitwt | Select-Object Name, CommandType
    & packages/powershell/test/test-profile-commands.ps1

Both helper names must report `Function`. The diagnostic must load modules without an error; missing optional prerequisite tools may be reported as environment information rather than a profile-path failure.

For Unix workflow validation, inspect the local image and build it only if absent, then use a unique name. In PowerShell syntax the command sequence is:

    docker image inspect dotfile-agent-test:local
    docker build -f test/container/Dockerfile -t dotfile-agent-test:local test/container
    $taskContainer = "dotfile-agent-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))"
    $taskRepo = (Get-Location).Path
    docker run -d --name $taskContainer --label dotfile-agent-test=true --mount "type=bind,source=$taskRepo,target=/repo-ro,readonly" -e DEBIAN_FRONTEND=noninteractive dotfile-agent-test:local sleep infinity
    docker exec $taskContainer bash /repo-ro/test/container/init-workspace.sh
    docker exec -w /workspace $taskContainer bash -lc 'bash bootstrap/bootstrap.sh'
    docker exec -w /workspace $taskContainer bash -lc 'just install && just stow && just post'
    docker rm -f $taskContainer

Skip the build command when image inspection succeeds. Initialization must report that `/workspace/packages/container.list` was refreshed from `packages.list`. Cleanup must name only this task's container.

Finish with:

    git diff --check
    git diff --name-only
    git status --short --untracked-files=all

The task-specific tracked paths must be `.dotter/windows.toml`, `README.md`, `docs/packages/powershell.md`, `docs/dotter-and-just.md`, and this plan. The pre-existing Neovim status may remain, but its content must not have been changed by this task.

## Validation and Acceptance

The change is accepted when all of the following observable behaviors hold. `git diff --check` succeeds. `just dry` parses the merged TOML and proposes only the PowerShell target migration. Ordinary `just stow` completes without force, writes the new Documents links, and reconciles the ignored cache away from OneDrive. `Test-Path $PROFILE.CurrentUserCurrentHost` returns true. The entrypoint and every managed `profile.d` item are symbolic links into `packages/powershell`. A new rich PowerShell session exposes `gits` and `gitwt` as functions, and the package diagnostic has no module load errors. The disposable container completes bootstrap, install, stow, and post in `/workspace`, and is removed. Final status proves unrelated Neovim work remains outside the task diff.

## Idempotence and Recovery

Tracked edits are deterministic and can be reapplied. `just dry` is non-mutating and should always precede the first deployment after a mapping edit. `just stow` is the supported idempotent reconciliation path and can be retried after a transient failure.

If the preview contains an unrelated target operation, stop before deployment and report the exact operation. If the new profile target already contains a non-link file, do not overwrite it and do not use force; report the conflict so the operator can decide how to preserve it. If deployment fails after removing an old mapping, rerun `just dry`, inspect both target directories and `.dotter/cache.toml`, then retry ordinary `just stow`. Do not hand-edit the cache unless a later, separately approved recovery plan requires it.

The Docker workspace is disposable. If validation fails, capture the first blocking command and its output, then remove only the uniquely named task container. Recreate a fresh container for a retry rather than treating `/workspace` as source of truth.

## Artifacts and Notes

Initial host facts:

    PowerShell version: 7.6.3
    $PROFILE.CurrentUserCurrentHost: C:\Users\night\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
    Documents known folder: C:\Users\night\Documents
    Dotter cached profile target: C:\Users\night\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
    Release tags: none

Static and preview evidence:

    git diff --check: exit 0
    sandboxed just dry: unusable because Dotter expanded ~ to C:\Users\CodexSandboxOnline
    real-user just dry: intended six OneDrive removals plus six Documents additions
    unrelated real-user operation: packages/git/.gitconfig -> C:\Users\night\.gitconfig
    unrelated target state: ordinary 940-byte file, not a symbolic link
    post-preview profile targets: absent
    post-preview cache: six OneDrive PowerShell mappings, zero Documents-default mappings

Disposable Unix workflow evidence:

    image: dotfile-agent-test:local (sha256:df2e23faf9994bf7d17534aeb3159299bfb7ae1eb0700317f8b3b83a0d7eb6d1)
    container: dotfile-agent-20260731071220
    workspace initialization: copied /repo-ro to /workspace and replaced container.list with packages.list
    bootstrap: success; just 1.21.0 and dotter 0.13.5
    install: command success; 14 succeeded, 3 skipped, warnings for unavailable apt packages nvm and uv
    stow: success; symbolic links created under /root from /workspace sources
    post: success; Neovim plugins and tmux plugins installed
    repeat just dry: exit 0 with no pending Dotter operations
    cleanup: docker rm -f removed only dotfile-agent-20260731071220

Final repository review:

    git diff --check: exit 0
    task implementation diff: 59 insertions and 4 deletions across four existing tracked files
    new tracked-plan candidate: plans/powershell-profile-path.md
    unrelated Neovim modified/deleted/untracked path list: identical to initial status
    host profile targets after all validation: absent
    host PowerShell cache after all validation: six OneDrive mappings, zero Documents-default mappings

Microsoft's PowerShell profile documentation defines the Windows PowerShell 7 current-user, current-host default as `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`, states that `$PROFILE` values vary by user and host, and notes that Documents may be changed by folder redirection or OneDrive. Dotter's package/local configuration documentation states that file targets map repository-relative source keys to filesystem locations, that `[files]` in `local.toml` can override targets, and that `local.toml` wins merge conflicts after included platform configuration. These facts are embedded in this plan so implementation does not depend on those pages remaining available.

## Interfaces and Dependencies

No code interface, library, package selection, or command signature changes. The stable user commands remain `just dry` and `just stow`. The only changed deployment interface is the default target of two existing source keys:

    packages/powershell/Microsoft.PowerShell_profile.ps1 -> ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
    packages/powershell/profile.d -> ~/Documents/PowerShell/profile.d

PowerShell 7 is the runtime consumer. Dotter is the deployment and state-reconciliation dependency. `just` remains the stable command surface. Docker and the repository test image provide isolated Unix workflow proof.

Revision note (2026-07-31 07:07Z): Created the initial self-contained ExecPlan from verified host state and the approved implementation plan so tracked deployment behavior can now be changed safely.

Revision note (2026-07-31 07:09Z): Recorded completion of the mapping and documentation edits after a task-scoped diff confirmed that only the intended source paths were changed.

Revision note (2026-07-31 07:11Z): Recorded the sandbox home-resolution discrepancy and the real-user `.gitconfig` preview conflict, then paused host deployment exactly at the plan's unrelated-operation stop condition.

Revision note (2026-07-31 07:15Z): Recorded successful disposable Unix workflow validation, its best-effort apt warnings, idempotent dry-run evidence, and task-container cleanup.

Revision note (2026-07-31 07:16Z): Recorded final static and worktree review evidence, confirmed the Neovim boundary held, and left host deployment steps explicitly pending behind the `.gitconfig` preview stop condition.

Revision note (2026-07-31 08:32Z): Recorded the user's decision to commit the validated repository change independently while retaining the unresolved host deployment proof as explicit follow-up work.
