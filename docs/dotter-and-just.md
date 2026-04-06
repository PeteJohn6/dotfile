# Dotter And Just

This document defines the maintainer guidance for Dotter deployment behavior and the `justfile` command surface that exposes it. They are documented together because `justfile` defines the stable commands users run, while Dotter implements the deployment semantics behind `dry`, `stow`, `stow-force`, and `uninstall`.

## Why They Are Paired

- `justfile` is the stable command surface for user-workflow after bootstrap.
- Dotter is the deployment engine behind the `stow` stage and the supporting preview and undeploy commands.
- Changes to `.dotter/` often require matching validation through the `justfile` commands users actually run.
- Changes to `justfile` recipes should preserve existing Dotter-backed behavior unless the command surface is being intentionally revised.

## Command Mapping

| User command | Runtime behavior | Maintainer concern |
| --- | --- | --- |
| `just dry` | previews Dotter deployment with `deploy --dry-run` | preview semantics, conflict reporting, and safe validation path |
| `just stow` | runs Dotter deploy in normal mode | default deployment behavior for selected config packages |
| `just stow-force` | runs Dotter deploy with `--force` | overwrite behavior and explicit conflict resolution |
| `just uninstall` | runs Dotter undeploy | full undeploy and reset behavior |

Treat changes to these commands as changes to stow-side user-workflow semantics, not as isolated recipe edits.

## `.dotter/` Layout

| Path | Role |
| --- | --- |
| `.dotter/global.toml` | canonical base package model, shared helpers, and default mappings |
| `.dotter/unix.toml` | Unix-specific mapping and variable overrides |
| `.dotter/windows.toml` | Windows-specific mapping and variable overrides |
| `.dotter/default/` | seed templates for local package selection |
| `.dotter/local.toml` | machine-local package selection and overlay includes |
| `.dotter/cache.toml` | machine-local deployment state used for reconciliation |

## Merge And State Model

Dotter merges configuration in this order:

1. `.dotter/global.toml`
2. `.dotter/local.toml`
3. files included from `.dotter/local.toml`

Maintain these rules:

- define the base package model in `.dotter/global.toml`
- use platform overlays to patch paths or variables, not to redefine package selection
- keep `.dotter/local.toml` as machine-local operator state
- never treat `.dotter/local.toml` or `.dotter/cache.toml` as canonical source of truth

## Editing Rules

- Prefer changing `.dotter/` mappings, package files under `packages/`, or platform overlays before changing `justfile`.
- Change `justfile` only when command behavior, composition, or operator messaging truly needs to change.
- Keep `just dry`, `just stow`, `just stow-force`, and `just uninstall` aligned with the Dotter behavior they expose.
- Treat `.dotter/default/` as seed material for local state, not as a second canonical package model.
- When a mapping change affects selected config packages, update the relevant `docs/packages/<package>.md` guide in the same change.

## Validation And Debugging

- Start with `just dry` when changing mappings, overlays, or deploy-path logic.
- Use `just stow` to validate normal deployment behavior after preview semantics still look correct.
- Use `just stow-force` only when validating intentional overwrite behavior.
- Use `just uninstall` only when validating undeploy or reset semantics.
- When `justfile` changes, validate the exact user-facing command path that changed instead of testing Dotter in isolation.
- When Unix runtime behavior is involved and the host is not the right proof surface, use the validation path routed from `docs/maintainer-workflow.md`.

## Documentation Boundaries

- Keep the user-facing stage contract and command guarantees in `docs/user-workflow.md`.
- Keep maintainer routing, validation depth, and skill usage in `docs/maintainer-workflow.md`.
- Keep Dotter merge rules, `justfile` command mapping, deployment-state rules, and stow-side validation guidance in this document.
