#!/data/data/com.termux/files/usr/bin/bash
# opencode-wrapper.sh — Termux launcher for patched OpenCode v2 glibc binary.
#
# - Sets TERMUX_EXEC__EXECVE_CALL__INTERCEPT=disable and
#   TERMUX_EXEC__SYSTEM_LINKER_EXEC__MODE=disable BEFORE exec so that
#   libtermux-exec.so (already preloaded in the current bash process) does NOT
#   rewrite execve() into `/system/bin/linker64 opencode.bin`, which fails with:
#   `error: ".../opencode.bin" has unexpected e_type: 2` (ET_EXEC).
# - Unsets LD_PRELOAD so Android's Bionic libtermux-exec.so is not inherited by glibc.
# - Sets Termux TMPDIR and SSL_CERT_FILE defaults.
# - Executes opencode.bin directly (via its patched PT_INTERP), or falls back to
#   proot if the Android kernel SELinux policy blocks direct execve() on app_data_file.

export TERMUX_EXEC__EXECVE_CALL__INTERCEPT=disable
export TERMUX_EXEC__SYSTEM_LINKER_EXEC__MODE=disable
unset LD_PRELOAD
export TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
export SSL_CERT_FILE="${SSL_CERT_FILE:-/data/data/com.termux/files/usr/etc/tls/cert.pem}"

if [ "${OPENCODE_USE_PROOT:-0}" = "1" ]; then
  exec proot "$HOME/.opencode/bin/opencode.bin" "$@"
fi

exec "$HOME/.opencode/bin/opencode.bin" "$@"
