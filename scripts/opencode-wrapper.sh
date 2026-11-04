#!/data/data/com.termux/files/usr/bin/bash
# opencode-wrapper.sh — Termux launcher for patched OpenCode v2 glibc binary.
#
# - Unsets LD_PRELOAD so Android's Bionic libtermux-exec.so is not preloaded into glibc.
# - Does NOT export LD_LIBRARY_PATH so child Bionic processes (bash, git, rg, less)
#   continue to link cleanly against Android's /system/bin/linker64.
# - Sets Termux TMPDIR and SSL_CERT_FILE defaults.
# - Executes opencode.bin directly (via its patched PT_INTERP) so /proc/self/exe
#   (process.execPath) remains opencode.bin when spawning `opencode serve --service`.

unset LD_PRELOAD
export TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
export SSL_CERT_FILE="${SSL_CERT_FILE:-/data/data/com.termux/files/usr/etc/tls/cert.pem}"
exec "$HOME/.opencode/bin/opencode.bin" "$@"
