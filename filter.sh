#!/usr/bin/env bash
# downterm filter.sh — progress bar filter for yt-dlp (Linux/macOS)
# Usage: filter.sh <url> <ffmpeg_path> <yt-dlp_path> [mode] [quality]

url="${1:-}"
ff="${2:-}"
ytdlp="${3:-yt-dlp}"
mode="${4:-video}"
quality="${5:-best}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"

if [ "$mode" = "audio" ]; then
  args=(-x --audio-format mp3 --audio-quality 0 -o '%(title)s.%(ext)s' --newline)
else
  case "$quality" in
    1080) format='bv*[height<=1080]+ba/b[height<=1080]' ;;
    720)  format='bv*[height<=720]+ba/b[height<=720]' ;;
    480)  format='bv*[height<=480]+ba/b[height<=480]' ;;
    *)    format='bv*+ba/b' ;;
  esac
  args=(-f "$format" --merge-output-format mp4 -o '%(title)s.%(ext)s' --newline)
fi

if [ -n "$ff" ]; then
  args+=(--ffmpeg-location "$ff")
fi

# Deno detection
if [ -x "${SCRIPT_DIR}/deno" ]; then
  args+=(--js-runtimes "deno:${SCRIPT_DIR}/deno")
elif [ -x "${SCRIPT_DIR}/deno.exe" ]; then
  args+=(--js-runtimes "deno:${SCRIPT_DIR}/deno.exe")
elif command -v deno >/dev/null 2>&1; then
  args+=(--js-runtimes "deno:deno")
fi

# Silent dedup archive
args+=(--download-archive .downterm_archive.txt)

args+=("$url")

last_bar=false
err_out=""
skip_detected=false
"$ytdlp" "${args[@]}" 2>&1 | while IFS= read -r line; do
  if [[ "$line" =~ \[download\]\ +([0-9.]+)% ]]; then
    pct="${BASH_REMATCH[1]}"
    pct_int="${pct%.*}"
    [ -z "$pct_int" ] && pct_int=0
    n=$(( (pct_int * 30) / 100 ))
    filled=""
    empty=""
    for (( i=0; i<n; i++ )); do filled+='#'; done
    for (( i=n; i<30; i++ )); do empty+='-'; done
    printf "\r  %s%s  %s%%   " "$filled" "$empty" "$pct" >&2
    last_bar=true
  elif [[ "$line" =~ has\ already\ been\ downloaded ]]; then
    skip_detected=true
  elif [[ "$line" =~ ^\[youtube\] ]] || [[ "$line" =~ ^\[info\] ]] || [[ "$line" =~ ^\[Merger\] ]] || [[ "$line" =~ ^\[Deleting\] ]] || [[ "$line" =~ ^\[ExtractAudio\] ]] || [[ "$line" =~ ^\[EmbedSubtitle\] ]] || [[ "$line" =~ ^\[Metadata\] ]]; then
    : # suppress
  elif [ -n "$line" ]; then
    if $last_bar; then printf '\n' >&2; last_bar=false; fi
    printf '%s\n' "$line" >&2
  fi
done

# Map known errors to codes
if [ -n "$err_out" ]; then
  code=""
  msg=""
  case "$err_out" in
    *"Video unavailable"*) code="ERR-01"; msg="video unavailable (private/deleted)" ;;
    *"Private video"*) code="ERR-02"; msg="private video — sign in required" ;;
    *"Members-only"*) code="ERR-03"; msg="members-only content" ;;
    *"geo"*"restricted"*) code="ERR-04"; msg="geo-restricted in your region" ;;
    *"age restricted"*) code="ERR-05"; msg="age-restricted — needs cookies" ;;
    *"Sign in to confirm"*) code="ERR-06"; msg="bot detection — try again later" ;;
    *"No video formats found"*) code="ERR-07"; msg="no downloadable formats found" ;;
    *"Unsupported URL"*) code="ERR-13"; msg="unsupported URL — not a valid video link" ;;
    *) code="ERR-00"; msg="unknown error" ;;
  esac
  printf "\n  %s — %s  ⟡  see github.com/onion3130/downterm/blob/main/docs/ERRORS.md\n" "$code" "$msg" >&2
fi
