#!/usr/bin/env bash
# dotfiles-bootstrap.sh (system paths, no DEST_BIN, no ~/.local/bin)
# Platforms: Linux (x86_64/arm64) & macOS (arm64)
# Policy:
#   - macOS: use Homebrew to install `just` and `dotter` (brew manages paths)
#   - Linux: `just` via official install script to /usr/local/bin/just
#            `dotter` via official binary downloaded to /usr/local/bin/dotter
#   - Linux requires root: this script will EXIT if not run as root (admin), since it writes to /usr/local/bin
# No generic DEST_BIN variables; paths are explicit per tool.
# Optional env:
#   DOTTER_VERSION  (e.g. v0.13.4; default: latest)
#   DOTTER_ASSET    (override exact filename, e.g. dotter-linux-x64-musl)
#   NO_SUDO=1       (do not attempt sudo when writing system paths)

set -euo pipefail
IFS=$'
	'

say(){ echo "$*"; }
ok(){ echo "✔ $*"; }
warn(){ echo "⚠ $*"; }
err(){ echo "✘ $*" 1>&2; }

have(){ command -v "$1" >/dev/null 2>&1; }

# Detect OS/ARCH (only combos upstream ships)
case "$(uname -s)" in
  Darwin) OS_FAMILY=macos ;;
  Linux)  OS_FAMILY=linux ;;
  *)      err "Unsupported OS"; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  ARCH_FAMILY=x64 ;;
  arm64|aarch64) ARCH_FAMILY=arm64 ;;
  *)             err "Unsupported arch"; exit 1 ;;
esac
ok "System: $OS_FAMILY, Arch: $ARCH_FAMILY"

# macos: ensure Homebrew is installed

# install just and dotter via Homebrew on macOS