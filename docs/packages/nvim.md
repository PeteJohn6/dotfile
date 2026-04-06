# Neovim Package

This document explains the repo-managed Neovim package under `packages/nvim/`. It covers both the file layout and the design choices behind the package.

## Design Intent

- Keep the entrypoint thin and push durable behavior into small Lua modules.
- Use `lazy.nvim` as the package bootstrap boundary so plugin setup stays declarative.
- Centralize language tooling in one place so adding language support is a data change, not a repo-wide refactor.
- Treat `lazy-lock.json` as a reproducibility artifact, not a scratch file.

## Structure

| Path | Role |
| --- | --- |
| `packages/nvim/init.lua` | Package entrypoint |
| `packages/nvim/lua/core/` | Core options, keymaps, GUI settings, helpers |
| `packages/nvim/lua/lazyconf.lua` | `lazy.nvim` bootstrap and setup |
| `packages/nvim/lua/plugins/` | Plugin specs grouped by concern |
| `packages/nvim/lazy-lock.json` | Reproducible plugin lockfile |

## Package Layout

Plugins are grouped by behavior rather than load order:

- appearance
- completion
- editor
- explorer
- terminal
- git
- telescope
- language tooling
- AI assistant integrations

That structure keeps the package understandable at the feature level. A contributor changing completion, Git, or UI behavior should only need to inspect the matching plugin file instead of tracing one monolithic setup script.

## Language Tooling Pattern

`lua/plugins/language.lua` is intentionally configuration-driven. It centralizes:

- Treesitter parser lists
- formatter mappings
- linter mappings
- LSP server metadata used by Mason and `lspconfig`

This keeps language additions declarative and avoids scattering formatter, linter, and LSP changes across unrelated plugin files.

## Operational Commands

- `:Lazy` for plugin status and management
- `:Mason` for LSP and tool installation status
- `:LspInfo` for active LSP clients
- `:Lazy health` and `:checkhealth` for diagnostics

## Editing Rules

- Keep plugin specs modular and lazily loaded where possible.
- Update `lazy-lock.json` only when plugin versions intentionally change.
- When package bootstrap behavior changes, keep post-install scripts and docs aligned.
