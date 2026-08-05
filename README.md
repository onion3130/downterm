# downterm

> a quiet terminal wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → run `downterm` → press a number.**  
Minimal terminal UI. No window app. No flag soup.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

**Current:** `3.1.1`

---

## type `downterm` anywhere (PATH)

After a one-time install, **any new terminal** can launch downterm by typing:

```bat
downterm
```

### Windows

1. Open the downterm folder and run `download.bat` once  
2. Press **`7`** — *add to PATH*  
   · or double-click / run: `download.bat --install`  
3. **Close that terminal and open a new one** (PATH updates apply to new sessions)  
4. Type:

```bat
downterm
```

What this does:
- Ensures `downterm.cmd` exists in the downterm folder  
- Adds **that folder** to your **user PATH**  
- New cmd/PowerShell windows resolve `downterm` → terminal menu  

Undo:

```bat
download.bat --uninstall
```

### Linux / macOS

```bash
chmod +x download.sh filter.sh
./download.sh --install
# or press 7 in the menu
```

Then open a **new** shell and run:

```bash
downterm
```

This links `~/.local/bin/downterm` → `download.sh`.  
If the command is not found, add to `~/.bashrc` / `~/.zshrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## everyday use

1. In your browser, **copy** a video link  
2. Type **`downterm`** (or run `download.bat` / `./download.sh`)  
3. Press **`1`** → best video downloads  

```
  downterm  3.1.1
  ..........................................

  copy a link, then pick a number.

  1  paste · best video
  2  paste · pick quality
  3  paste · audio only
  4  history
  5  open folder
  6  setup tools
  7  add to PATH  →  type  downterm  anywhere
  8  help
  9  quit
```

---

## setup (yt-dlp / ffmpeg)

Press **`6`** or run `download.bat --setup` to fetch pinned tools (see `bin/checksums.txt`).  
On Linux, install **ffmpeg** with your package manager if needed.

---

## files

| file | role |
|------|------|
| **`downterm.cmd`** | Windows command name (`downterm`) |
| `install-path.ps1` | Adds/removes this folder on user PATH |
| `download.bat` | Terminal UI (Windows) |
| `download.sh` | Terminal UI (Linux/macOS) |
| `filter.ps1` / `filter.sh` | Progress bar + yt-dlp |

---

## releases

- **`3.1.1`** — PATH install polish + README: type **`downterm`** anywhere  
- **`3.1.0`** — terminal-only; removed window GUI; first PATH install  
- `2.x` — older prompt/GUI experiments  

https://github.com/onion3130/downterm/releases

---

## license

MIT for downterm source. Third-party tool licenses: see license files in the repo.

---

made with too much time and a terminal.
