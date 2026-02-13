# Debugging PowerShell Profile

This guide provides detailed instructions for verifying and debugging the modular PowerShell profile configuration.

## Quick Reference

| Task | Command |
|------|---------|
| **Test profile changes** | `pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"` |
| **Enable debug output** | `$env:PROFILE_DEBUG=1; pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"` |
| **Run diagnostic script** | `pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"` |
| **Verify module exports** | `pwsh -NoProfile -Command ". '$PWD\profile.d\05-utils.ps1'; . '$PWD\profile.d\XX-modulename.ps1'; Get-Command -CommandType Function \| Where-Object Source -eq '' \| Format-Table Name"` |
| **Check specific commands** | `Get-Command gitwt,dockerfexec,gits -ErrorAction SilentlyContinue \| Format-Table Name,CommandType` |
| **Disable debug mode** | `Remove-Item env:PROFILE_DEBUG` |


## Debug Mode

The profile loads silently by default. To see diagnostic output during loading:

**One-time debug session**:
```powershell
$env:PROFILE_DEBUG=1
pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"
```

**Persistent debug mode** (for current PowerShell session):
```powershell
$env:PROFILE_DEBUG=1
. $PROFILE
```

**Disable debug mode**:
```powershell
Remove-Item env:PROFILE_DEBUG
```

## Verifying Commands

After loading or modifying the profile, verify that commands are properly defined:

### Quick Verification
Check if specific commands exist:
```powershell
Get-Command gitwt,gitwts,dockerfexec,dockerfshell,gits,dockerps,dockercompose -ErrorAction SilentlyContinue | Format-Table Name,CommandType
```

### Comprehensive Test
Load profile and verify all commands in one step:
```powershell
pwsh -NoProfile -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'; Get-Command gitwt,gitwts,dockerfexec,dockerfshell,gits,dockerps,dockercompose -ErrorAction SilentlyContinue | Format-Table Name,CommandType"
```

### Using Diagnostic Script
Run the comprehensive diagnostic tool:
```powershell
pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"
```

This will check:
- Prerequisites (git, docker, fzf, starship)
- Module loading status
- Function availability
- Detailed error reporting

## Debugging Profile Issues

### Common Issues and Solutions

**Issue 1: Commands Not Loading**
- **Symptom**: Functions like `gitwt`, `dockerfexec`, `gits` are not available
- **Cause**: Module loading path incorrect or modules returning early from guard patterns
- **Solution**: Check that `$PSScriptRoot` is used (not `$PROFILE.CurrentUserAllHosts`) and prerequisites are installed

**Issue 2: Syntax Errors in Modules**
- **Symptom**: Module shows `[ERROR]` in diagnostic output
- **Cause**: PowerShell parsing errors (encoding issues, invalid syntax)
- **Solution**: Check error line number, verify encoding, simplify complex expressions

**Issue 3: Guard Patterns Blocking Load**
- **Symptom**: Module loads but functions are missing
- **Cause**: Prerequisites (git, docker, fzf) not in PATH
- **Solution**: Install missing tools or ensure they're in system PATH

### Debug Workflow

1. **Run Diagnostics**
   ```powershell
   pwsh -NoProfile -Command "& '$PWD\test\test-profile-commands.ps1'"
   ```

2. **Check Module Loading**
   Look for `[ERROR]` or `[MISSING]` indicators in output

3. **Verify Prerequisites**
   ```powershell
   where.exe git
   where.exe docker
   where.exe fzf
   ```

4. **Test Individual Module**
   ```powershell
   pwsh -NoProfile -Command ". '$PWD\profile.d\10-git.ps1'; Get-Command gitwt,gits -ErrorAction SilentlyContinue"
   ```

5. **Check Profile Path Resolution**
   Ensure modules are loaded from correct location:
   ```powershell
   pwsh -NoProfile -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'" # Should show correct Location
   ```

### Key Debugging Commands

**Test profile loading with output:**
```powershell
pwsh -NoProfile -NoExit -Command ". '$PWD\Microsoft.PowerShell_profile.ps1'"
```

**Check what functions were created:**
```powershell
Get-Command -CommandType Function | Where-Object Source -eq ''
```

**View profile loading errors:**
```powershell
$Error[0] | Format-List * -Force
```
