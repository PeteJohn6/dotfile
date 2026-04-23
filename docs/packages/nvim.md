# Neovim Package

This guide explains the repo-managed Neovim package under `packages/nvim/`. It covers the file layout, configuration model, lifecycle hooks, and package-specific validation notes.

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
| `packages/post/nvim.sh` | Unix post hook for `lazy.nvim` bootstrap and plugin sync |
| `packages/post/nvim.ps1` | Windows post hook for `lazy.nvim` bootstrap and plugin sync |

## Configuration Model

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

`lua/plugins/language.lua` is intentionally configuration-driven. It centralizes Treesitter parser lists, formatter mappings, linter mappings, and LSP server metadata used by Mason and `lspconfig`.

## Lifecycle Integration

| Stage | Current behavior |
| --- | --- |
| Install list | `packages/packages.list` installs `neovim(nvim)`. `packages/container.list` also includes `neovim(nvim)`. |
| Pre-install | `packages/pre-install-unix.sh` maps `neovim` to `preinstall_neovim`. |
| Dotter deployment | Unix deploys `packages/nvim` to `~/.config/nvim`. Windows deploys it to `~/AppData/Local/nvim`. |
| Post hook | `packages/post/nvim.sh` and `packages/post/nvim.ps1` run Neovim headlessly and execute `Lazy! sync`. |

`preinstall_neovim` only handles apt-based Unix installs. It skips when the package manager is not `apt` or when `nvim` is already on `PATH`. When apt lacks a usable Neovim command, the handler downloads the stable Neovim tarball for `x86_64` or `arm64`, installs it under `INSTALL_OPT_DIR/neovim`, links `INSTALL_BIN_DIR/nvim`, and verifies the linked binary.

The post hooks self-check for `nvim`. If present, they run `nvim --headless +qa` to let the config bootstrap `lazy.nvim`, then run `nvim --headless "+Lazy! sync" +qa` to synchronize plugins.

## Operational Commands

- `:Lazy` for plugin status and management
- `:Mason` for LSP and tool installation status
- `:LspInfo` for active LSP clients
- `:Lazy health` and `:checkhealth` for diagnostics

## Editing Rules

- Keep plugin specs modular and lazily loaded where possible.
- Update `lazy-lock.json` only when plugin versions intentionally change.
- When package bootstrap behavior changes, keep post-install scripts and this guide aligned.

## Validation Notes

Use Lua syntax checks or a headless Neovim startup check for config changes. When plugin bootstrap behavior changes, run the matching post hook path for the target platform and confirm `Lazy! sync` completes.

## Common Failure Modes

- `lazy-lock.json` changes without an intentional plugin update.
- A plugin spec assumes a tool that Mason does not install or track.
- A formatter, linter, or LSP mapping is added outside `lua/plugins/language.lua`.
- Post hooks fail because Neovim starts interactively or because a plugin command is renamed.
