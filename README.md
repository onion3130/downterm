# downterm

> a quiet terminal wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → type `downterm` → press a number.**  
Minimal terminal UI. No window app.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

**Current:** `3.4.0`

---

## setup (recommended)

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
3. Press **`1`** for best video  

```
  1  paste · best video
  2  paste · pick quality
  3  paste · audio only
  4  history
  5  open folder
  6  setup tools (+ PATH)
  7  add to PATH only
  8  help
  9  quit
```

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
| **`setup.bat`** / **`setup.ps1`** | Windows setup (tools + PATH) |
| **`setup.sh`** | Linux/macOS setup (tools + PATH) |
| `downterm.cmd` / `downterm.ps1` | Command entrypoints |
| `install-path.ps1` | PATH add/remove helper |
| `download.bat` / `download.sh` | Terminal menu |
| `filter.ps1` / `filter.sh` | Progress bar + yt-dlp |

---

## releases

- **`3.4.0`** � Linux/macOS now report actionable HTTP, connection, ffmpeg, and deno error codes consistently with Windows

- **`3.3.0`** — `setup.bat` / `setup.ps1` / `setup.sh`; setup **always** installs PATH; manual PATH still available  
- **`3.2.0`** — first-run PATH offer; PowerShell entrypoint  
- **`3.1.x`** — terminal-only + PATH basics  

https://github.com/onion3130/downterm/releases

---

## license

MIT for downterm source. Third-party tools: see license files in the repo.
