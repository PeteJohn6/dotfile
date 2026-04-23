# Add Ghostty Config Package

This ExecPlan is a living document. The sections `Progress`, `Surprises & Discoveries`, `Decision Log`, and `Outcomes & Retrospective` must be kept up to date as work proceeds.

This plan follows `PLANS.md` at the repository root. It is intentionally checked in because this work changes the maintained `install` and `stow` workflow surface.

## Trigger / Why This Needs an ExecPlan

This work adds a new Dotter-managed package and changes how Unix package installation interprets Homebrew aliases. Dotter is the repository tool that deploys files from `packages/` into a user's home directory during the `stow` stage. Homebrew casks are Homebrew-managed graphical applications installed with `brew install --cask`, which is different from ordinary formula installs. Because these changes affect what `just install` installs and what `just stow` deploys, they alter durable user workflow behavior and require a checked-in ExecPlan.

## Purpose / Big Picture

After this change, a Unix user using the default Dotter profile gets a managed Ghostty configuration at `~/.config/ghostty`, and macOS host installs can install Ghostty through Homebrew cask syntax in `packages/packages.list`. A contributor can see the behavior by inspecting the parsed install list, running `bash -n script/install.sh`, and validating the full `bootstrap -> install -> stow -> post` workflow in the disposable Unix container harness.

## Progress

- [x] (2026-04-23 00:00Z) Added the Ghostty Dotter package selection and deployment mapping in `.dotter/default/unix.toml`, `.dotter/global.toml`, and `.dotter/unix.toml`.
- [x] (2026-04-23 00:00Z) Added `packages/ghostty/config.ghostty`, `packages/ghostty/themes/custom`, and `packages/ghostty/backdrops/pastel-samurai.acrylic.png`.
- [x] (2026-04-23 00:00Z) Added `ghostty @macos | brew:cask:ghostty` to `packages/packages.list`.
- [x] (2026-04-23 00:00Z) Updated `script/install.sh` so `brew:cask:name` aliases install with `brew install --cask name` and satisfaction checks use `brew list --cask name` when no command is found on `PATH`.
- [x] (2026-04-23 00:00Z) Updated `README.md`, `docs/packages/overview.md`, and `docs/packages/ghostty.md` for Ghostty and Homebrew cask syntax.
- [x] (2026-04-23 00:00Z) Removed the unused Ghostty `final-showdown.jpg` backdrop from the intended package.
- [x] (2026-04-23 00:00Z) Ran static validation: `git diff --check`, `bash -n script/install.sh`, `rg 'final-showdown' docs/packages/ghostty.md packages/ghostty/config.ghostty packages/ghostty/themes/custom`, `git diff --cached --check`, and `git diff --cached --name-status`.
- [ ] Commit with message `feat: add ghostty config package`, then run the container workflow validation against committed `HEAD`.

## Surprises & Discoveries

- Observation: Ghostty is represented as a Unix Dotter config package, but the install list deliberately installs the application only on macOS.
  Evidence: `packages/packages.list` uses `ghostty @macos | brew:cask:ghostty`, while `.dotter/unix.toml` deploys `packages/ghostty` on Unix when the package is selected.
- Observation: Homebrew casks may not put a command named after the package on `PATH`, so command lookup alone is not a reliable satisfaction check.
  Evidence: `script/install.sh` checks `brew list --cask "${install_name#cask:}"` when the current package manager is `brew` and the install alias begins with `cask:`.

## Decision Log

- Decision: Keep Ghostty installation macOS-only through Homebrew cask syntax, while allowing the Unix Dotter package to be selected on Linux.
  Rationale: The repository has a stable host install list for common package managers, but this task does not introduce Linux Ghostty package source automation. Dotter deployment remains useful anywhere Ghostty is installed independently.
  Date/Author: 2026-04-23 / Codex
- Decision: Use `pastel-samurai.acrylic.png` as the only checked-in Ghostty backdrop.
  Rationale: The Ghostty config already references this PNG file, and keeping one static backdrop avoids a half-ported WezTerm-style dynamic selector.
  Date/Author: 2026-04-23 / Codex
- Decision: Represent cask aliases as `brew:cask:name` in `packages/packages.list` and as `cask:name` after package-manager alias parsing.
  Rationale: This preserves the existing `manager:name` alias model for all package managers while giving the Homebrew installer enough information to select the cask subcommand.
  Date/Author: 2026-04-23 / Codex

## Outcomes & Retrospective

The implementation adds the Ghostty package files, selects the package in the default Unix Dotter profile, documents the package, and extends the Unix installer to handle Homebrew cask aliases. Static validation passed before commit staging. Container workflow validation must run against committed `HEAD`; if Docker is unavailable, the exact blocker should be recorded in the final task summary.

## Context and Orientation

