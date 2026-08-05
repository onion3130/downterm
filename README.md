# downterm

> a quiet wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

A minimal, styled terminal wrapper around yt-dlp. Paste a URL, pick video/audio and quality, get the file. No flags to memorize, no clutter, no noise.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

---

## what it does

- picks the **best video + best audio** stream (or audio-only mp3)
- merges them into a single **mp4** (via ffmpeg)
- **quality pick**: best / 4K / 1440p / 1080p / 720p / 480p (video), best / medium / low (audio)
- **type pick**: video or audio
- **subtitles**: optional English auto/official subs embedded into the file
- **SponsorBlock**: optional removal of sponsors / intros / outros (YouTube)
- **force overwrite**: re-download even if the file already exists
- **clipboard paste** (`p`), **history** (`h`), **open folder** (`o`), **info preview** (`i`)
- **batch mode**: paste `urls.txt` instead of a URL, it downloads all of them
- **playlists**: passes YouTube playlist URLs to yt-dlp natively (downloads every item)
- **dedup by file existence**: skip existing files unless you force overwrite
- **first-run setup**: type `s` to fetch pinned, SHA256-verified copies of yt-dlp, ffmpeg, and deno
- **non-interactive mode**: flags + `downterm.conf` for scripted use
- **error codes**: clear `ERR-NN` codes — see [docs/ERRORS.md](./docs/ERRORS.md)
- shows a **clean progress bar** with speed + ETA instead of spamming 5000 lines
- stays open so you can grab another

## screenshots

```
  downterm  v2.4
  ...............................................

  a quiet wrapper around yt-dlp.

  url  p paste  h history  o open  i info
  ? help  t test  r redo  s setup  q quit

  < https://youtube.com/watch?v=...
    video or audio? (v/a) [v]
    quality? (b/k/2/1/7/4) [b]
    embed English subs? (y/n) [n]
    SponsorBlock remove? (y/n) [n]
    overwrite if exists? (y/n) [n]

  downterm  v2.4
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

### Option A - Windows full bundle (recommended for Windows)

Download `downterm-vX-windows-full.zip` from the [latest release](https://github.com/onion3130/downterm/releases/latest) and extract it. Binaries (yt-dlp.exe, ffmpeg.exe, deno.exe) are pre-bundled — no first-run `s` setup required, no network fetch on launch. Just run `download.bat`.

### Option B - from source

```bash
git clone https://github.com/onion3130/downterm.git
cd downterm
# Windows
download.bat
# Linux/macOS
chmod +x download.sh && ./download.sh
```

On Windows, the bundled binaries (`yt-dlp.exe`, `ffmpeg.exe`, `deno.exe`) ship in the repo root so `git clone` gives you a working setup out of the box. On Linux/macOS, type **`s`** (or `setup`) at the prompt on first run — downterm fetches pinned, SHA256-verified copies of `yt-dlp` and `deno` from their official release pages; install `ffmpeg` via your system package manager. See [`bin/checksums.txt`](./bin/checksums.txt) for the pinned versions and hashes.

### Option C - re-fetch / refresh binaries

Already installed but want fresh copies? Type **`s`** (or `setup`) at the prompt. downterm re-fetches the pinned versions from upstream and verifies each SHA256 against `bin/checksums.txt`. This is also how you update to a new pinned version after `bin/checksums.txt` is bumped.

## usage

### interactive (default)

1. Run the script
2. Paste a URL, type `p` for clipboard, or drop a `urls.txt` for batch
3. Pick video/audio, quality, optional subs / SponsorBlock / overwrite
4. File saves next to the script (or into `--output=` / `OUTPUT=` dir)

### non-interactive (scripted)

```bash
# single download, no prompts
./download.sh "https://youtube.com/watch?v=..." --mode=audio --quality=720

# video with extras
./download.sh "https://youtube.com/watch?v=..." --mode=video --quality=1080 --subs --sponsorblock

# or set defaults in downterm.conf (see downterm.conf.example):
#   MODE=video
#   QUALITY=1080
#   OUTPUT=./downloads
#   SUBS=0
#   FORCE=0
#   SPONSORBLOCK=0
```

CLI flags override `downterm.conf`, which overrides built-in defaults. If a URL is passed with resolved mode/quality (flags or config), interactive prompts are skipped.

## commands

| key | action |
|-----|--------|
| `<url>` | download video or audio |
| `<file.txt>` | batch mode: download all URLs from file |
| `p` / `paste` | paste URL from clipboard and download |
| `h` / `history` | pick from recent URLs |
| `o` / `open` | open the download folder |
| `i` / `info` | show title / duration / uploader, optional download |
| `?` or `help` | open the help screen |
| `t` or `test` | self-test: sample download, then delete |
| `r` or `redo` | re-download the last URL |
| `s` or `setup` | fetch pinned yt-dlp/ffmpeg/deno binaries (SHA256-verified) |
| `q` / `quit` / `exit` | close downterm |

## prompts

| key | meaning |
|-----|--------|
| `v` / `a` | video or audio (default: video) |
| `b` / `k` / `2` / `1` / `7` / `4` | best / 4K / 1440p / 1080p / 720p / 480p |
| `b` / `m` / `l` | audio: best / medium / low |
| subs y/n | embed English subtitles (video) |
| sponsor y/n | SponsorBlock segment removal (video) |
| force y/n | overwrite if file already exists |
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
- `v2.3` - **bundled binaries shipped in repo + release zip** (policy revert: yt-dlp.exe/ffmpeg.exe/deno.exe tracked again), enhanced `--version` shows pinned vs installed versions for yt-dlp/ffmpeg/deno
- `v2.4` - **clipboard paste** (`p`), **history** (`h`), **open folder** (`o`), **info preview** (`i`), **4K/1440p** quality, **English subtitles**, **SponsorBlock**, **force overwrite**, safer filenames (`title [id].ext`), conf keys `SUBS`/`FORCE`/`SPONSORBLOCK`, CLI `--subs` `--force` `--sponsorblock`, Linux/macOS parity (redo, audio quality, new commands)

## license

MIT - see [LICENSE](./LICENSE)

---

made with too much time and a terminal.
