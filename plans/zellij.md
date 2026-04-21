# Add an Inert Zellij Configuration

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `PLANS.md` in the repository root. It is self-contained so a contributor can resume the work with only this file and the current working tree.

## Trigger / Why This Needs an ExecPlan

This task adds a new durable configuration artifact under `packages/`. The root `AGENTS.md` says an ExecPlan is mandatory before significant configuration work when a relevant plan exists or when work can affect durable repository outputs. There was no existing Zellij plan under `plans/`, so this file records the chosen scope before any tracked Zellij configuration is added.

The scope is intentionally narrow. This change creates an inert Zellij config file only. It does not wire Zellij into Dotter deployment, default package selections, package-manager install lists, bootstrap, install, stow, post-install scripts, `README.md`, `docs/`, `justfile`, or repository tests. Because it does not alter the maintained `bootstrap -> install -> stow -> post` user workflow, there is no compatibility risk to existing users.

## Purpose / Big Picture

After this change, the repository contains a ready-to-use Zellij configuration at `packages/zellij/config.kdl`. Zellij is a terminal workspace manager; in this plan, it is treated as an optional tool that a user may point at this config manually. The config mirrors the high-frequency behavior of this repository's tmux setup without replacing Zellij's defaults.

A user can see the result by running `zellij --config packages/zellij/config.kdl setup --check` from the repository root when Zellij is installed. The file remains inert until a future change deploys it through Dotter or the user manually passes it to Zellij.

## Progress

- [x] (2026-04-21T18:10:58Z) Read `PLANS.md`, confirmed no existing `plans/zellij.md` was present, and inspected the tmux config that this Zellij config should resemble.
- [x] (2026-04-21T18:10:58Z) Checked that `zellij` is not installed on the host PATH and that `apt-cache policy zellij` prints no candidate from the current host apt index.
- [x] (2026-04-21T18:10:58Z) Created this ExecPlan before adding a tracked Zellij config file.
- [x] (2026-04-21T18:10:58Z) Created `packages/zellij/config.kdl` with root options and incremental normal-mode keybindings.
- [x] (2026-04-21T18:10:58Z) Ran static validation with `git diff --check`; it exited 0 with no output. Because the new files are untracked and the sandbox cannot write the Git index, also ran `git diff --check --no-index /dev/null packages/zellij/config.kdl` and `git diff --check --no-index /dev/null plans/zellij.md`; both emitted no whitespace warnings and exited 1 only because `--no-index` reports differences from `/dev/null`.
- [x] (2026-04-21T18:10:58Z) Checked for Zellij with `command -v zellij`; it exited 1 with no output, so `zellij --config packages/zellij/config.kdl setup --check` was skipped.
- [x] (2026-04-21T18:10:58Z) Checked for the devcontainer CLI required by the repository's Unix validation skill; `command -v devcontainer` exited 1 with no output, so devcontainer validation could not be started.
- [x] (2026-04-21T18:10:58Z) Updated this ExecPlan with final validation results and outcome notes.
- [x] (2026-04-22) Re-ran runtime validation with the user-provided executable at `/home/zellij`; `/home/zellij --version` printed `zellij 0.44.1`, and `/home/zellij --config packages/zellij/config.kdl setup --check` exited 0 with `[CONFIG FILE]: Well defined.`
- [x] (2026-04-22) Re-ran static validation after updating this plan; `git diff --check` exited 0 with no output, and `git diff --check --no-index /dev/null packages/zellij/config.kdl` plus `git diff --check --no-index /dev/null plans/zellij.md` emitted no whitespace warnings.

## Surprises & Discoveries

- Observation: The current host does not have a `zellij` executable on PATH, and the current host apt index has no visible `zellij` candidate.
  Evidence: `command -v zellij` exited 1 with no output; `apt-cache policy zellij` exited 0 with no output.

- Observation: A working Zellij executable is available at `/home/zellij`, even though it is not on PATH.
  Evidence: `/home/zellij --version` printed `zellij 0.44.1`; `/home/zellij --config packages/zellij/config.kdl setup --check` exited 0 and reported `[CONFIG FILE]: Well defined.`

- Observation: Zellij keybindings can be added to the default keybinding set by placing entries in a `keybinds` block. This supports the chosen incremental approach because a small `normal` block can add direct keys without clearing the defaults.
  Evidence: The Zellij user guide describes `keybinds { normal { bind "Alt h" { MoveFocusOrTab "Left"; } } }` as a valid shape.

