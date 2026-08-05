# downterm

> a quiet wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

**Copy a link → open downterm → press one number (or one button).**  
No flags. No typing URLs. Minimal dark window on Windows; number menu everywhere else.

[![self-test](https://github.com/onion3130/downterm/actions/workflows/test.yml/badge.svg)](https://github.com/onion3130/downterm/actions/workflows/test.yml)

---

## what it does

- **Windows GUI** (default): dark minimal window — paste button, quality dropdown, **download** click
- **Number menu** (terminal): press `1`–`9` only — no URL typing
- Clipboard is the source of truth (copy link in browser first)
- Best video+audio → **mp4** (ffmpeg), or audio-only **mp3**
- Quality: best / 4K / 1440 / 1080 / 720 / 480
- Optional English subs + SponsorBlock from the pick-quality path / GUI checkboxes
- History + open folder
- Progress bar, quiet logs, clear `ERR-NN` codes — [docs/ERRORS.md](./docs/ERRORS.md)
- Setup (`7` or GUI warning) fetches pinned yt-dlp / ffmpeg / deno

## how to use (the whole point)

1. In your browser: **copy** a video link  
2. Double-click **`download.bat`** (Windows)  
3. Click **paste** (if needed) → **download**  
   · or in the number menu press **`1`** for best video immediately  

That’s it.

## screenshots

```
  downterm  v2.6
  ..........................................

  no typing. pick a number.

  1  paste link  ·  download best video
  2  paste link  ·  pick quality
  3  paste link  ·  audio only
  4  history
  5  open folder
  6  open window gui
  7  setup tools
  8  help
  9  quit

  >
```

## setup

### Windows

1. Get a release or clone the repo  
2. Double-click **`download.bat`** → GUI opens  
3. (First time) if tools are missing, open **terminal** from the GUI or run menu **7 setup**

### Linux / macOS

```bash
git clone https://github.com/onion3130/downterm.git
cd downterm
chmod +x download.sh filter.sh
./download.sh
```

Copy a link, press **`1`**. Install `ffmpeg` via your package manager; use menu **7** for yt-dlp.

## menu (terminal)

| key | action |
|-----|--------|
| `1` | clipboard → best video (no other questions) |
| `2` | clipboard → pick quality (numbers only) |
| `3` | clipboard → audio |
| `4` | history |
| `5` | open folder |
| `6` | open GUI (Windows) / help (Linux) |
| `7` | setup tools |
| `8` / `9` | help / quit |

Advanced: `download.bat --tui` forces the number menu.
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
- `v2.4` - clipboard paste, history, info, 4K/1440, subs, SponsorBlock, force overwrite (still prompt-heavy)
- `v2.5` - **no URL typing**: number menu only — `1` paste+best video, quality picker by number, history/folder/setup
- `v2.6` - **Windows GUI default** (`gui.ps1`): paste button, dropdowns, one **download** click; double-click `download.bat` opens the window

## license

MIT - see [LICENSE](./LICENSE)

---

made with too much time and a terminal.
