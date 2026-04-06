# Maintainer Workflow

This document defines the maintainer workflow for changing the repository. It is separate from the user workflow and should preserve the user-workflow model by default.

## Default Rule

Start by identifying which user-workflow stage changed. Treat `bootstrap -> install -> stow -> post` as the maintained contract, then change the implementation behind the affected stage.

- Start every maintenance task by asking whether bootstrap, install, stow, or post semantics changed.
- Preserve the user-facing contract by default.
- Change the implementation layer behind the affected stage first. Change `justfile` only when the command surface is being intentionally revised.
- `justfile` belongs to the user command surface and generally should not change unless the interface is being intentionally revised.
- Internal path ownership is secondary to stage ownership.
- Validation should prove that the affected stage contract still holds.
- Treat skill usage as part of the maintainer workflow. Use repository skills when runtime validation is required by the chosen proof surface.

## Development Paths

These top-level paths are directly involved in user-workflow, even though maintainers often edit them:

- `bootstrap/`
- `script/`
- `packages/`
- `.dotter/`
- `justfile`
- `README.md`

These top-level paths are not directly involved in user-workflow, but maintainers use them to document, validate, and plan changes to it:

- `AGENTS.md`
- `docs/`
- `test/`
- `plans/`
- `.agents/`

## Package Documentation

When changing a specific package configuration, read `docs/packages/overview.md` first for shared package conventions. Then consult `docs/packages/<package>.md` if it exists.

- Record shared package conventions and cross-package rules in `docs/packages/overview.md`.
- Record the package's design intent, layout notes, and configuration model in `docs/packages/<package>.md`.
- Record package-specific debugging and validation guidance in that same `docs/packages/<package>.md` file.
- When changing a package configuration, use `devcontainer-for-unix-work` to validate that package configuration in isolation before broader workflow validation.
- Keep generic workflow-level validation guidance in this document; put package-specific commands, common failure modes, and troubleshooting notes in the package doc.

## Dotter And Just

When changing `.dotter/` layout, Dotter merge rules, or the `justfile` implementation behind `dry`, `stow`, `stow-force`, or `uninstall`, read `docs/dotter-and-just.md`.

- Keep the user-facing stage contract in `docs/user-workflow.md`.
- Keep maintainer routing and validation depth in this document.
- Keep Dotter merge rules, deployment-state rules, `justfile` command mapping, and stow-side validation guidance in `docs/dotter-and-just.md`.

## Change Routing

| Change type | Primary stage | Primary edit paths | Validation path |
| --- | --- | --- | --- |
| Bootstrap behavior | `bootstrap` | `bootstrap/`, `justfile`, `README.md` | platform-specific command path or targeted static proof |
| Install behavior | `install` | `script/`, `packages/`, `justfile`, `README.md` | narrow install proof first, then broader workflow proof if stage boundaries move |
| Stow behavior | `stow` | `.dotter/`, `packages/`, `justfile`, `README.md` | read `docs/dotter-and-just.md`, then run dotter preview or targeted deploy proof |
| Post-install behavior | `post` | `script/`, `packages/`, `justfile`, `README.md` | targeted post hook or composed workflow proof |
| Supporting docs and validation | supporting | `test/`, `docs/`, `plans/`, `.agents/` | validate the changed proof surface itself, then the affected runtime path if needed |
| Command surface | multiple stages | `justfile`, `README.md`, `AGENTS.md`, `docs/` | validate the changed command path, use `docs/dotter-and-just.md` when stow-side commands changed, and update workflow docs in the same change |

## Validation Flow

1. Identify which user-workflow stage changed: bootstrap, install, stow, post, or only validation/supporting paths.
2. Update the implementation layer behind that stage.
3. Run static validation appropriate to the edited paths, including docs and other non-runtime checks. Prefer direct formatter, linter, and toolchain commands over repo-local wrapper scripts.
4. When a package configuration changes, use `devcontainer-for-unix-work` to validate that package configuration in isolation before broader workflow validation.
5. Use `devcontainer-for-unix-work` to validate that the full user-facing `bootstrap -> install -> stow -> post` model still holds.
6. Add the narrowest relevant stage-specific test, harness, or command path when the change needs more than the full workflow check to prove the affected contract still holds.
7. Update the user-facing and maintainer-facing docs in the same change, including `docs/packages/overview.md` when shared package conventions changed, `docs/packages/<package>.md` when package behavior changed, and `docs/dotter-and-just.md` when stow-side deployment or command-surface implementation changed.

## Validation Skills

- Prefer `test/` or the relevant tool's direct formatter, linter, or built-in checks first when they already provide the right proof surface.
- Use `devcontainer-for-unix-work` to validate package configurations in isolation when package config changes.
- Use `devcontainer-for-unix-work` to validate the full user-facing workflow model.
- Keep validation aligned with the affected user-workflow stage, not internal directory boundaries.
