# Maintain the Alacritty package profile model

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

## Purpose / Big Picture

The Alacritty package should stay easy to deploy on Windows, macOS, and Linux while avoiding per-machine source files. After the current change, Windows users get a stable `wsl.toml` profile that opens the current user's default WSL distribution. A user can change the target distribution with `wsl --set-default <DistroName>` without changing this repository.

## Progress

- [x] (2026-04-19 08:20Z) Inspected the existing Alacritty Dotter mapping and confirmed the Windows package was tied to a tracked `ubuntu-20_04.toml` profile.
- [x] (2026-04-19 08:30Z) Evaluated a generated-profile approach using a Windows post hook and WSL distribution discovery.
- [x] (2026-04-19 08:38Z) Confirmed normal `wsl --list` usage does not require administrator rights, but sandboxed execution can fail with WSL service access errors.
- [x] (2026-04-19 08:43Z) Selected the simpler default-distribution profile model and implemented `packages/alacritty/wsl.toml`.
- [x] (2026-04-19 08:45Z) Updated the Windows Dotter mapping, README, and package documentation.
- [x] (2026-04-19 08:46Z) Validated the Windows deployment with `dotter.exe deploy --dry-run`, `git diff --check`, and TOML parsing.
- [x] (2026-04-19 09:05Z) Moved Alacritty design and iteration notes into this plan and kept `docs/packages/alacritty.md` focused on the current design.

## Surprises & Discoveries

- Observation: `wsl.exe --list --quiet` can fail inside the Codex sandbox with `Wsl/EnumerateDistros/Service/E_ACCESS_DENIED`.
  Evidence: the same command failed in the sandbox, while the user ran `wsl --list` successfully in their normal shell.
- Observation: The user's normal `wsl --list` output showed multiple distributions, including `Ubuntu-20.04`, `Ubuntu-24.04`, and `docker-desktop`.
  Evidence: the user-provided command output listed those distributions.
- Observation: The old Dotter cache can still mention a previously deployed per-distro profile after the source mapping changes.
  Evidence: `dotter.exe deploy --dry-run` showed historical cache removal for the old profile and addition for `packages/alacritty/wsl.toml`.

## Decision Log

- Decision: Use one tracked `packages/alacritty/wsl.toml` profile instead of one profile per WSL distribution.
  Rationale: A fixed profile follows the user-controlled WSL default distribution and avoids source churn when Ubuntu versions change.
  Date/Author: 2026-04-19 / Codex
- Decision: Do not add a Windows post hook for WSL discovery in this iteration.
  Rationale: Runtime discovery is unnecessary when `wsl.exe` can select the current user's default distribution, and a post hook would add failure modes around WSL service access and output parsing.
  Date/Author: 2026-04-19 / Codex
- Decision: Keep `wsl.toml` launching WSL as `root`, starting in `/home`, and running `zsh`.
  Rationale: This preserves the behavior expected by the current user while removing only the hardcoded distribution name.
  Date/Author: 2026-04-19 / Codex
- Decision: Keep user-facing package documentation focused on the current state and store design iteration here.
  Rationale: `docs/packages/alacritty.md` should be a maintenance reference, while this plan can preserve why the profile model changed.
  Date/Author: 2026-04-19 / Codex

## Outcomes & Retrospective

The Alacritty package now deploys a Windows `wsl.toml` profile that imports the base Alacritty config and starts `wsl.exe` without a `-d` distribution argument. The repository no longer needs tracked `ubuntu-20_04.toml` or `ubuntu-24_04.toml` files for Alacritty. The profile target is now controlled by the user's WSL default distribution, which is changed outside the repo with `wsl --set-default <DistroName>`.

The main tradeoff is explicitness versus maintenance cost. The profile no longer names `Ubuntu-24.04`, so readers must know that WSL default distribution controls the target. The README and package guide document that current behavior.

## Context and Orientation

This repository deploys terminal configuration through Dotter. Dotter reads package mappings from `.dotter/global.toml`, `.dotter/local.toml`, and included platform overlays such as `.dotter/windows.toml`. The Alacritty package lives under `packages/alacritty/`. On Windows, `.dotter/windows.toml` maps Alacritty files into `~/AppData/Roaming/Alacritty/`.

The base Alacritty config is `packages/alacritty/alacritty.toml.tmpl`, a Dotter-rendered template. The shared theme directory is `packages/alacritty/themes/`. The Windows WSL profile is `packages/alacritty/wsl.toml`, which imports the rendered `alacritty.toml` from the deployed Alacritty config directory.

## Plan of Work

Maintain a single Windows WSL profile file named `packages/alacritty/wsl.toml`. The file should import `./alacritty.toml`, set `program = "wsl.exe"`, and pass arguments that enter WSL as `root`, start in `/home`, and run `zsh`. It must not include `-d <DistroName>`.

Keep `.dotter/windows.toml` mapping `packages/alacritty/wsl.toml` to `~/AppData/Roaming/Alacritty/wsl.toml`. Do not add one tracked Alacritty profile per Ubuntu or WSL distribution version.

Keep `README.md` concise. It should tell users that the Windows Alacritty WSL profile follows the current user's default WSL distribution. Keep `docs/packages/alacritty.md` focused on the current package layout, runtime behavior, and validation commands.

## Concrete Steps

From the repository root, the completed implementation used these commands and checks:

    dotter.exe deploy --dry-run
    git diff --check
    python -c "import tomllib, pathlib; [tomllib.loads(pathlib.Path(p).read_text()) for p in ['.dotter/windows.toml','packages/alacritty/wsl.toml','packages/alacritty/alacritty.toml.tmpl']]"

Expected Windows dry-run signal:

    [ INFO] [+] symlink "packages/alacritty/wsl.toml" -> ".../AppData/Roaming/Alacritty/wsl.toml"
    [ INFO] template "packages/alacritty/alacritty.toml.tmpl" -> ".../AppData/Roaming/Alacritty/alacritty.toml"

## Validation and Acceptance

Acceptance is satisfied when Dotter preview includes `packages/alacritty/wsl.toml`, no Alacritty source mapping references `ubuntu-20_04.toml` or `ubuntu-24_04.toml`, and `packages/alacritty/wsl.toml` contains no `-d` distribution argument.

On a Windows machine with Alacritty and WSL installed, running Alacritty with the deployed `wsl.toml` profile should open the current user's default WSL distribution as `root`, in `/home`, running `zsh`. To change the opened distribution, run:

    wsl --set-default <DistroName>

## Idempotence and Recovery

Re-running `dotter.exe deploy --dry-run` or `just stow` is safe. Dotter cache entries for old Alacritty profiles are machine-local deployment state and should not be treated as source of truth. If a user needs a distro-specific Alacritty profile later, add it as a deliberate new profile rather than renaming `wsl.toml` back to a versioned Ubuntu file.

## Artifacts and Notes

The maintained Windows WSL profile content is:

    [general]
    import = ["./alacritty.toml"]

    [terminal.shell]
    program = "wsl.exe"
    args = ["-u", "root", "--cd", "/home", "zsh"]

## Interfaces and Dependencies

This package depends on Alacritty understanding TOML config files and on Windows resolving `wsl.exe` from the normal system path. The repository interface remains the same: users select the `alacritty` package in `.dotter/local.toml`, then run `just dry` or `just stow` to preview or deploy it.
