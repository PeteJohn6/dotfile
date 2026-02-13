# CLAUDE.md

This file provides guidance when working with code in this repository.

## Overview

This is a modular PowerShell profile configuration repository. The profile is structured with a main entry point (`Microsoft.PowerShell_profile.ps1`) and a modular plugin system in `profile.d/` for organizing functionality by domain.

## You must strictly comply every time you run.

CRITICAL: Always execute `pwd` first. File operations are RESTRICTED to the current directory only.  
CRITICAL: Do not modify any files under `$PWD/test` unless explicitly authorized.
CRITICAL: Never access the `$PWD/.tree/` folder.

## Architecture

### Main Profile Entry Point
- **Microsoft.PowerShell_profile.ps1**: Initializes Starship prompt, loads the Chocolatey profile, and auto-loads all modules from `profile.d/` in alphabetical order.

### Module Loading System
Modules in `profile.d/` are loaded automatically in alphabetical order. Numeric prefixes (05-, 10-, 20-, etc.) control load order to handle dependencies.

### Key Design Patterns

**Conditional Loading**: Each domain module uses a guard pattern to exit early if the required tool is not available:
```powershell
if (-not (Test-Command docker)) { return }
```

**fzf Integration**: Interactive functions use fzf for fuzzy selection with preview panes showing relevant context (logs, git status, etc.).

**Completion Caching**: Docker completion is generated once and cached for 30 days in the `cache/` directory to improve startup performance.

## When adding a new module, you need:

1. Create a new `.ps1` file in `profile.d/` with an appropriate numeric prefix.
2. Add a guard pattern if the module requires external tools.
3. Follow the existing module structure with header comments.

## After adding or modifying code, you must:

1. Use `$PWD/test` to ensure there are no errors or warnings. Detailed test and debug instructions are provided in `$PWD/test/CLAUDE.md`.

2. Follow these steps to keep documentation synchronized:

   1. Synchronize `README.md` if any of the following changed:

      * function/alias names (renamed, added, or removed)
      * command descriptions
      * module prerequisites or dependencies
   2. Update the module’s command table in `README.md`:

      * locate the module’s section (e.g., “### Git Module”, “### Docker Module”)
      * update the command table to match the actual functions/aliases in the code
      * ensure descriptions accurately reflect functionality

### Quick way to inspect loaded modules

```powershell
# List all functions exported by a module
pwsh -NoProfile -Command ". '$PWD\profile.d\05-utils.ps1'; . '$PWD\profile.d\XX-modulename.ps1'; Get-Command -CommandType Function | Where-Object Source -eq '' | Format-Table Name"
```

Note: Replace `XX-modulename.ps1` with your target module file.

### Example scenarios requiring `README.md` updates:

* Renaming functions (e.g., `dkr-shell` → `dockerfshell`)
* Removing alias functions (e.g., consolidating an old alias into the main `docker*` function)
* Adding new interactive commands to existing modules
* Changing function signatures in a way that affects usage
