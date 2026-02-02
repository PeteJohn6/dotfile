# Dotfiles

Cross-platform dotfiles management system using `just` + `dotter` architecture.

## Features

- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Declarative**: Manage packages via simple text lists
- **Idempotent**: Safe to run repeatedly without side effects
- **Profile-Based**: Platform-specific configurations via dotter
- **Automated**: One command to set up everything

## Architecture

```
bootstrap.{sh,ps1}  →  just install  →  just stow  →  just post
     ↓                      ↓                ↓            ↓
  install just       parse lists/     dotter deploy   run post/
  install dotter     install pkgs     create symlinks  scripts
```

### Tools

1. **just** - Task runner for orchestrating the workflow
2. **dotter** - Dotfile deployment via symbolic links
3. **Platform package managers**:
   - Linux: apt/dnf/pacman
   - macOS: Homebrew
   - Windows: scoop

## Quick Start

### 1. Bootstrap Dependencies

**macOS/Linux:**
```bash
bash bootstrap/bootstrap.sh
```

**Windows (PowerShell as Administrator):**
```powershell
pwsh -NoProfile -File bootstrap/bootstrap.ps1
```

This installs `just` and `dotter` on your system.

### 2. Deploy Everything

```bash
just up
```

This runs the complete workflow:
- Installs packages from `lists/<platform>.list`
- Deploys dotfiles via dotter (creates symlinks)
- Runs post-installation scripts

## Usage

### Available Commands

```bash
just --list           # Show all available commands

# Individual steps
just install          # Install packages only
just dry              # Preview what dotter will link (dry-run)
just stow             # Deploy dotfiles (create symlinks)
just post             # Run post-installation scripts

# Complete workflow
just up               # Run: install → stow → post

# Cleanup
just uninstall        # Remove all deployed dotfiles
just cache            # Update dotter cache
```

### Adding Packages

Edit the appropriate list file:
- `lists/linux.list` - Packages for Linux (apt/dnf/pacman)
- `lists/macos.list` - Packages for macOS (Homebrew)
- `lists/windows.list` - Packages for Windows (scoop)

Format: one package per line, comments start with `#`

```bash
# Example: lists/linux.list
git
neovim
ripgrep  # fast grep alternative
```

Then run:
```bash
just install
```

### Adding Dotfiles

1. Create a directory in `packages/` for your tool (e.g., `packages/git/`)
2. Add configuration files to that directory
3. Configure mappings in `.dotter/global.toml`:

```toml
[files]
packages/git/.gitconfig = "~/.gitconfig"
packages/nvim = { target = "~/.config/nvim", type = "symbolic" }
```

4. Deploy:
```bash
just stow
```

### Post-Installation Scripts

Add scripts to `post/` for tasks that run after dotfiles are deployed:

**Unix (Linux/macOS):**
```bash
# post/nvim-plugins.sh
#!/usr/bin/env bash
set -euo pipefail
nvim --headless "+Lazy! sync" +qa
```

**Windows:**
```powershell
# post/nvim-plugins.ps1
#Requires -Version 7
nvim --headless "+Lazy! sync" +qa
```

Make scripts executable (Unix):
```bash
chmod +x post/nvim-plugins.sh
```

## Directory Structure

```
dotfiles/
├── bootstrap/           # Bootstrap scripts (install just + dotter)
│   ├── bootstrap.sh     # macOS/Linux
│   └── bootstrap.ps1    # Windows
├── install/             # Package installation scripts
│   ├── install-linux.sh
│   ├── install-macos.sh
│   └── install.ps1
├── lists/               # Package lists per platform
│   ├── linux.list
│   ├── macos.list
│   └── windows.list
├── packages/            # Dotfiles organized by tool
│   ├── git/
│   ├── nvim/
│   └── ...
├── post/                # Post-installation scripts
│   ├── post.sh          # Unix orchestrator
│   ├── post.ps1         # Windows orchestrator
│   └── *.{sh,ps1}       # Individual post scripts
├── .dotter/
│   ├── global.toml      # Dotter configuration
│   └── local.toml       # Machine-specific (git-ignored)
└── justfile             # Task orchestration
```

## Platform-Specific Notes

### Windows

- Use **scoop** for user-mode package installation (no admin needed after bootstrap)
- Run PowerShell scripts from repository root
- Windows Terminal recommended for best experience

### macOS

- Homebrew installation handled by bootstrap script
- Uses system-wide `/usr/local/bin` paths

### Linux

- Supports apt (Debian/Ubuntu), dnf (Fedora), pacman (Arch)
- Bootstrap requires root for installing to `/usr/local/bin`

## Development

### Guidelines

1. **Idempotency**: All scripts must be safe to run multiple times
2. **Error Handling**: Use strict mode (`set -euo pipefail` or `Set-StrictMode`)
3. **Cross-Platform**: Test on all supported platforms when possible
4. **Documentation**: Update `CLAUDE.md` for AI assistant context

### File Naming

- Unix scripts: `.sh` extension, executable (`chmod +x`)
- Windows scripts: `.ps1` extension
- Package lists: `.list` extension

## Troubleshooting

### "command not found: just"

Run the bootstrap script first to install dependencies.

### "dotter: not found"

Run the bootstrap script or install manually:
- macOS: `brew install dotter`
- Linux: See `bootstrap/bootstrap.sh` for installation steps
- Windows: `scoop install dotter`

### Symlinks not created

1. Check dotter configuration: `.dotter/global.toml`
2. Run dry-run to preview: `just dry`
3. Ensure packages directory exists with files

### Platform detection issues

dotter auto-detects your platform. To override, edit `.dotter/local.toml`:
```toml
packages = ["linux"]  # or "macos" or "windows"
```

## Contributing

1. Test changes on your platform
2. Update package lists as needed
3. Keep `CLAUDE.md` in sync with changes
4. Ensure scripts remain idempotent

## License

MIT

## Resources

- [just manual](https://just.systems/man/)
- [dotter wiki](https://github.com/SuperCuber/dotter/wiki)
- [scoop](https://scoop.sh/) (Windows)
- [Homebrew](https://brew.sh/) (macOS)