- Observation: The repository's disposable devcontainer validation path is unavailable in this environment because the devcontainer CLI is not installed.
  Evidence: `command -v devcontainer` exited 1 with no output before any container startup command could be attempted.

- Observation: The sandbox cannot write this linked worktree's Git index, so intent-to-add validation could not be used for untracked files.
  Evidence: `git add -N packages/zellij/config.kdl plans/zellij.md` failed with `fatal: Unable to create '/home/dotfile/.git/worktrees/zellij/index.lock': Read-only file system`; `ls -l /home/dotfile/.git/worktrees/zellij/index.lock` then confirmed no lock file remained.

## Decision Log

- Decision: Add only `packages/zellij/config.kdl` in this pass.
  Rationale: The user selected a config-only scope. Keeping the file inert avoids changing installation, deployment, post-install hooks, default templates, README workflows, docs, or tests.
  Date/Author: 2026-04-21 / Codex

- Decision: Preserve Zellij's default keybindings and add only frequent tmux-like direct keys in `normal` mode.
  Rationale: This gives tmux users familiar pane and tab movement while minimizing conflict with the official Zellij key model.
  Date/Author: 2026-04-21 / Codex

- Decision: Use `MoveFocusOrTab` for horizontal `Alt h` and `Alt l`, but `MoveFocus` for vertical `Alt j` and `Alt k`.
  Rationale: Horizontal movement can reasonably fall through to previous or next tab when no pane exists in that direction, which resembles tmux pane/window navigation. Vertical movement has no tab analogy.
  Date/Author: 2026-04-21 / Codex

- Decision: Do not implement tmux's previous/next session direct keys.
  Rationale: The Zellij action list exposes session actions such as switching sessions but does not provide a direct previous-session or next-session action equivalent to tmux's `switch-client -p` and `switch-client -n`.
  Date/Author: 2026-04-21 / Codex

- Decision: Do not add Zellij to `packages/packages.list` or `packages/container.list`.
  Rationale: The host apt index does not show a `zellij` candidate, and package installation is outside the selected config-only scope.
  Date/Author: 2026-04-21 / Codex

## Outcomes & Retrospective

The config-only Zellij scope was completed. The change added `packages/zellij/config.kdl` and this plan file, with no edits to Dotter deployment, package lists, README/docs, `justfile`, or tests. Static validation passed with `git diff --check`, and additional `--no-index` whitespace checks over the new untracked files emitted no warnings. Runtime config validation passed with `/home/zellij --config packages/zellij/config.kdl setup --check`, which exited 0 and reported `[CONFIG FILE]: Well defined.` Devcontainer validation was skipped because the `devcontainer` CLI is not installed in this environment.

## Context and Orientation

The repository is a dotfile monorepo organized around a user workflow of `bootstrap -> install -> stow -> post`. The `bootstrap/` directory prepares machines, `script/` performs install and post-install orchestration, `packages/` stores package lists and managed configs, and `.dotter/` describes which package files are deployed into a user's home directory.

This plan intentionally does not touch the workflow pieces. The new Zellij file will live at `packages/zellij/config.kdl`, but there will be no `.dotter/` entry pointing it at `~/.config/zellij/config.kdl`, no package-list entry installing a `zellij` executable, and no post-install hook.

The tmux reference behavior lives in `packages/tmux/conf.d/00-options.conf` and `packages/tmux/conf.d/10-keybindings.conf`. The tmux options set `/bin/zsh` as the default shell, enable mouse support, keep a 100000-line history buffer, and enable clipboard integration. The tmux keybindings add direct `Alt+h/j/k/l` pane movement, `Alt+,` and `Alt+.` previous/next window navigation, `Alt+t` window creation, `Alt+w` window killing, and previous/next session keys. Zellij calls tmux-like windows "tabs"; this plan maps tmux window actions to Zellij tab actions.

Zellij configuration files use KDL, a structured text format where nodes have names, arguments, and optional child blocks. The root of `config.kdl` may contain options such as `default_shell "/bin/zsh"` and `mouse_mode true`. Keybindings belong inside a `keybinds` block, and mode-specific bindings belong inside mode blocks such as `normal`.

## Plan of Work

