# downterm

> a quiet terminal wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → run `downterm` → press a number.**  
Minimal terminal UI. No window app.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

**Current:** `3.2.0`

---

## type `downterm` in PowerShell / cmd

### One-time setup (Windows)

1. Open the downterm folder and run **`download.bat`**  
2. On first launch, choose **Y** when asked to add PATH  
   · or press **`7`** in the menu  
   · or run: `download.bat --install`  
3. **Close that window completely**  
4. Open a **new** PowerShell or cmd  
5. Type:

```powershell
downterm
```

If you see *not recognized*, the terminal is still using the old PATH — open a brand-new window after install.

### What install does

- Writes **`downterm.cmd`** and **`downterm.ps1`** (so both cmd and PowerShell find it)
- Adds this folder to your **user PATH**
- Undo: `download.bat --uninstall`

### Linux / macOS

```bash
./download.sh --install   # or menu → 7
# new shell:
downterm
```

---

## everyday use

1. **Copy** a video link in the browser  
2. Type **`downterm`**  
3. Press **`1`** → best video  

```
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

## files

| file | role |
|------|------|
| `downterm.cmd` / `downterm.ps1` | Command name for PATH |
| `install-path.ps1` | PATH install / uninstall |
| `download.bat` / `download.sh` | Terminal menu |
| `filter.ps1` / `filter.sh` | Progress bar + yt-dlp |

---

## releases

- **`3.2.0`** — first-run PATH offer; PowerShell `downterm.ps1` entrypoint; clearer install messaging  
- **`3.1.1`** — PATH install polish  
- **`3.1.0`** — terminal-only; removed window GUI  

https://github.com/onion3130/downterm/releases

---

## license

MIT for downterm source. Third-party tools: see license files in the repo.
