# Packages Overview

This overview defines the shared conventions for repo-managed assets under `packages/` and the package guides under `docs/packages/`.

Package guides are current configuration references. They explain how a package is configured now, how the files are deployed or loaded, and how the package participates in the maintained `bootstrap -> install -> stow -> post` model.

## Documentation Boundary

`docs/packages/<package>.md` should contain:

- current design and configuration model
- key decisions and package layout
- lifecycle integration across install lists, pre-install rules, Dotter deployment, and post hooks
- runtime assumptions and package-specific troubleshooting
- concise validation notes for the edited package

`docs/packages/` should not contain execution plans, status logs, staged implementation instructions, task queues, release projections, or retrospectives. Put those artifacts under `plans/`.

Every package guide must include a `Lifecycle Integration` section, or an equivalent section with the same facts, that states:

- whether the package appears in `packages/packages.list` or `packages/container.list`
- whether the package has a package-specific pre-install rule
- whether Dotter deploys the package and on which platform profile
- whether the package has a post hook

Keep package-local `README.md` files short. Durable package knowledge belongs in the matching guide under `docs/packages/`.

## Package Lists

| File | Purpose |
| --- | --- |
| `packages/packages.list` | Full desktop install list with optional `@platform` selectors |
| `packages/container.list` | Smaller container install list without platform selectors |

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

Unix currently uses the explicit rule library in `packages/pre-install-unix.sh`. Windows keeps its current pre-install preparation inside `script/install.ps1` before the main Scoop install loop.

Current package-specific Unix rules:

| Package key | Handler | Package guide |
| --- | --- | --- |
| `neovim` | `preinstall_neovim` | [nvim.md](nvim.md) |
| `starship` | `preinstall_starship` | [starship.md](starship.md) |

## Post Hooks

Per-tool post-install scripts live in `packages/post/`.

Rules for post hooks:

- name the script by CLI command, not by package-manager package name
- self-check the CLI first and exit `0` when the tool is absent
- keep hooks idempotent and emit `[post:<tool>]` logs

The post orchestrators run every discovered script; self-checking is the only filter. Shared execution rules stay here, and concrete hook behavior belongs in the matching package guide.

Current package-specific post hooks:

| Hook | Behavior owner |
| --- | --- |
| `packages/post/nvim.sh` | [nvim.md](nvim.md) |
| `packages/post/nvim.ps1` | [nvim.md](nvim.md) |
| `packages/post/tmux.sh` | [tmux.md](tmux.md) |

## Maintained Config Packages

Repo-managed config packages live under `packages/<name>/`. When adding or changing one:

1. update the install list if software installation should change
2. update Dotter mappings if deployed files should change
3. add a pre-install rule only when the package-manager path is insufficient
4. add a post hook only when work must happen after deployment
5. sync this overview when shared package conventions change
6. sync the matching package guide when configuration, lifecycle behavior, troubleshooting, or validation notes change
7. sync `README.md` and `docs/user-workflow.md` when the user-visible command surface changes

Treat package changes in terms of the user-workflow stage they affect: install, stow, or post.

Current package guides:

| Package | Guide | Workflow role |
| --- | --- | --- |
| `alacritty` | [alacritty.md](alacritty.md) | Dotter-managed terminal config; installed on macOS and Windows |
| `git` | [git.md](git.md) | Dotter-managed global Git config; installed on desktop and container profiles |
| `nvim` | [nvim.md](nvim.md) | Dotter-managed Neovim config with Unix pre-install and post hooks |
| `powershell` | [powershell.md](powershell.md) | Dotter-managed Windows PowerShell profile |
| `starship` | [starship.md](starship.md) | Dotter-managed Starship symbol config with Unix pre-install support |
| `tmux` | [tmux.md](tmux.md) | Dotter-managed Unix tmux config with a post hook |
| `wezterm` | [wezterm.md](wezterm.md) | Dotter-managed terminal config; installed on macOS and Windows |
| `zellij` | [zellij.md](zellij.md) | Repo-maintained config that is not wired into install or Dotter |
| `zsh` | [zsh.md](zsh.md) | Dotter-managed Unix shell profile; installed on desktop and container profiles |
