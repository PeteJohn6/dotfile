# Add a repo-managed WezTerm package with upstream background support

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This document is maintained in accordance with [PLANS.md](PLANS.md).

## Purpose / Big Picture

After this change, users can enable a repo-managed `wezterm` package alongside `alacritty` and get a minimal WezTerm setup with the upstream-inspired theme, fallback font stack, and background image system. The deployed config stays aligned with the repo's `bootstrap -> install -> stow -> post` model and can be verified through Dotter preview plus a full devcontainer workflow run.

## Progress

- [x] (2026-04-12 11:30Z) Surveyed the existing `alacritty` package, Dotter mappings, README examples, and maintainer workflow requirements.
- [x] (2026-04-12 11:38Z) Researched the upstream WezTerm config modules for fonts, theme, bindings, and background controller behavior.
- [x] (2026-04-12 11:55Z) Locked the target shape: keep `alacritty`, add `wezterm`, disable statusline/mux UI/tab bar, preserve current Alacritty bindings, add background shortcuts, and deploy on both Windows and Unix.
- [x] (2026-04-12 12:12Z) Implemented the `packages/wezterm/` config tree, Dotter mappings, default-template changes, README updates, and package guide.
- [x] (2026-04-12 12:17Z) Imported the sample backdrop set and pre-rendered acrylic variants.
- [x] (2026-04-12 12:19Z) Ran Windows `dotter.exe deploy --dry-run` with a temporary `.dotter/local.toml` and confirmed the whole `packages/wezterm` tree maps into `~/.config/wezterm`.
- [x] (2026-04-12 12:35Z) Ran the Unix devcontainer workflow: `bootstrap`, `just install`, and `just stow && just post` with `wezterm` enabled in `/workspace/.dotter/local.toml`.
- [x] (2026-04-12 12:37Z) Removed the disposable validation container after the Unix checks completed.

## Surprises & Discoveries

- Observation: the repo already installs `wezterm` from `packages/packages.list`, but it is not yet a repo-managed Dotter package.
  Evidence: `README.md` lists `wezterm` under software install lists, while `.dotter/*.toml` only map `alacritty`.
- Observation: the upstream background controller must call `set_images()` during initial `wezterm.lua` evaluation or WezTerm hits coroutine restrictions.
  Evidence: upstream `utils/backdrops.lua` documents that `wezterm.glob(...)` must run from `wezterm.lua` on initial load.
- Observation: local Git status inspection is blocked by Git's safe-directory check in this sandboxed user context.
  Evidence: `git status --short` fails with `detected dubious ownership`.
- Observation: the shared Unix validation environment does not install `wezterm`, because the repo package list only installs it on macOS and Windows.
  Evidence: `packages/packages.list` contains `wezterm @macos,windows`, so Unix validation had to prove deployment correctness through Dotter and the full workflow rather than by launching WezTerm itself.
- Observation: the devcontainer workflow still has pre-existing install failures for `nvm` and `uv` on Ubuntu apt.
  Evidence: `just install` completed with `14 succeeded, 3 skipped, 2 failed` and named `nvm` and `uv` as packages that `apt` could not locate.
- Observation: the installed `devcontainer` CLI version has no `down` command.
  Evidence: `devcontainer down --workspace-folder . --config test/devcontainer/devcontainer.json` failed with `Unknown arguments: ... down`, so cleanup used `docker rm -f <container-id>` instead.

## Decision Log

- Decision: deploy WezTerm as a full directory at `~/.config/wezterm` instead of a single file.
  Rationale: the upstream background system, theme, and package utilities are naturally modular and are easier to maintain in a small directory tree than by flattening everything into one file.
  Date/Author: 2026-04-12 / Codex
- Decision: keep the minimal UI constraints even while porting upstream modules.
  Rationale: the user explicitly asked for no statusline, no multiplexer behavior, and no tab bar, so only theme/fonts/background-specific pieces are imported.
  Date/Author: 2026-04-12 / Codex
- Decision: do not port upstream GPU adapter selection.
  Rationale: background/theme/fonts are the desired features; hard-coding backend preferences introduces machine-specific behavior without being required for the user-visible result.
  Date/Author: 2026-04-12 / Codex

## Outcomes & Retrospective

The repository now has a repo-managed `wezterm` package that deploys a minimal WezTerm config with imported backdrop logic, theme, fonts, background utilities, and a sample backdrop set. Dotter mappings and default templates were updated on both Unix and Windows, and the README plus package documentation now describe the new maintained package.

Validation proved the new package integrates into both Windows and Unix deployment flows. The Windows dry-run resolved the whole `packages/wezterm` tree correctly, and the Unix devcontainer completed `bootstrap`, `install`, `stow`, and `post` with `wezterm` included in the active local config. The only validation failures observed were the pre-existing `nvm` and `uv` apt install misses, which are outside the scope of this change.

## Context and Orientation