Create `packages/zellij/config.kdl` as a new file. The file should begin with a short comment explaining that it is inspired by the repo's tmux defaults and that it keeps Zellij's default keybindings. Then add root options that match the intended Zellij behavior:

    default_shell "/bin/zsh"
    on_force_close "detach"
    pane_frames true
    mouse_mode true
    scroll_buffer_size 100000
    copy_clipboard "system"
    copy_on_select true
    theme "catppuccin-macchiato"
    show_startup_tips false
    show_release_notes false

Then add a `keybinds` block with only a `normal` block. Inside `normal`, add these bindings:

    bind "Alt h" { MoveFocusOrTab "Left"; }
    bind "Alt j" { MoveFocus "Down"; }
    bind "Alt k" { MoveFocus "Up"; }
    bind "Alt l" { MoveFocusOrTab "Right"; }
    bind "Alt ," { GoToPreviousTab; }
    bind "Alt ." { GoToNextTab; }
    bind "Alt t" { NewTab; }
    bind "Alt w" { CloseTab; }

Do not edit `.dotter/`, `packages/packages.list`, `packages/container.list`, `README.md`, `docs/`, `justfile`, or any test directory for this scope.

## Concrete Steps

From the repository root, create the package directory if it does not already exist:

    mkdir -p packages/zellij

Create `packages/zellij/config.kdl` with the exact options and keybindings described in the Plan of Work. After the file exists, run:

    git diff --check

If the command succeeds, it should print no output and exit 0.

Then check whether Zellij is installed:

    command -v zellij

If this prints a path, run:

    zellij --config packages/zellij/config.kdl setup --check

Expect exit 0. If `command -v zellij` prints nothing and exits 1 but the user supplies an explicit executable path, run the same check through that executable. If no executable is available, do not install Zellij in this pass; record that runtime validation was skipped because the user-selected scope avoids install workflow changes.

The repository's Unix validation skill prefers validating inside `test/devcontainer/devcontainer.json` when the devcontainer CLI is available. In this environment, `command -v devcontainer` printed nothing and exited 1, so no devcontainer startup or cleanup command could run.

## Validation and Acceptance

The static acceptance check is `git diff --check` from the repository root. It must exit 0 with no whitespace errors.

The runtime acceptance check is conditional. If Zellij is already installed or an explicit executable path is supplied, `zellij --config packages/zellij/config.kdl setup --check` or the equivalent path-qualified command must exit 0, proving that the config is valid according to the local Zellij binary. If no Zellij executable is available, the runtime check is considered skipped, not failed, because this task explicitly avoids adding install support.

The final diff must include only `plans/zellij.md` and `packages/zellij/config.kdl`, aside from any pre-existing untracked user files that were already present. The final diff must not modify deployment, install, docs, README, `justfile`, or tests.

## Idempotence and Recovery

Creating `packages/zellij/` with `mkdir -p` is idempotent. Reapplying the config content is safe because the intended file is small and fully described in this plan. If the config check fails, compare `packages/zellij/config.kdl` against the exact target in this plan and correct any KDL syntax or action-name typo.

If a future contributor wants this config deployed automatically, that must be a separate scoped change that updates `.dotter/`, package lists if needed, README/docs, and validation for the full `bootstrap -> install -> stow -> post` workflow.

## Artifacts and Notes

The intended `packages/zellij/config.kdl` content is:

    // Zellij config inspired by this repo's tmux defaults.
    // It keeps Zellij's default keybindings and adds only frequent direct keys.

    default_shell "/bin/zsh"
    on_force_close "detach"
    pane_frames true
    mouse_mode true
    scroll_buffer_size 100000
    copy_clipboard "system"
    copy_on_select true
    theme "catppuccin-macchiato"
    show_startup_tips false
    show_release_notes false

    keybinds {
        normal {
            bind "Alt h" { MoveFocusOrTab "Left"; }
            bind "Alt j" { MoveFocus "Down"; }
            bind "Alt k" { MoveFocus "Up"; }
            bind "Alt l" { MoveFocusOrTab "Right"; }

            bind "Alt ," { GoToPreviousTab; }
            bind "Alt ." { GoToNextTab; }
            bind "Alt t" { NewTab; }
            bind "Alt w" { CloseTab; }
        }
    }

Plan revision note: 2026-04-21, initial plan created to capture the config-only Zellij scope before adding the tracked configuration file.

Plan revision note: 2026-04-21, updated progress, discoveries, concrete steps, and outcomes after adding the config and running available validation.

Plan revision note: 2026-04-22, updated validation results after the user provided `/home/zellij` for runtime config checking.
