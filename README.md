# downterm

> a quiet wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

A minimal, styled terminal wrapper around yt-dlp. Paste a URL, pick video/audio and quality, get the file. No flags to memorize, no clutter, no noise.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

---

## what it does

- picks the **best video + best audio** stream (or audio-only mp3)
- merges them into a single **mp4** (via ffmpeg)
- **quality pick**: best / 1080p / 720p / 480p (video), best / medium / low (audio)
- **type pick**: video or audio
- **batch mode**: paste `urls.txt` instead of a URL, it downloads all of them
- **playlists**: passes YouTube playlist URLs to yt-dlp natively (downloads every item)
- **dedup by file existence**: a video that's already on disk gets skipped; delete the file to re-download
- **first-run setup**: type `s` to fetch pinned, SHA256-verified copies of yt-dlp, ffmpeg, and deno
- **non-interactive mode**: pass `<url> --mode=audio --quality=720` (or use a `downterm.conf`) for scripted use
- **error codes**: clear `ERR-NN` codes for private/geo/age/bot/network failures - see [docs/ERRORS.md](./docs/ERRORS.md)
- shows a **clean progress bar** with speed + ETA instead of spamming 5000 lines
- stays open so you can grab another

## screenshots

```
  downterm  v2.2
  ...............................................

  a quiet wrapper around yt-dlp.

  url  ? help  t test  r redo  s setup  q quit

  < https://youtube.com/watch?v=...
    video or audio? (v/a) [v]
    quality? (b/1/7/4) [b]

  downterm  v2.2
  ...............................................

  acquiring
  https://youtube.com/watch?v=...

  -----------------------------------------------

  ######################-----------  75.3%  4.8 MB/s  ETA 00:42

  -----------------------------------------------
  saved.  next to yt-dlp.exe

  any key to run again.
```

## setup

### Option A - from source (recommended)

```bash
git clone https://github.com/onion3130/downterm.git
cd downterm
# Windows
download.bat
# Linux/macOS
chmod +x download.sh && ./download.sh
```

On first run, type **`s`** (or `setup`) at the prompt. downterm fetches pinned, SHA256-verified copies of yt-dlp, ffmpeg, and deno directly from their official release pages. No binaries are stored in this repo - see [`bin/checksums.txt`](./bin/checksums.txt) for the pinned versions and hashes.

### Option B - full install (offline)

