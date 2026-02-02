# Install Scripts

This directory contains platform-specific installation scripts that read package lists and install software using the appropriate package manager.

**Common Patterns**:
1. Detect platform (Linux/macOS/Windows)
2. Read corresponding `.list` file from `lists/` directory
3. Parse file (skip comments, trim whitespace)
4. Install packages using appropriate package manager
5. Log progress and handle errors

**Naming Convention**:
- `script/install/install-linux.sh` - Linux installer (apt/dnf/pacman)
- `script/install/install-macos.sh` - macOS installer (Homebrew)
- `script/install/install.ps1` - Windows installer (winget/scoop/chocolatey)

**Implementation Notes**:
- Must be idempotent - safe to run multiple times
- Should check if package is already installed before installing
- Should continue on individual package failures (don't fail entire script)
- Should provide clear progress output


## Available Scripts

- `install-linux.sh` - Linux installation script (apt/dnf/pacman)
- `install-macos.sh` - macOS installation script (Homebrew)
- `install.ps1` - Windows installation script (winget/scoop/chocolatey)

## Purpose

Install scripts perform the following tasks:
1. Detect the current platform
2. Read the corresponding package list from `lists/<platform>.list`
3. Parse the list file (skip comments, handle whitespace)
4. Install packages using the platform's package manager
5. Log progress and handle errors gracefully

## Invocation

These scripts are invoked by the `just install` command. They should not typically be run directly, but can be for testing:

```bash
# Linux
./script/install/install-linux.sh

# macOS
./script/install/install-macos.sh

# Windows (PowerShell)
.\script\install\install.ps1
```

## Implementation Requirements

All install scripts must:
- Be idempotent (safe to run multiple times)
- Check if packages are already installed before attempting installation
- Handle individual package failures gracefully (don't fail entire script)
- Provide clear progress output
- Exit with appropriate status codes

## Package Lists

Package lists are read from:
- `lists/linux.list` - Linux packages
- `lists/macos.list` - macOS packages
- `lists/windows.list` - Windows packages

See the main CLAUDE.md for package list format specification.
