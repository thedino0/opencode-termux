# OpenCode v2 for Android Termux (`aarch64` / `glibc`)

Run the official **[OpenCode v2](https://github.com/anomalyco/opencode)** (`v2.2.5+`) natively on **any `aarch64` Android device** in Termux using Termux's `glibc` runtime — complete with an in-place ELF `PT_INTERP` patcher (so the v2 background server daemon works out-of-the-box), **8 true-black AMOLED themes**, a **day/night Termux + OpenCode theme switcher**, and a **1,000,000 token context window** configuration for **DeepSeek V4.1 Flash Free**.

---

## ✨ Features

- **Native `glibc` Execution (No Proot / No Proxy Overhead):** Runs the official `opencode-linux-arm64` release directly via Termux's `ld-linux-aarch64.so.1` without `proot` slowdown or local HTTP proxy latency.
- **In-Place ELF64 `PT_INTERP` Patcher (`scripts/patch-interp.js`):** Standard `patchelf --set-interpreter` shifts ELF sections and corrupts standalone Bun binaries (`SIGSEGV`). Our patcher writes the Termux `glibc` interpreter path into existing segment alignment padding at the end of `PT_LOAD[0]` without moving a single byte.
- **Working OpenCode v2 Background Server (`opencode serve --service`):** Because the kernel executes `opencode.bin` directly via its patched `PT_INTERP`, `/proc/self/exe` (`process.execPath`) resolves to `opencode.bin` instead of `ld-linux-aarch64.so.1`, fixing `Server process exited with code 127 (serve: cannot open shared object file)`.
- **Clean Child Process Execution (`git`, `rg`, `bash`, `less`):** Avoids exporting `LD_LIBRARY_PATH` so native Android/Bionic Termux binaries never collide with `glibc`'s `libc.so`.
- **8 True-Black (`#000000`) AMOLED Themes + `theme` CLI:** Ships all 8 native OpenCode v2 AMOLED themes and the `theme` / `theme-sync.sh` CLI helper from [DEAD1nsane/opencode2-termux-musl](https://github.com/DEAD1nsane/opencode2-termux-musl).
- **1M Context Window Config:** Preconfigured `config/opencode.jsonc` unlocking a `1,000,000` token context window for `opencode/deepseek-v4.1-flash-free`.

---

## 📱 Full Setup on Any Android Device (Termux)

### Prerequisites
1. Install **[Termux](https://github.com/termux/termux-app/releases)** (F-Droid or GitHub release — **do not** use the outdated Play Store build) on any 64-bit (`aarch64`) Android device.
2. *(Optional)* Install **[Termux:API](https://github.com/termux/termux-api/releases)** if you want automatic 15-minute day/night theme scheduling (`theme auto`).

### Step 1: Update Termux & Clone This Repository
Open Termux and run:

```bash
pkg update && pkg upgrade -y
pkg install -y git curl
git clone https://github.com/adity-a0/opencode-termux.git ~/opencode-termux
cd ~/opencode-termux
```

### Step 2: Run the Automated Installer
```bash
bash install.sh
```

What `install.sh` does automatically:
1. Installs `glibc-repo` and `glibc-runner` (`ld-linux-aarch64.so.1`), `which`, `ripgrep`, `nodejs`, `python`, `curl`, and `tar`.
2. Downloads the latest OpenCode v2 release from `https://opencode.ai/v2/install`.
3. Moves the binary to `~/.opencode/bin/opencode.bin` and runs `node scripts/patch-interp.js` to patch `PT_INTERP` in-place.
4. Installs the Termux launcher wrapper at `~/.opencode/bin/opencode` and symlinks `$PREFIX/bin/opencode`.
5. Installs all 8 AMOLED themes into `~/.config/opencode/themes/`, Termux dark/light 16-color ANSI palettes into `~/.termux/`, the `theme` CLI into `$PREFIX/bin/theme`, and default configs (`opencode.jsonc`, `cli.json`).

### Step 3: Launch OpenCode
```bash
opencode --version
cd /path/to/your/project
opencode
```

---

## 🎨 Themes & Day/Night Switching (`theme`)

Inside the OpenCode TUI, run `/themes` to choose from the 8 installed AMOLED themes:

| # | Theme Name | Accent | File |
| :--- | :--- | :--- | :--- |
| 1 | `1-rbw-amoled` | Red `#ff2740` | [`themes/1-rbw-amoled.json`](themes/1-rbw-amoled.json) |
| 2 | `2-obw-amoled` | Orange `#FF914A` | [`themes/2-obw-amoled.json`](themes/2-obw-amoled.json) |
| 3 | `3-ybw-amoled` | Yellow `#FFFF4B` | [`themes/3-ybw-amoled.json`](themes/3-ybw-amoled.json) |
| 4 | `4-gbw-amoled` | Green `#00FF7A` | [`themes/4-gbw-amoled.json`](themes/4-gbw-amoled.json) |
| 5 | `5-bbw-amoled` | Blue `#0090FF` | [`themes/5-bbw-amoled.json`](themes/5-bbw-amoled.json) |
| 6 | `6-vbw-amoled` | Violet `#6F66FF` | [`themes/6-vbw-amoled.json`](themes/6-vbw-amoled.json) |
| 7 | `7-pbw-amoled` | Pink `#FF60F8` | [`themes/7-pbw-amoled.json`](themes/7-pbw-amoled.json) |
| 8 | `8-rainbow-amoled` | Full Neon Multi | [`themes/8-rainbow-amoled.json`](themes/8-rainbow-amoled.json) |

From your Termux shell, use the `theme` command to switch both OpenCode and Termux's terminal palette together:

```bash
theme status          # One-glance summary of OpenCode + Termux theme state
theme dark            # Force dark mode (#000000 bg + dark 16-color ANSI palette)
theme light           # Force light mode (#ffffff bg + light 16-color ANSI palette)
theme termux light    # Flip only the Termux terminal palette (leave OpenCode untouched)
theme termux dark     # Flip Termux terminal palette back to pure black
theme auto            # Enable 07:00-19:00 automatic day/night switching via Termux:API
```

---

## 🧠 1,000,000 Context Window Configuration

[`config/opencode.jsonc`](config/opencode.jsonc) configures `opencode/deepseek-v4.1-flash-free` with a `1,000,000` token context window while keeping `output` at `32,000` (giving `968,000` usable input tokens before compaction):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "opencode": {
      "models": {
        "deepseek-v4.1-flash-free": {
          "limit": {
            "context": 1000000,
            "output": 32000
          }
        }
      }
    }
  }
}
```

---

## 🙏 Credits & Acknowledgements

- **[anomalyco/opencode](https://github.com/anomalyco/opencode)** — The official OpenCode AI coding agent and CLI.
- **[DEAD1nsane/opencode2-termux-musl](https://github.com/DEAD1nsane/opencode2-termux-musl)** ([**@DEAD1nsane**](https://github.com/DEAD1nsane)) — Creator of the 8 true-black AMOLED v2 themes (`themes/*.json`) and the `theme` / `theme-sync.sh` Termux day/night palette switching scripts included in this repository.
- **[guysoft/opencode-termux](https://github.com/guysoft/opencode-termux)** ([**@guysoft**](https://github.com/guysoft)) — Early Termux packaging inspiration for OpenCode.
- **[termux-pacman/glibc-packages](https://github.com/termux-pacman/glibc-packages)** — Termux `glibc` runtime (`ld-linux-aarch64.so.1`) used to run the upstream Linux `arm64` build natively.

---

## 📄 License

[MIT](LICENSE)
