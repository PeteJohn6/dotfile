#!/usr/bin/env zsh
# =============================================================================
# Zsh Profile Diagnostic Script
# =============================================================================
# Tests whether profile modules can load and which prerequisites are available.

setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
PROFILE_ROOT="${SCRIPT_DIR:h}"
PROFILE_PATH="${PROFILE_ROOT}/.zshrc"

typeset -a minimal_reasons=()
[[ "${TERM:-}" == "dumb" ]] && minimal_reasons+=("TERM=dumb")
[[ ! -o interactive ]] && minimal_reasons+=("non-interactive shell")
[[ ! -t 0 ]] && minimal_reasons+=("stdin is not a TTY")
[[ ! -t 1 ]] && minimal_reasons+=("stdout is not a TTY")

typeset expected_minimal=0
(( ${#minimal_reasons[@]} > 0 )) && expected_minimal=1

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
  if (( expected_minimal )) && [[ "${module_name:t}" == "07-starship.zsh" ]]; then
    print
    print "  Skipping: ${module_name:t}"
    print "    [SKIPPED] Requires a rich terminal session"
    continue
  fi

  print
  print "  Testing: ${module_name:t}"
  if ( source "$module_name" ); then
    print "    [OK] Module loaded without errors"
  else
    print "    [ERROR] Module failed to load"
    module_errors+=("${module_name:t}")
  fi
done

# === Check full profile behavior ===
print
print "[4] Checking Full Profile Behavior"
print "-------------------------------------------"

if [[ -f "$PROFILE_PATH" ]]; then
  PROFILE_DEBUG=1 source "$PROFILE_PATH"
else
  print "  [ERROR] Main profile not found at: $PROFILE_PATH"
fi

typeset -a expected_functions=(gitwt gitwts gitwtr gitco gits gitl)
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
if (( expected_minimal )); then
  print "  Session mode: minimal"
  print "  Skip reasons: ${(j:, :)minimal_reasons}"
else
  print "  Session mode: rich"
fi

for fn in "${expected_functions[@]}"; do
  if (( expected_minimal )); then
    if whence -w "$fn" >/dev/null 2>&1; then
      print "    [UNEXPECTED] ${fn} should not be defined in minimal mode"
    else
      print "    [OK] ${fn} not loaded in minimal mode"
    fi
  elif whence -w "$fn" >/dev/null 2>&1; then
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

if (( expected_minimal )); then
  print
  print "Profile Session Mode: minimal (${(j:, :)minimal_reasons})"
else
  print
  print "Profile Session Mode: rich"
fi

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
