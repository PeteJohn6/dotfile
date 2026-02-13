#!/usr/bin/env zsh
# =============================================================================
# Zsh Profile Diagnostic Script
# =============================================================================
# Tests whether profile modules can load and which prerequisites are available.

setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
PROFILE_ROOT="${SCRIPT_DIR:h}"
PROFILE_PATH="${PROFILE_ROOT}/.zshrc"

print
print "========================================"
print "Zsh Profile Diagnostics"
print "========================================"
print

# === Check Prerequisites ===
print "[1] Checking Prerequisites"
print "-------------------------------------------"

typeset -a prerequisites=(git docker fzf starship)
typeset -A available
typeset cmd

for cmd in "${prerequisites[@]}"; do
  if (( $+commands[$cmd] )); then
    available[$cmd]=1
    print "  [OK] ${cmd} found at: ${commands[$cmd]}"
  else
    available[$cmd]=0
    print "  [MISSING] ${cmd} not found in PATH"
  fi
done

# === Test utility module ===
print
print "[2] Testing Utility Module"
print "-------------------------------------------"

typeset utils_path="${PROFILE_ROOT}/conf.d/05-utils.zsh"
if [[ -f "$utils_path" ]]; then
  if source "$utils_path"; then
    print "  [OK] 05-utils.zsh loaded successfully"
    if test_command zsh; then
      print "  [OK] test_command helper works"
    else
      print "  [ERROR] test_command helper returned unexpected result"
    fi
  else
    print "  [ERROR] Failed to load 05-utils.zsh"
  fi
else
  print "  [ERROR] 05-utils.zsh not found at: $utils_path"
fi

# === Test individual modules ===
print
print "[3] Testing Profile Modules"
print "-------------------------------------------"

typeset profile_dir="${PROFILE_ROOT}/conf.d"
typeset -a module_errors=()
typeset module_name

for module_name in "$profile_dir"/*.zsh(N); do
  print
  print "  Testing: ${module_name:t}"
  if ( source "$module_name" ); then
    print "    [OK] Module loaded without errors"
  else
    print "    [ERROR] Module failed to load"
    module_errors+=("${module_name:t}")
  fi
done

# === Check available functions ===
print
print "[4] Checking for Expected Functions"
print "-------------------------------------------"

if [[ -f "$PROFILE_PATH" ]]; then
  PROFILE_DEBUG=1 source "$PROFILE_PATH"
else
  print "  [ERROR] Main profile not found at: $PROFILE_PATH"
fi

typeset -a expected_functions=(gitwt gitwts gits gitl)
if [[ "${available[docker]:-0}" == "1" ]]; then
  expected_functions+=(
    dockerfshell
    dockerflogs
    dockerfrmi
    dockerfrm
    dockerfrun
    dockerfexec
  )
fi

typeset fn
for fn in "${expected_functions[@]}"; do
  if whence -w "$fn" >/dev/null 2>&1; then
    print "    [OK] ${fn}"
  else
    print "    [MISSING] ${fn}"
  fi
done

# === Summary ===
print
print "========================================"
print "Summary"
print "========================================"

typeset -a missing_prereqs=()
for cmd in "${prerequisites[@]}"; do
  if [[ "${available[$cmd]:-0}" != "1" ]]; then
    missing_prereqs+=("$cmd")
  fi
done

if (( ${#missing_prereqs[@]} > 0 )); then
  print
  print "Missing Prerequisites: ${(j:, :)missing_prereqs}"
  print "  -> This may prevent some profile modules from loading"
fi

if (( ${#module_errors[@]} > 0 )); then
  print
  print "Failed Modules: ${(j:, :)module_errors}"
fi

if (( ${#missing_prereqs[@]} == 0 && ${#module_errors[@]} == 0 )); then
  print
  print "All checks passed."
fi

print
print "========================================"
print
