#!/usr/bin/env bash
# downterm filter.sh — progress bar filter for yt-dlp (Linux/macOS)
# Usage: filter.sh <url> <ffmpeg_path> <yt-dlp_path> [mode] [quality] [output]

url="${1:-}"
ff="${2:-}"
ytdlp="${3:-yt-dlp}"
mode="${4:-video}"
quality="${5:-best}"
output="${6:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"

# --- Item 5: URL pre-validation ---
if [[ ! "$url" =~ ^https?:// ]]; then
  printf "\n  ERR-13 - invalid URL  *  must start with http:// or https://\n" >&2
  exit 13
fi

# Build output template
outTpl='%(title)s.%(ext)s'
if [ -n "$output" ]; then outTpl="${output}/%(title)s.%(ext)s"; fi

if [ "$mode" = "audio" ]; then
  aq='0'
  case "$quality" in
    medium) aq='5' ;;
    low)    aq='9' ;;
  esac
  args=(-x --audio-format mp3 --audio-quality "$aq" -o "$outTpl" --newline)
else
  case "$quality" in
    1080) format='bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    720)  format='bv*[ext=mp4][height<=720]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    480)  format='bv*[ext=mp4][height<=480]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    *)    format='bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b' ;;
  esac
  args=(-f "$format" --merge-output-format mp4 -o "$outTpl" --newline)
fi

if [ -n "$ff" ]; then
  args+=(--ffmpeg-location "$ff")
fi

if [ -x "${SCRIPT_DIR}/deno" ]; then
  args+=(--js-runtimes "deno:${SCRIPT_DIR}/deno")
elif [ -x "${SCRIPT_DIR}/deno.exe" ]; then
  args+=(--js-runtimes "deno:${SCRIPT_DIR}/deno.exe")
elif command -v deno >/dev/null 2>&1; then
  args+=(--js-runtimes "deno:deno")
fi

# --- Item 5: dedup by file existence (no archive) ---
args+=(--no-overwrites --continue)

args+=("$url")

skip_patterns='^\[youtube\]|^\[info\]|^\[Merger\]|^\[Deleting\]|^\[ExtractAudio\]|^\[EmbedSubtitle\]|^\[Metadata\]|^\[download\]\s+Destination:'

# Buffer error-bearing lines so we can analyze them after the bar finishes
err_out=""

"$ytdlp" "${args[@]}" 2>&1 | while IFS= read -r line; do
  if [[ "$line" =~ \[download\]\ +([0-9.]+)%.*at\ +([0-9.]+)([KMG]?)i?B/s.*ETA\ +(.+) ]]; then
    pct="${BASH_REMATCH[1]}"
    speed_val="${BASH_REMATCH[2]}"
    speed_unit="${BASH_REMATCH[3]}"
    eta="${BASH_REMATCH[4]}"
    if [[ "$speed_unit" == "M" ]]; then
      speed_mb="$speed_val"
    elif [[ "$speed_unit" == "K" ]]; then
      speed_mb=$(awk "BEGIN {printf \"%.2f\", $speed_val/1024}")
    elif [[ "$speed_unit" == "G" ]]; then
      speed_mb=$(awk "BEGIN {printf \"%.2f\", $speed_val*1024}")
    else
      speed_mb=$(awk "BEGIN {printf \"%.2f\", $speed_val/1024/1024}")
    fi
    pct_int="${pct%.*}"
    [ -z "$pct_int" ] && pct_int=0
    n=$(( (pct_int * 30) / 100 ))
    filled=""
    empty=""
    for (( i=0; i<n; i++ )); do filled+='#'; done
    for (( i=n; i<30; i++ )); do empty+='-'; done
    printf "\r  %s%s  %s%%  %s MB/s  ETA %s   " "$filled" "$empty" "$pct" "$speed_mb" "$eta" >&2
    last_bar=true
  elif [[ "$line" =~ \[download\]\ +([0-9.]+)% ]]; then
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
  elif echo "$line" | grep -qE "$skip_patterns"; then
    : # suppress
  elif [ -n "$line" ]; then
    if $last_bar; then printf '\n' >&2; last_bar=false; fi
    printf '%s\n' "$line" >&2
    # Accumulate non-progress lines so we can pattern-match errors at the end
    printf '%s\n' "$line" >>"$err_buf"
  fi
done

# In bash, while-loop with pipe runs in a subshell, so err_buf lives in a tmp file instead.
err_buf="${tmp_dir:-/tmp}/downterm_err.$$"
trap 'rm -f "$err_buf" 2>/dev/null' EXIT

if $last_bar; then printf '\n' >&2; fi

if [ -f "$err_buf" ]; then
  err_out=$(cat "$err_buf" 2>/dev/null)
  rm -f "$err_buf" 2>/dev/null
else
  err_out=""
fi
if [ -n "$err_out" ]; then
  code=""
  msg=""
  case "$err_out" in
    *"Video unavailable"*) code="ERR-01"; msg="video unavailable (private/deleted)" ;;
    *"Private video"*) code="ERR-02"; msg="private video - sign in required" ;;
    *"Members-only"*) code="ERR-03"; msg="members-only content" ;;
    *"geo"*"restricted"*) code="ERR-04"; msg="geo-restricted in your region" ;;
    *"age restricted"*) code="ERR-05"; msg="age-restricted - needs cookies" ;;
    *"Sign in to confirm"*) code="ERR-06"; msg="bot detection - try again later" ;;
    *"No video formats found"*) code="ERR-07"; msg="no downloadable formats found" ;;
    *"Unsupported URL"*) code="ERR-13"; msg="unsupported URL - not a valid video link" ;;
    *) code="ERR-00"; msg="unknown error" ;;
  esac
  printf "\n  %s - %s  *  see github.com/onion3130/downterm/blob/main/docs/ERRORS.md\n" "$code" "$msg" >&2
  # --- Item 5: cleanup partial files on error ---
  rm -f ./*.part ./*.temp 2>/dev/null
  exit 1
fi
