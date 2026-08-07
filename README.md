# downterm

> a quiet terminal wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → type `downterm` → press a number.**  
Minimal terminal UI. No window app. No Electron. Nothing to configure.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Current:** `4.1.0`

---

## install in one line (no git, no clone)

| | |
|--|--|
| **Windows** (PowerShell) | `irm https://raw.githubusercontent.com/onion3130/downterm/main/install.ps1 \| iex` |
| **Linux / macOS** | `curl -fsSL https://raw.githubusercontent.com/onion3130/downterm/main/install.sh \| bash` |

<details>
<summary>see the one-liners with copy buttons</summary>

**Windows** — PowerShell:
```powershell
irm https://raw.githubusercontent.com/onion3130/downterm/main/install.ps1 | iex
```

**Linux / macOS** — shell:
```bash
curl -fsSL https://raw.githubusercontent.com/onion3130/downterm/main/install.sh | bash
```

</details>

The installer pulls the latest release, fetches verified `yt-dlp`/`ffmpeg`/`deno`
(a SHA-256-checked setup), and puts `downterm` on PATH. Open a **new** terminal and type `downterm`.

### manual setup

### Windows

1. Download / clone this repo  
2. Double-click **`setup.bat`**  
   · or in PowerShell from the folder:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1
```

3. Close that window  
4. Open a **new** PowerShell or cmd  
5. Type:

```powershell
downterm
```

**What `setup.bat` does**
- Downloads missing tools (`yt-dlp`, `ffmpeg`, `deno`) when needed  
- **Always adds this folder to your user PATH**  
- Writes `downterm.cmd` + `downterm.ps1` so the `downterm` command works  

### Linux / macOS

```bash
chmod +x setup.sh download.sh filter.sh
./setup.sh
# new terminal:
downterm
```

**What `setup.sh` does**
- Fetches `yt-dlp` (and deno when possible)  
- Reminds you to install `ffmpeg` via your package manager if missing  
- **Always links** `~/.local/bin/downterm`  

If `downterm` is not found after setup:

```bash
export PATH="$HOME/.local/bin:$PATH"
# add that line to ~/.bashrc or ~/.zshrc for permanence
```

---

## manual PATH install (always available)

You can add PATH **without** re-fetching tools anytime:

| | Windows | Linux / macOS |
|--|---------|----------------|
| Script | `setup.bat -PathOnly` | `./setup.sh --path-only` |
| App flag | `download.bat --install` | `./download.sh --install` |
| In menu | press **`7`** | press **`7`** |

Undo PATH:

```bat
download.bat --uninstall
```

```bash
./download.sh --uninstall
```

---

## everyday use

1. **Copy** a video link in the browser  
2. Type **`downterm`**  
3. Press **`1`**  
4. **Paste** the link (Enter to use the clipboard)

```
  1  best video
  2  pick quality
  3  audio only
  4  history
  5  open folder
  6  setup tools (+ PATH)
  7  add to PATH only
  8  help
  9  quit
  0  playlist · pick items
```

### what's built in (v4.1)

- **Real self-update** — `downterm --update` now downloads and replaces the wrapper scripts when a newer release exists (not just a link)
- **Dumb-terminal safe** — colors turn off automatically with `NO_COLOR`, `TERM=dumb`, or piped output
- **Playlist picker** — press `0`, paste a playlist, choose `all` / `1-3` / `2,5,7`
- **Cookies** — restricted content: `downterm --cookies=cookies.txt` (or `COOKIES=` in `downterm.conf`)
- **Audio formats** — option `3` picks `mp3` / `m4a` / `opus` / `wav`; also `--audio-format=flac|aac`
- **Metadata** — title + thumbnail are embedded by default (`--no-embed` to skip)
- **Quiet progress bar** — speed + ETA, one line, no spam

### options

| flag | meaning |
|------|---------|
| `--version` | print version |
| `--update` | refresh yt-dlp + check for a newer downterm |
| `--install` / `--uninstall` | add / remove PATH entry |
| `--cookies=FILE` | browser cookies for restricted content |
| `--audio-format=mp3` | default audio container (`mp3` \| `m4a` \| `opus` \| `wav` \| `flac` \| `aac`) |
| `--no-embed` | skip embedding title + thumbnail |

Or set permanent defaults in **`downterm.conf`** (see `downterm.conf.example`).

---

## setup script options

### Windows (`setup.ps1` / `setup.bat`)

| Flag | Meaning |
|------|---------|
| *(none)* | tools if needed **+ PATH** (default) |
| `-PathOnly` | **PATH only** (manual re-install) |
| `-SkipPath` | tools only, no PATH |
| `-ForceTools` | re-download tools even if present |

### Linux / macOS (`setup.sh`)

| Flag | Meaning |
|------|---------|
| *(none)* | tools if needed **+ PATH** (default) |
| `--path-only` | **PATH only** |
| `--skip-path` | tools only |
| `--force-tools` | re-fetch tools |

---

## files

| file | role |
|------|------|
| `install.ps1` / `install.sh` | one-line installers (used by the commands at the top) |
| **`setup.bat`** / **`setup.ps1`** | Windows setup (tools + PATH) |
| **`setup.sh`** | Linux/macOS setup (tools + PATH) |
| `downterm.cmd` / `downterm.ps1` | Command entrypoints |
| `install-path.ps1` | PATH add/remove helper |
| `download.bat` / `download.sh` | Terminal menu |
| `filter.ps1` / `filter.sh` | Progress bar + yt-dlp + error codes |

---

## releases

- **`4.1.0`** — **real self-update** (downloads + replaces wrappers, not just a message); **paste-prompt** for links with clipboard as Enter-default; **`NO_COLOR` / `TERM=dumb` / piped** output support; non-interactive `--setup` (CI-safe); CI timeout guards

- **`4.0.0`** — one-line installers; **playlist picker** (option `0`); **cookies** (`--cookies=…`); **audio formats** (`m4a`/`opus`/`wav`); **embed title + thumbnail** by default (`--no-embed`); **self-update check** (`--update`, pin-verified yt-dlp); `ERR-14` for missing cookie files

- **`3.4.0`** — Linux/macOS now report actionable HTTP, connection, ffmpeg, and deno error codes consistently with Windows

- **`3.3.0`** — `setup.bat` / `setup.ps1` / `setup.sh`; setup **always** installs PATH; manual PATH still available  
- **`3.2.0`** — first-run PATH offer; PowerShell entrypoint  
- **`3.1.x`** — terminal-only + PATH basics  

https://github.com/onion3130/downterm/releases

---

## license

MIT for downterm source. Third-party tools: see license files in the repo.
