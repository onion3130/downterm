# downterm

> a quiet wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

A minimal, styled terminal wrapper around yt-dlp. Paste a URL, pick video/audio and quality, get the file. No flags to memorize, no clutter, no noise.

---

## what it does

- picks the **best video + best audio** stream (or audio-only mp3)
- merges them into a single **mp4** (via ffmpeg)
- **quality pick**: best / 1080p / 720p / 480p
- **type pick**: video or audio
- **batch mode**: paste `urls.txt` instead of a URL, it downloads all of them
- **silent dedup**: already-downloaded videos are skipped automatically
- shows a **clean progress bar** instead of spamming 5000 lines
- stays open so you can grab another

## screenshots

```
  downterm  v2.0
  ...............................................

  a quiet wrapper around yt-dlp.

  ? help   t test   q quit

  < https://youtube.com/watch?v=...
    video or audio? (v/a) [v]
    quality? (b/1/7/4) [b]

  downterm  v2.0
  ...............................................

  acquiring
  https://youtube.com/watch?v=...

  -----------------------------------------------

  ######################-----------  75.3%

  -----------------------------------------------
  saved.  next to yt-dlp.exe

  any key to run again.
```

Batch mode:
```
  < urls.txt
    video or audio? (v/a) [v]
    quality? (b/1/7/4) [b]

  downterm  v2.0
  ...............................................

  [1/5] https://youtube.com/watch?v=...
  -----------------------------------------------
  ########################  91.2%
  saved.

  [2/5] ...
  ...

  5 done.
```

## setup

### Option A — full install (recommended)
Download the bundled zip from the [latest release](https://github.com/onion3130/downterm/releases/latest) and extract. Binaries are included so it works with zero setup.

- **Windows users** → `downterm-v2.0-windows.zip` (includes `yt-dlp.exe`, `ffmpeg.exe`, `deno.exe`)
- **Linux/macOS users** → `downterm-v2.0-linux.tar.gz` (scripts only; uses system yt-dlp/ffmpeg/deno)
- **Already have yt-dlp/ffmpeg/deno** → `downterm-v2.0-script-only.zip`

### Option B — from source
```bash
git clone https://github.com/onion3130/downterm.git
cd downterm
# Windows
download.bat
# Linux/macOS
chmod +x download.sh && ./download.sh
```

## usage

1. Run the script
2. Paste a URL (or `urls.txt` for batch mode)
3. Pick video/audio (`v`/`a`, default `v`)
4. Pick quality (`b`/`1`/`7`/`4`, default `b`)
5. File saves next to the script

## commands

| key | action |
|-----|--------|
| `<url>` | download video or audio |
| `<file.txt>` | batch mode: download all URLs from file |
| `?` or `help` | open the help screen |
| `t` or `test` | self-test: downloads a sample, verifies, then deletes |
| `q` / `quit` / `exit` | close downterm |

## prompts

| key | meaning |
|-----|--------|
| `v` / `a` | video or audio (default: video) |
| `b` / `1` / `7` / `4` | best / 1080p / 720p / 480p (default: best) |

## how the progress bar works

yt-dlp normally prints a new line for every 0.1% downloaded. downterm pipes that output through `filter.ps1` (Windows) or `filter.sh` (Linux), which parses the latest progress update and redraws a single line:

```
  ####################----------  66.7%
```

## requirements

### Windows
- Windows 10+ (for ANSI color support)
- PowerShell (bundled with Windows)
- `yt-dlp.exe` — included in Windows zip
- `ffmpeg.exe` — included in Windows zip
- `deno.exe` — included in Windows zip (for full YouTube format support)

### Linux / macOS
```bash
chmod +x download.sh
./download.sh
```
- `yt-dlp` — `pip install yt-dlp` or `sudo apt install yt-dlp`
- `ffmpeg` — `sudo apt install ffmpeg`
- `deno` — `curl -fsSL https://deno.land/install.sh | sh`
- bash 4+ (for regex matching in the progress bar filter)

## bundled software (legal notes)

### yt-dlp
- License: The Unlicense (effectively public domain)
- Source: https://github.com/yt-dlp/yt-dlp

### ffmpeg
- License: LGPL v2.1+
- Source: https://ffmpeg.org / https://www.gyan.dev/ffmpeg/builds/
- Full license text: see [ffmpeg-LICENSE.txt](./ffmpeg-LICENSE.txt)

### deno
- License: MIT
- Source: https://github.com/denoland/deno
- Purpose: JavaScript runtime for yt-dlp YouTube extraction
- Full license text: see [deno-LICENSE.txt](./deno-LICENSE.txt)

All three are freely redistributable. If you maintain any of these and want anything changed, open an issue.

## releases

Each version is preserved in [`/releases`](./releases). Latest scripts:
- Windows: [`download.bat`](./download.bat)
- Linux/macOS: [`download.sh`](./download.sh)

See all releases: https://github.com/onion3130/downterm/releases

- `v1.0` — first sketch, dotted header
- `v1.1` — wordmark + boxed guide panel
- `v1.2` — tightened, single accent wordmark
- `v1.3` — yt-dlp.exe existence check, success/warn branching
- `v1.4` — in-app help (`?`) and quit (`q`) commands
- `v1.5` — cleaned layout, help, quit, error flow
- `v1.6` — fixed `'cho'` bug and post-entry layout
- `v1.7` — clean full-redraw on entry, no jumble
- `v1.8` — progress bar filter (`filter.ps1`), ffmpeg auto-detect
- `v1.9` — Linux support (`download.sh` + `filter.sh`), self-test (`t`)
- `v1.9.1` — bundled deno.exe for full YouTube format support
- `v2.0` — **type pick** (video/audio), **quality pick** (1080p/720p/480p), **batch mode** (urls.txt), **silent dedup** (archive)

## license

MIT — see [LICENSE](./LICENSE)

---

made with too much time and a terminal.