The user-facing workflow is `bootstrap -> install -> stow -> post`. `script/install.sh` implements Unix package installation behind `just install`. `packages/packages.list` is the host install list. `.dotter/default/unix.toml` is the seeded local Dotter profile for Unix users, `.dotter/global.toml` declares package names, and `.dotter/unix.toml` maps package directories to deployed home-directory paths. `packages/ghostty/` is the new Ghostty config package, with `config.ghostty` as the Ghostty entrypoint, `themes/custom` as the theme file, and `backdrops/pastel-samurai.acrylic.png` as the static background image. `docs/packages/overview.md` documents shared package-list syntax, while `docs/packages/ghostty.md` documents the new package.

## Plan of Work

First, keep the Dotter files aligned so the `ghostty` package exists globally, is selected by default for Unix local configs, and deploys `packages/ghostty` to `~/.config/ghostty`. Next, keep the Ghostty package self-contained with the config, theme, and one referenced backdrop image. Then update the host install list and `script/install.sh` so Homebrew cask aliases use `brew install --cask` and already-installed casks are skipped. Finally, update user-facing docs and validate with static checks plus the disposable Unix container workflow.

## Concrete Steps

Run all commands from the repository root, `/home/dotfile/.tree/feature/ghostty`.

Inspect the final tracked change set:

    git status --short
    git diff --stat

Run static validation:

    git diff --check
    bash -n script/install.sh
    rg 'final-showdown' docs/packages/ghostty.md packages/ghostty/config.ghostty packages/ghostty/themes/custom

Stage only the intended files and commit:

    git add .dotter/default/unix.toml .dotter/global.toml .dotter/unix.toml README.md docs/packages/overview.md docs/packages/ghostty.md packages/packages.list packages/ghostty/config.ghostty packages/ghostty/themes/custom packages/ghostty/backdrops/pastel-samurai.acrylic.png plans/ghostty-package.md script/install.sh
    git add -u packages/ghostty/backdrops/final-showdown.jpg
    git diff --cached --check
    git diff --cached --name-status
    git commit -m "feat: add ghostty config package"

Validate the committed workflow from a clean archive copy if Docker is available:

    tmpdir="$(mktemp -d)"
    git archive HEAD | tar -x -C "$tmpdir"
    docker build -f "$tmpdir/test/container/Dockerfile" -t dotfile-agent-test:local "$tmpdir/test/container"
    docker run -d --name dotfile-agent-ghostty --label dotfile-agent-test=true --mount type=bind,source="$tmpdir",target=/repo-ro,readonly -e DEBIAN_FRONTEND=noninteractive dotfile-agent-test:local sleep infinity
    docker exec dotfile-agent-ghostty bash /repo-ro/test/container/init-workspace.sh
    docker exec -w /workspace dotfile-agent-ghostty bash -lc 'bash bootstrap/bootstrap.sh'
    docker exec -w /workspace dotfile-agent-ghostty bash -lc 'just install && just stow && just post'
    docker rm -f dotfile-agent-ghostty
    rm -rf "$tmpdir"

## Validation and Acceptance

Static validation passes when `git diff --check`, `bash -n script/install.sh`, and `git diff --cached --check` exit with status zero, and when searching the Ghostty docs and config for `final-showdown` returns no matches. The staged name-status output must include only the intended Dotter, installer, package, docs, and plan files, and must not include `.codex`.

Workflow validation passes when the archive-built container runs `bash bootstrap/bootstrap.sh` and then `just install && just stow && just post` successfully in `/workspace`. If Docker is unavailable in the current environment, record the exact blocker, such as `docker: command not found`, and keep the static validation as the completed local proof.

## Idempotence and Recovery

The text edits and package additions are idempotent. Rerunning Dotter deployment should keep `~/.config/ghostty` mapped to `packages/ghostty`. If validation creates a temporary archive directory or disposable container, remove only that task-specific directory or container. Do not remove unrelated containers or local state. Do not commit `.codex`.

## Artifacts and Notes

The key package-list entry is:

    ghostty @macos | brew:cask:ghostty

The key Ghostty backdrop setting is:

    background-image = backdrops/pastel-samurai.acrylic.png

The expected staged files are the Dotter TOML files, `script/install.sh`, `packages/packages.list`, the `packages/ghostty/` files except `final-showdown.jpg`, `README.md`, `docs/packages/overview.md`, `docs/packages/ghostty.md`, and `plans/ghostty-package.md`.

## Interfaces and Dependencies

The Unix installer must continue using Bash and the existing package-manager dispatch in `script/install.sh`. For Homebrew only, an install alias parsed as `cask:name` must call `brew install --cask name`, and satisfaction checks must call `brew list --cask name` after command lookup fails. No package-manager behavior for apt, dnf, pacman, or ordinary Homebrew formula aliases should change. Dotter must deploy the complete `packages/ghostty` directory to `~/.config/ghostty` when `ghostty` is selected.

Revision note, 2026-04-23: Created this plan to document the Ghostty package work, the Homebrew cask alias behavior, the selected backdrop, and the validation path required before the feature commit.

Revision note, 2026-04-23: Updated progress and outcomes with static validation evidence before staging the feature commit.