Download the bundled zip from the [latest release](https://github.com/onion3130/downterm/releases/latest) and extract if you can't (or don't want to) reach the upstream servers at runtime. Binaries are included in the bundle only - never in the git repo.

## usage

### interactive (default)

1. Run the script
2. Paste a URL (or `urls.txt` for batch, or a YouTube playlist URL)
3. Pick video/audio (`v`/`a`, default `v`)
4. Pick quality (`b`/`1`/`7`/`4`, default `b`)
5. File saves next to the script (or into `--output=` dir if given)

### non-interactive (scripted)

```bash
# single download, no prompts
./download.sh "https://youtube.com/watch?v=..." --mode=audio --quality=720

# or set defaults in downterm.conf (loaded automatically):
#   MODE=audio
#   QUALITY=720
#   OUTPUT=./downloads
```

CLI flags override `downterm.conf`, which overrides built-in defaults. If a URL is passed and mode/quality are fully resolved (by flags or config), no prompts appear.

## commands

| key | action |
|-----|--------|
| `<url>` | download video or audio |
| `<file.txt>` | batch mode: download all URLs from file |
| `?` or `help` | open the help screen |
| `t` or `test` | self-test: downloads a small sample from a stable Google CDN, verifies, then deletes |
| `r` or `redo` | re-download the last URL |
| `s` or `setup` | fetch pinned yt-dlp/ffmpeg/deno binaries (SHA256-verified) |
| `q` / `quit` / `exit` | close downterm |

## prompts

| key | meaning |
|-----|--------|
| `v` / `a` | video or audio (default: video) |
| `b` / `1` / `7` / `4` | best / 1080p / 720p / 480p (default: best) |
| `b` / `m` / `l` | audio: best / medium / low (default: best) |

## how the progress bar works

yt-dlp normally prints a new line for every 0.1% downloaded. downterm pipes that output through `filter.ps1` (Windows) or `filter.sh` (Linux), which parses the latest progress update and redraws a single line:

```
  ####################----------  66.7%  4.2 MB/s  ETA 01:18
```

## requirements

### Windows
- Windows 10+ (for ANSI color support and `curl.exe`)
- PowerShell (bundled with Windows, used for the progress bar and zip extraction)
- Run `s` on first launch to fetch `yt-dlp.exe`, `ffmpeg.exe`, `deno.exe`

### Linux / macOS
```bash
chmod +x download.sh
./download.sh
```
- bash 4+ (for regex matching in the progress bar filter)
- `curl` and either `sha256sum` or `shasum` (for setup verification)
- Run `s` on first launch to fetch `yt-dlp` and `deno`
- `ffmpeg`: install via your system package manager (apt/brew/dnf)

## error handling

downterm maps yt-dlp failures to short error codes. The most common:

| code | meaning | what to do |
|------|---------|------------|
| `ERR-01` | video unavailable (private/deleted) | the URL is dead - try another |
| `ERR-04` | geo-restricted in your region | use a VPN or pick another video |
| `ERR-05` | age-restricted (needs cookies) | sign in via browser, export cookies, pass to yt-dlp |
| `ERR-06` | YouTube bot detection | wait a few minutes and retry |
| `ERR-07` | no downloadable formats | the host may not provide mp4; try audio mode |
| `ERR-08/09/10` | HTTP 4xx / 5xx / connection failure | check your network, retry |
| `ERR-11` | ffmpeg not found | run `s` to fetch ffmpeg (Windows) or apt/brew install |
| `ERR-13` | invalid/unsupported URL | make sure it starts with `http://` or `https://` |

On any non-zero exit, downterm cleans up partial `.part` / `.temp` files automatically. See [docs/ERRORS.md](./docs/ERRORS.md) for the full list.

## bundled software (legal notes)

The **downterm source code** is MIT-licensed (see [LICENSE](./LICENSE)).

downterm fetches third-party binaries on first run. They are **not** committed to this repo. The full licenses are bundled alongside the source for attribution:

| component | license | source |
|-----------|---------|--------|
| **yt-dlp** | The Unlicense (effectively public domain) | https://github.com/yt-dlp/yt-dlp |
| **ffmpeg** (gyan.dev essentials build) | **GPL v3** | https://www.gyan.dev/ffmpeg/builds/ - see [ffmpeg-LICENSE.txt](./ffmpeg-LICENSE.txt) |
| **deno** | MIT | https://github.com/denoland/deno - see [deno-LICENSE.txt](./deno-LICENSE.txt) |

> **Note on the ffmpeg license.** The gyan.dev *essentials* build is licensed under **GPL v3**, not LGPL. This is because it statically links GPL-only codecs (x264, x265, etc.). Redistributing that build *together with* downterm in a single zip makes the **combined bundle GPL v3**. The downterm source code alone (without the GPL ffmpeg binary) remains MIT. If you want a license-compatible ffmpeg build, use gyan.dev's `ffmpeg-release-full-shared.7z` (LGPL) or install ffmpeg via your system package manager.

GitHub's license detector may report "MIT or GPL-3.0" because both license files exist in the repo. This is expected: MIT covers the source, GPL-3.0 covers the ffmpeg build we document.

## releases

Each version is preserved in [`/releases`](./releases). Latest scripts:
- Windows: [`download.bat`](./download.bat)
- Linux/macOS: [`download.sh`](./download.sh)

See all releases: https://github.com/onion3130/downterm/releases

- `v1.0` - first sketch, dotted header
- `v1.1` - wordmark + boxed guide panel
- `v1.2` - tightened, single accent wordmark
- `v1.3` - yt-dlp.exe existence check, success/warn branching
- `v1.4` - in-app help (`?`) and quit (`q`) commands
- `v1.5` - cleaned layout, help, quit, error flow
- `v1.6` - fixed `'cho'` bug and post-entry layout
- `v1.7` - clean full-redraw on entry, no jumble
- `v1.8` - progress bar filter (`filter.ps1`), ffmpeg auto-detect
- `v1.9` - Linux support (`download.sh` + `filter.sh`), self-test (`t`)
- `v1.9.1` - bundled deno.exe for full YouTube format support
- `v2.0` - **type pick** (video/audio), **quality pick** (1080p/720p/480p), **batch mode** (urls.txt)
- `v2.1` - force mp4 output (no webm), self-test anti-self-close, removed silent archive skips in favor of file-existence checks
- `v2.2` - **first-run setup** (`s` command with SHA256-verified binary fetch), **GitHub Actions CI** on ubuntu + windows, parity between `download.bat` and `download.sh`, improved error handling (URL validation, partial-file cleanup, ffmpeg-missing warnings), **non-interactive flags** (`--mode=`, `--quality=`, `--output=`) and `downterm.conf`, clarified ffmpeg **GPL v3** license vs source MIT, playlists pass-through to yt-dlp

## license

MIT - see [LICENSE](./LICENSE)

---

made with too much time and a terminal.
