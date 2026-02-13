# Dotter Configuration Guide

This file provides detailed guidance on the dotter configuration system used in this dotfiles repository.

## Overview

Dotter is a dotfile manager and templater. It creates symbolic links from the repository to your home directory and supports platform-specific configurations through profiles.

**Official Documentation**: https://github.com/SuperCuber/dotter/wiki

## File Structure

```
.dotter/
├── global.toml          # Base package definitions
├── default/             # Default local.toml templates
|     ├── windows.toml   # Default Windows local file
|     ├── unix.toml      # Default Unix local file
|     \── container.toml # Default container local file
├── windows.toml         # Windows-specific configuration 
├── unix.toml            # Unix-specific configuration
├── local.toml           # User-specific configuration read by dotter. On new environments, initially copied from default/ by bootstrap script according to platform. Modify this file for customization.
└── CLAUDE.md            # This file - implementation guidance
```

## Configuration File: global.toml

The `global.toml` file defines:
1. **Helpers**: Template variables and functions
2. **Default**: Base configuration inherited by all profiles
3. **Profiles**: Platform-specific configurations (linux, macos, windows)
4. **Files**: Mappings between source files and deployment targets

## Platform-Specific Configuration with Includes

Dotter supports platform-specific configuration through an include system where local.toml can include platform-specific configuration files.

### Configuration Structure
```
.dotter/
├── global.toml          # Base package definitions (loaded by dotter automatically)
├── windows.toml         # Windows-specific package overrides
├── unix.toml            # Unix-specific package overrides
└── local.toml           # User config: includes platform file + defines packages
└── local.toml.example   # Template
```

### Configuration Hierarchy

```
global.toml (loaded automatically by dotter)
  ↓ merged with
local.toml (defines packages, includes platform file)
  ↓ includes
windows.toml or unix.toml (platform-specific overrides)
```

**Important Notes:**
- `global.toml` is always loaded automatically by dotter
- `local.toml` must define the `packages` key
- Included files (windows.toml, unix.toml) should NOT define `packages` - they only patch package configurations
- Included files override settings from global.toml
- local.toml settings override everything

### Using Platform-Specific Configuration

1. Copy one of file in `default/` to local.toml:
```bash
cp .dotter/default/windwos.toml .dotter/local.toml
```

2. Edit local.toml and uncomment the appropriate include:
```toml
# For Windows:
includes = [".dotter/windows.toml"]

# For Linux/macOS:
includes = [".dotter/unix.toml"]

packages = ["git", "nvim"]
```

3. Deploy:
```bash
just stow
# or directly:
dotter deploy
```

### How Includes Work

When you run `dotter deploy`, dotter:
1. Automatically loads `global.toml` (defines all packages)
2. Loads `local.toml` (defines which packages to use)
3. Merges in each included file from local.toml in order
4. Included files can override package settings from global.toml
5. Deploys the merged configuration

**Configuration Flow:**

```
global.toml (always loaded):
  [nvim]
  depends = []

  [nvim.files]
  "packages/nvim" = "~/.config/nvim"  # Default

local.toml:
  includes = [".dotter/windows.toml"]  # On Windows
  packages = ["git", "nvim"]

windows.toml (included and merged):
  [nvim.files]
  "packages/nvim" = "~/AppData/Local/nvim"  # Overrides global

Result on Windows: packages/nvim → ~/AppData/Local/nvim
Result on Unix (with unix.toml): packages/nvim → ~/.config/nvim
```

## File Mappings

### Simple Mappings

For platform-agnostic files:
```toml
[git]
depends = []

[git.files]
"packages/git/.gitconfig" = "~/.gitconfig"
"packages/git/.gitignore_global" = "~/.gitignore_global"
```

This creates symbolic links from the package files to their target locations.

### Platform-Specific Mappings

For files that need different paths per platform, use platform files to override the global configuration:

**In global.toml** (platform-agnostic default, auto-loaded):
```toml
[nvim]
depends = []

[nvim.files]
"packages/nvim" = "~/.config/nvim"  # Default Unix path
```

**In unix.toml** (included from local.toml):
```toml
# Override settings for Unix platforms

[nvim.files]
"packages/nvim" = "~/.config/nvim"
```

**In windows.toml** (included from local.toml):
```toml
# Override settings for Windows
# Note: Do NOT define 'packages' here

[nvim.files]
"packages/nvim" = "~/AppData/Local/nvim"
```
### Key Concepts

**Includes-Based Approach:**
- global.toml defines all packages with default settings (auto-loaded)
- local.toml specifies which packages to use and which platform file to include
- Platform files (windows.toml, unix.toml) patch package settings for each platform
- Single package (`nvim`) works on all platforms
- Platform-specific configuration is cleanly separated

**Why Use Includes:**
- Clean separation of platform-specific logic
- global.toml stays platform-agnostic
- Platform files only define overrides, not full package definitions
- Follows dotter's include pattern
- No duplicate package definitions in global.toml
- Easy to add new platforms (WSL, BSD, etc.)

**File Deployment:**
- Dotter recursively deploys files from directories by default
- Individual files within `packages/nvim/` are symlinked to their targets
- The end result is functionally equivalent to a directory symlink

### Setup Steps

1. Copy and edit local.toml:
   ```bash
   cp .dotter/default/windows.toml .dotter/local.toml
   ```

2. Edit local.toml to adjust packages if need:
   ```toml
   packages = ["git", "nvim"]
   ```

3. Preview deployment:
   ```bash
   just dry
   # or directly:
   dotter deploy --dry-run
   ```

4. Verify platform-specific behavior:
   - **Windows**: Should show `packages/nvim/init.lua -> ~/AppData/Local/nvim/init.lua`
   - **Linux/macOS**: Should show `packages/nvim/init.lua -> ~/.config/nvim/init.lua`

5. Deploy dotfiles:
   ```bash
   just stow
   # or directly:
   dotter deploy
   ```

### Verification

Check that configuration files were deployed:

**On Windows (PowerShell):**
```powershell
Get-Item ~/AppData/Local/nvim/init.lua
```

**On Linux/macOS:**
```bash
ls -la ~/.config/nvim/init.lua
```

Test Neovim configuration:
```bash
nvim --version
nvim -c "echo stdpath('config')" -c "quit"
```

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
[new-package]
depends = []

[new-package.files]
"packages/new-package/.somerc" = "~/.somerc"
```

#### For Platform-Specific Files:

```toml
# Declare the package
[new-package]
depends = []

# Define default file mapping
[new-package.files]
"packages/new-package" = { type = "symbolic", target = "~/.config/new-package" }

# Override for Windows with different path
[windows.new-package.files]
"packages/new-package" = { type = "symbolic", target = "~/AppData/Local/new-package" }
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
[example]
depends = []

[example.files]
"packages/example/config" = "~/.config/example/config"
```

Creates a symlink by default. Changes to deployed files are reflected in the repository.

### Explicit Symbolic Links
```toml
[example.files]
"packages/example" = { type = "symbolic", target = "~/.config/example" }
```

Explicitly specify symbolic link type when needed (e.g., for directories).

### Template Files
```toml
[example.files]
"packages/example/config.tmpl" = { type = "template", target = "~/.config/example/config" }
```

Processes the file through dotter's template engine. Useful for platform-specific content.

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
