#!/data/data/com.termux/files/usr/bin/bash
# install.sh — Full automated setup & updater for OpenCode v2 on Android Termux (aarch64).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_DIR="$HOME/.opencode/bin"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

ARCH="$(uname -m)"
[ "$ARCH" = "aarch64" ] || die "Only aarch64 Android devices are supported (detected: $ARCH)."

log "Installing required Termux packages..."
pkg update -y
pkg install -y glibc-repo
pkg install -y glibc-runner which ripgrep nodejs python curl tar git

[ -f "$PREFIX/glibc/lib/ld-linux-aarch64.so.1" ] || die "glibc dynamic linker not found at $PREFIX/glibc/lib/ld-linux-aarch64.so.1"

log "Cleaning up any stale opencode binaries..."
rm -f "$PREFIX/bin/opencode" "$HOME/opencode.bin"
mkdir -p "$INSTALL_DIR"

log "Downloading latest OpenCode v2 release..."
curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path

log "Moving binary to $INSTALL_DIR/opencode.bin and patching PT_INTERP in-place..."
mv -f "$INSTALL_DIR/opencode" "$INSTALL_DIR/opencode.bin"
chmod +x "$INSTALL_DIR/opencode.bin"
node "$SCRIPT_DIR/scripts/patch-interp.js" "$INSTALL_DIR/opencode.bin" "$PREFIX/glibc/lib/ld-linux-aarch64.so.1"

log "Installing Termux glibc wrapper to $INSTALL_DIR/opencode..."
install -m 755 "$SCRIPT_DIR/scripts/opencode-wrapper.sh" "$INSTALL_DIR/opencode"
ln -sf "$INSTALL_DIR/opencode" "$PREFIX/bin/opencode"

if [ -d "$SCRIPT_DIR/themes" ]; then
  log "Installing 8 AMOLED themes to ~/.config/opencode/themes/..."
  mkdir -p "$HOME/.config/opencode/themes"
  cp -f "$SCRIPT_DIR/themes/"*.json "$HOME/.config/opencode/themes/"
fi

if [ -d "$SCRIPT_DIR/palettes" ]; then
  log "Installing Termux dark/light ANSI palettes to ~/.termux/..."
  mkdir -p "$HOME/.termux"
  cp -f "$SCRIPT_DIR/palettes/colors-dark.properties" "$HOME/.termux/colors-dark.properties"
  cp -f "$SCRIPT_DIR/palettes/colors-light.properties" "$HOME/.termux/colors-light.properties"
  [ -f "$HOME/.termux/colors.properties" ] || cp -f "$HOME/.termux/colors-dark.properties" "$HOME/.termux/colors.properties"
fi

if [ -f "$SCRIPT_DIR/scripts/theme" ] && [ -f "$SCRIPT_DIR/scripts/theme-sync.sh" ]; then
  log "Installing theme and theme-sync.sh helpers to $PREFIX/bin/theme..."
  mkdir -p "$PREFIX/libexec/opencode"
  install -m 700 "$SCRIPT_DIR/scripts/theme-sync.sh" "$PREFIX/libexec/opencode/theme-sync.sh"
  install -m 700 "$SCRIPT_DIR/scripts/theme" "$PREFIX/libexec/opencode/theme"
  ln -sf "$PREFIX/libexec/opencode/theme" "$PREFIX/bin/theme"
fi

if [ -d "$SCRIPT_DIR/config" ]; then
  mkdir -p "$HOME/.config/opencode"
  [ -f "$HOME/.config/opencode/opencode.jsonc" ] || cp -f "$SCRIPT_DIR/config/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
  [ -f "$HOME/.config/opencode/cli.json" ] || cp -f "$SCRIPT_DIR/config/cli.json" "$HOME/.config/opencode/cli.json"
fi

log "Restarting OpenCode background service..."
pkill -f "opencode.bin serve" 2>/dev/null || true
rm -f "$HOME/.local/state/opencode/service.json"

log "Verifying installation..."
"$PREFIX/bin/opencode" --version
log "Setup complete! Run 'opencode' to launch the TUI or 'theme status' to inspect themes."
