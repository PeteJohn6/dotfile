# Dotter Configuration Guide

This file provides detailed guidance on the dotter configuration system used in this dotfiles repository.

## Overview

Dotter is a dotfile manager and templater. It creates symbolic links from the repository to your home directory and supports platform-specific configurations through profiles.

**Official Documentation**: https://github.com/SuperCuber/dotter/wiki

## File Structure

```
.dotter/
|-- global.toml          # Main dotter configuration file
`-- CLAUDE.md            # This file - implementation guidance
```

## Configuration File: global.toml

The `global.toml` file defines:
1. **Helpers**: Template variables and functions
2. **Default**: Base configuration inherited by all profiles
3. **Profiles**: Platform-specific configurations (linux, macos, windows)
4. **Files**: Mappings between source files and deployment targets

## Profile System

### Platform Profiles

The repository supports three platform profiles:
- `[linux]` - Linux systems (uses `~/.config` for configuration)
- `[macos]` - macOS systems (uses `~/.config` for configuration)
- `[windows]` - Windows systems (uses `~/AppData/Local` for configuration)

### Profile Selection

Dotter automatically detects the platform, but you can override it:
```bash
dotter deploy -l linux    # Force Linux profile
dotter deploy -l macos    # Force macOS profile
dotter deploy -l windows  # Force Windows profile
```

## File Mappings

### Simple Mappings

For platform-agnostic files:
```toml
[files]
packages/git/.gitconfig = "~/.gitconfig"
```

This creates a symbolic link from `packages/git/.gitconfig` to `~/.gitconfig`.

### Platform-Specific Mappings

For files that need different paths per platform:

```toml
# First declare the file
[files.packages/nvim]
type = "symbolic"

# Then define platform-specific targets
[linux.files.packages/nvim]
target = "~/.config/nvim"

[macos.files.packages/nvim]
target = "~/.config/nvim"

[windows.files.packages/nvim]
target = "~/AppData/Local/nvim"
```

## Current Package Mappings

### Git Configuration
- **Source**: `packages/git/.gitconfig`
- **Target**: `~/.gitconfig` (all platforms)
- **Type**: Symbolic link

### Neovim Configuration
- **Source**: `packages/nvim/`
- **Targets**:
  - Linux/macOS: `~/.config/nvim`
  - Windows: `~/AppData/Local/nvim`
- **Type**: Symbolic link

## Adding New Packages

### Step 1: Create Package Directory

```bash
mkdir -p packages/new-package
```

### Step 2: Add Configuration Files

Place your dotfiles in the package directory:
```bash
packages/new-package/
|-- config.conf
`-- .somerc
```

### Step 3: Update global.toml

#### For Platform-Agnostic Files:

```toml
[files]
packages/new-package/.somerc = "~/.somerc"
```

#### For Platform-Specific Files:

```toml
# Declare the file
[files.packages/new-package]
type = "symbolic"

# Define platform-specific targets
[linux.files.packages/new-package]
target = "~/.config/new-package"

[macos.files.packages/new-package]
target = "~/.config/new-package"

[windows.files.packages/new-package]
target = "~/AppData/Local/new-package"
```

### Step 4: Test Deployment

```bash
# Dry run to verify
just dry
# or directly
dotter deploy --dry-run

# Deploy for real
just stow
# or directly
dotter deploy
```

## Link Types

### Symbolic Links (default)
```toml
[files.packages/example]
type = "symbolic"
target = "~/.config/example"
```

Creates a symlink. Changes to deployed files are reflected in the repository.

### Template Files
```toml
[files.packages/example/config.tmpl]
type = "template"
target = "~/.config/example/config"
```

Processes the file through dotter's template engine. Useful for platform-specific content.

## Common Operations

### Deploy Dotfiles
```bash
just stow              # via justfile
dotter deploy          # directly
```

### Dry Run (Preview Changes)
```bash
just dry               # via justfile
dotter deploy --dry-run # directly
```

### Undeploy Dotfiles
```bash
just uninstall         # via justfile
dotter undeploy --verbose # directly
```

### Check Configuration
```bash
dotter deploy --dry-run --verbose
```

## Template Variables

Define variables in the `[helpers]` section:
```toml
[helpers]
email = "user@example.com"
```

Use in template files:
```
git_email = {{ email }}
```

## Best Practices

1. **Test with dry-run first**: Always use `--dry-run` before actual deployment
2. **Use symbolic links**: Prefer symbolic links over copying for easier updates
3. **Platform-specific paths**: Use profile-specific targets for platform-dependent paths
4. **Keep packages isolated**: Each package should be self-contained in its directory
5. **Document custom helpers**: Add comments for any template helpers you define

## Troubleshooting

### Links Not Created
- Check file paths are relative to repository root
- Verify target directory exists (create parent dirs manually if needed)
- Check file permissions

### Wrong Platform Profile
- Explicitly specify profile: `dotter deploy -l <platform>`
- Check platform detection: `dotter --help` shows detected platform

### Template Errors
- Verify helper variables are defined in `[helpers]`
- Check template syntax: `{{ variable_name }}`
- Use `--verbose` flag for detailed error messages

## Integration with Justfile

The repository uses `just` to orchestrate dotter:
- `just dry` - Preview changes
- `just stow` - Deploy dotfiles
- `just uninstall` - Remove deployed dotfiles

See the justfile for implementation details.
