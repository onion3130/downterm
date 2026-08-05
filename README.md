# downterm

> a quiet terminal wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → open downterm → press a number.**  
Minimal terminal UI only. No window app. No flag soup.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

**Current:** `3.1.0`

---

## how to use

1. In your browser, **copy** a video link  
2. Run **downterm** (or `download.bat` / `./download.sh`)  
3. Press **`1`** → best video downloads  

That’s the whole product.

```
  downterm  3.1.0
  ..........................................

  copy a link, then pick a number.

  1  paste · best video
  2  paste · pick quality
  3  paste · audio only
  4  history
  5  open folder
  6  setup tools
  7  install PATH  (type downterm anywhere)
  8  help
  9  quit

  >
```

---

## install so `downterm` works anywhere

### Windows

1. Put the folder somewhere stable (e.g. Documents or clone path)  
2. Run downterm once → press **`7`** (install PATH)  
   or: `download.bat --install`  
3. **Open a new terminal**  
4. Type:

```bat
downterm
```

This adds the folder to your **user PATH** and uses `downterm.cmd` as the entrypoint.

Remove later: `download.bat --uninstall`

### Linux / macOS

```bash
chmod +x download.sh filter.sh
./download.sh --install
# or press 7 in the menu
# ensure ~/.local/bin is on PATH, new shell:
downterm
```

---

## setup (tools)

Press **`6`** (or `download.bat --setup`) to fetch pinned **yt-dlp** / **ffmpeg** / **deno** (SHA256 via `bin/checksums.txt`).  
Linux: install **ffmpeg** with your package manager if needed.

---

## what it does

- Clipboard → download (no typing URLs)
- Best video+audio → **mp4**, or audio **mp3**
- Quality pick by number (best / 1080 / 720 / 480 / 1440 / 4K)
- Optional English subs + SponsorBlock on the quality path
- History + open folder
- Quiet progress bar · `ERR-NN` codes · [docs/ERRORS.md](./docs/ERRORS.md)

---

## files

| file | role |
|------|------|
| `downterm.cmd` | Windows PATH entry (`downterm`) |
| `download.bat` | Terminal UI (Windows) |
| `download.sh` | Terminal UI (Linux/macOS) |
| `filter.ps1` / `filter.sh` | Progress bar + yt-dlp |
| `bin/checksums.txt` | Pinned tool hashes |

---

## releases (recent)

- `3.1.0` — **terminal-only**; removed window GUI; **PATH install** so `downterm` works; number menu  
- `2.6` — (deprecated) WinForms experiment  
- `2.5` — number menu introduction  
- `2.4` and earlier — prompt / flag era  

See [releases](https://github.com/onion3130/downterm/releases).

---

## license

MIT for downterm source. Third-party binaries: see README history / license files (ffmpeg GPL when redistributed, yt-dlp Unlicense, deno MIT).

---

made with too much time and a terminal.
