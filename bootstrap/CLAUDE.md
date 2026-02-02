**Bootstrap Workflow**:
1. Detect the current platform (Linux/macOS/Windows)
2. Check if package manager is installed; install if missing:
   - Linux: Uses system package manager (apt/dnf/pacman) - already present
   - macOS: Installs Homebrew if not present
   - Windows: Installs Scoop (user-mode, no admin required)
3. Use package manager to install `just` and `dotter`
4. Bootstrap is complete - hand off to `just` for remaining setup

**Files**:
- `bootstrap/bootstrap-linux.sh` - Linux bootstrap
- `bootstrap/bootstrap-macos.sh` - macOS bootstrap (installs Homebrew)
- `bootstrap/bootstrap.ps1` - Windows bootstrap (installs Scoop)

**Usage**:
```bash
# Linux
./bootstrap/bootstrap-linux.sh

# macOS
./bootstrap/bootstrap-macos.sh

# Windows (PowerShell)
.\bootstrap\bootstrap.ps1
```
