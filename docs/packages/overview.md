# Packages Overview

This overview covers the shared conventions for assets under `packages/` and the package guides under `docs/packages/`. These assets are directly involved in user-workflow because they participate in install, stow, and post behavior.

## Documentation Model

- `packages/<package>/` stores the deployable config, scripts, and package-local tests for a maintained package.
- `docs/packages/overview.md` stores the shared package conventions that apply across maintained packages.
- `docs/packages/<package>.md` stores the durable design intent, layout notes, operational guidance, and package-specific debugging and validation notes for that package.
- Package guides should describe which user-workflow stages the package participates in.
- Keep package design and package-specific testing guidance in the same `docs/packages/<package>.md` file instead of splitting them across multiple docs.
- Update `docs/packages/overview.md` when shared package conventions change.
- Update the matching package guide whenever a package's structure, bootstrap behavior, debugging guidance, or verification flow changes.

## Package Lists

| File | Purpose |
| --- | --- |
| `packages/packages.list` | Full desktop install list with optional `@platform` selectors |
| `packages/container.list` | Smaller container list without platform selectors |

Desktop list syntax:

```text
package[(cli_name)] [@platform[,platform...]] [| manager:name ...]
```

Key rules:

- `(cli_name)` defaults to the package name.
- `@windows`, `@macos`, and `@linux` filter desktop installs by host platform.
- `| manager:name` overrides the install name for a package manager.
- Comments and empty lines are ignored.

## Pre-Install Rules

`packages/pre-install-unix.sh` is sourced by `script/install.sh` and dispatches handlers from `PREINSTALL_RULE_MAP`.

Use pre-install rules when a package needs custom setup before package-manager fallback, such as:

- downloading a newer binary directly
- creating command entrypoints under `INSTALL_BIN_DIR`
- installing directory bundles under `INSTALL_OPT_DIR`

This keeps the install stage split into two responsibilities:

- `pre-install` handles preparation, manual install paths, and exceptional cases where the package manager is missing a package or does not provide the required form.
- the package-manager install phase stays focused on normal manager-driven installs.
- because `script/install.sh` skips tools whose CLI is already available, a successful pre-install path can satisfy the package before the package-manager phase runs.

Unix currently uses the explicit rule library in `packages/pre-install-unix.sh`.
Windows currently keeps its pre-install preparation inside `script/install.ps1` before the main Scoop install loop.

Current built-in rules:

- `neovim`: apt-only tarball install path
- `starship`: Linux installer path into `INSTALL_BIN_DIR`

## Post Hooks

Per-tool post-install scripts live in `packages/post/`.

Rules for post hooks:

- name the script by CLI command, not by package-manager package name
- self-check the CLI first and exit `0` when the tool is absent
- keep hooks idempotent and emit `[post:<tool>]` logs

The post orchestrators run every discovered script; self-checking is the only filter.

## Maintained Config Packages

Repo-managed config packages live under `packages/<name>/`. When adding or changing one:

1. update the install list if software installation should change
2. update dotter mappings if deployed files should change
3. add a pre-install rule only when the package-manager path is insufficient
4. add a post hook only when work must happen after deployment
5. sync `docs/packages/overview.md` when shared package conventions change
6. sync the matching `docs/packages/<package>.md` guide when the package design, workflow, debugging guidance, or verification flow changes
7. sync `README.md` and `docs/user-workflow.md` when the user-visible surface changes

Treat package changes in terms of the user-workflow stage they affect: install, stow, or post.
