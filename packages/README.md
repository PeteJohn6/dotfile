# Packages Directory

This directory contains dotfiles organized by tool/application.

## Structure

Each subdirectory represents a tool and contains its configuration files:

```
packages/
├── git/
│   └── .gitconfig
├── nvim/
│   ├── init.lua
│   └── lua/
└── zsh/
    └── .zshrc
```

## Usage

1. Create a directory for your tool (e.g., `git/`, `nvim/`)
2. Add configuration files to that directory
3. Configure mappings in `.dotter/global.toml`

## Examples

### Single File Mapping

For a single config file like `.gitconfig`:

**.dotter/global.toml:**
```toml
[files]
packages/git/.gitconfig = "~/.gitconfig"
```

### Directory Mapping

For a config directory like neovim:

**.dotter/global.toml:**
```toml
[files]
packages/nvim = { target = "~/.config/nvim", type = "symbolic" }
```

### Platform-Specific Mappings

Different paths for different platforms:

**.dotter/global.toml:**
```toml
[files.packages/nvim]
type = "symbolic"

[linux.files.packages/nvim]
target = "~/.config/nvim"

[macos.files.packages/nvim]
target = "~/.config/nvim"

[windows.files.packages/nvim]
target = "~/AppData/Local/nvim"
```

## Guidelines

1. **Keep it organized**: One directory per tool
2. **Include README**: Document tool-specific setup if needed
3. **Relative paths**: Use relative paths in dotter config
4. **Test mappings**: Use `just dry` to preview before deploying
5. **Git ignore**: Local overrides should go in `.dotter/local.toml` (git-ignored)

## Adding New Packages

1. Create directory: `mkdir packages/mytool`
2. Add config files: `cp ~/.mytoolrc packages/mytool/`
3. Update `.dotter/global.toml` with mapping
4. Test: `just dry`
5. Deploy: `just stow`
