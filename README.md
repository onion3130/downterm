# downterm

> a quiet wrapper around [yt-dlp](https://github.com/yt-dlp/yt-dlp)

A minimal, styled Windows batch script that wraps yt-dlp into a clean little terminal experience. Paste a URL, press enter, get the file. No flags, no clutter, no noise.

---

## what it does

- picks the **best video + best audio** stream
- merges them into a single **mp4** (via ffmpeg)
- saves the file next to `yt-dlp.exe`
- shows a **clean progress bar** instead of spamming 5000 lines per download
- stays open so you can grab another

## screenshots

```
  downterm  v1.8
  ...............................................

  a quiet wrapper around yt-dlp.

  ? help   q quit

  < https://youtube.com/watch?v=...

  downterm  v1.8
  ...............................................

  acquiring
  https://youtube.com/watch?v=...

  -----------------------------------------------

  [youtube] Extracting URL...
  [info] Downloading 1 format(s): 401+251
  [download] Destination: video.f401.mp4
  ##################--------------  60.2%
  ...

  -----------------------------------------------
  saved.  next to yt-dlp.exe

  any key to run again.
```

## setup

Everything you need is included in the repo. Just clone and run:

```bat
git clone https://github.com/onion3130/downterm.git
cd downterm
download.bat
```

Or [download as ZIP](https://github.com/onion3130/downterm/archive/refs/heads/main.zip) and extract.

## usage

1. Double-click `download.bat`
2. Paste a video URL
3. Press Enter
4. File saves next to `yt-dlp.exe`

## commands

| key | action |
|-----|--------|
| `<url>` | download best video + audio, merged to mp4 |
| `?` or `help` | open the help screen |
| `q` / `quit` / `exit` | close downterm |

## how the progress bar works

yt-dlp normally spits out a new line for every 0.1% downloaded — hundreds of lines scrolling past. downterm pipes that output through `filter.ps1`, which parses the latest progress update and redraws a single line:

```
  ####################----------  66.7%
```

It updates in place with a carriage return, then shows any non-progress output (errors, info, warnings) above the bar. Your terminal stays clean.

## requirements

- Windows 10+ (for ANSI color support)
- PowerShell (bundled with Windows 10+)
- `yt-dlp.exe` — **included**
- `ffmpeg.exe` — **included**

## bundled software (legal notes)

This repo bundles two third-party binaries so it works out of the box:

### yt-dlp
- License: The Unlicense (effectively public domain)
- Source: https://github.com/yt-dlp/yt-dlp
- Freely redistributable. No attribution required, but appreciated.

### ffmpeg
- License: LGPL v2.1+
- Source: https://ffmpeg.org
- Build: gyan.dev essentials build (https://www.gyan.dev/ffmpeg/builds/)
- Full license text: see [ffmpeg-LICENSE.txt](./ffmpeg-LICENSE.txt)

Both are included in good faith as redistributable software. If you are the maintainer of either project and want anything changed, open an issue.

## releases

Each version is preserved in [`/releases`](./releases). The latest is [`download.bat`](./download.bat).

- `v1.0` — first sketch, dotted header
- `v1.1` — wordmark + boxed guide panel
- `v1.2` — tightened, single accent wordmark
- `v1.3` — yt-dlp.exe existence check, success/warn branching
- `v1.4` — in-app help (`?`) and quit (`q`) commands
- `v1.5` — cleaned layout, help, quit, error flow
- `v1.6` — fixed `'cho'` bug and post-entry layout
- `v1.7` — clean full-redraw on entry, no jumble
- `v1.8` — progress bar filter (`filter.ps1`), ffmpeg auto-detect

## license

MIT — see [LICENSE](./LICENSE)

---

made with too much time and a terminal.