This repository maintains terminal configs through Dotter. `packages/alacritty/` already contains the current terminal config, while `.dotter/global.toml`, `.dotter/unix.toml`, `.dotter/windows.toml`, and `.dotter/default/*.toml` define which package names exist, how they map to platform paths, and which ones bootstrap enables by default. `README.md` is the user-facing overview and must change when maintained packages or default package examples change. `docs/packages/overview.md` defines the package-doc convention, so the new `wezterm` package needs a dedicated guide at `docs/packages/wezterm.md`.

The target WezTerm package lives under `packages/wezterm/`. It needs a top-level `wezterm.lua`, subordinate `config/`, `colors/`, and `utils/` modules, and a `backdrops/` directory for shipped original images plus pre-rendered acrylic variants. Dotter should deploy the package directory as `~/.config/wezterm` on both Unix and Windows so the same module layout works on each platform.

## Plan of Work

Create the `packages/wezterm/` tree with a small, direct module graph. `wezterm.lua` should set up `package.path`, require the background controller, call `set_images()` during initial load, then merge `appearance`, `bindings`, `fonts`, and `general` into a config built by `wezterm.config_builder()`.

Port the upstream theme to `colors/custom.lua`. Port the font stack to `config/fonts.lua` but replace the Windows and Linux fallback font names with locally sensible defaults. Port the background controller to `utils/backdrops.lua` with only path and comment cleanup. Add `config/appearance.lua` and `config/bindings.lua` that preserve the repo's minimal UI while exposing the background shortcuts and the current Alacritty copy/paste/new-window/fullscreen bindings.

Update `.dotter/global.toml` to define the `wezterm` package, then add whole-directory mappings in `.dotter/unix.toml` and `.dotter/windows.toml`. Extend the default package arrays in `.dotter/default/unix.toml` and `.dotter/default/windows.toml` to include `wezterm`.

Write `docs/packages/wezterm.md` so a contributor can understand the package layout, the background image modes, the sample-image expectations, and the verification flow. Update `README.md` examples and the maintained-package table to mention `wezterm` as a repo-managed config package.

Import a small sample backdrop set with pre-rendered acrylic variants. Then validate with Dotter dry-run on Windows and with the repository devcontainer for Unix.

## Concrete Steps

From the repository root:

1. Create `plans/wezterm-minimal-upstream-port.md` and keep this document up to date as implementation proceeds.
2. Add the `packages/wezterm/` module tree and backdrop assets.
3. Update Dotter files and README/docs.
4. Create a temporary `.dotter/local.toml` for Windows dry-run validation.
5. Run devcontainer-based Unix validation.

Expected Windows dry-run signal:

    ==> Running dotter dry-run (preview mode)...
    ... packages/wezterm -> ~/.config/wezterm ...
    ==> Dry-run complete.

Observed Windows dry-run signal:

    [ INFO] [+] symlink "packages/wezterm\colors\custom.lua" -> "C:\Users\CodexSandboxOffline\.config\wezterm\colors\custom.lua"
    [ INFO] [+] symlink "packages/wezterm\wezterm.lua" -> "C:\Users\CodexSandboxOffline\.config\wezterm\wezterm.lua"

## Validation and Acceptance

Acceptance is satisfied when all of the following are true:

1. Dotter preview resolves the new `wezterm` package without configuration errors on Windows.
2. The Unix devcontainer can still execute the `bootstrap -> install -> stow -> post` workflow after the new package is added.
3. The deployed WezTerm config contains the imported theme, fallback font stack, background controller, and pre-rendered backdrop assets.
4. A machine with WezTerm installed can launch the deployed config, show an original backdrop by default, switch to a pre-rendered acrylic backdrop, and react to the configured background shortcuts while still lacking statusline, mux UI, and tab bar.

Static and workflow validation completed. Runtime launch validation still needs a host with WezTerm installed, which this sandbox does not provide.

## Idempotence and Recovery

The changes are additive. Re-running Dotter preview or the devcontainer workflow is safe. The temporary `.dotter/local.toml` used for validation should be deleted after checks complete. If a shipped sample backdrop causes issues, the whole `packages/wezterm/backdrops/` directory can be adjusted without touching the deployment interface.

## Artifacts and Notes

Important upstream modules being ported:

    utils/backdrops.lua
    colors/custom.lua
    config/fonts.lua

## Interfaces and Dependencies

At the end of this work, the repository must contain a new package name `wezterm` in Dotter config. `.dotter/unix.toml` and `.dotter/windows.toml` must deploy `packages/wezterm` to `~/.config/wezterm`. `packages/wezterm/wezterm.lua` must build the runtime config by merging the four config modules plus the imported theme/background utilities. `docs/packages/wezterm.md` must explain the package and its validation flow.

Revision note: created this plan during implementation so the change follows the repository ExecPlan requirement from design through validation.

Revision note: updated progress, discoveries, and outcomes after implementation and validation, including the pre-existing Unix `nvm` and `uv` install failures that are unrelated to the WezTerm package.
