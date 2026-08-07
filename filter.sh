#!/usr/bin/env bash
# downterm filter.sh — progress bar filter for yt-dlp (Linux/macOS)
# Usage: filter.sh <url> <ffmpeg_path> <yt-dlp_path> [mode] [quality] [output] [subs] [force] [sponsor]

url="${1:-}"
ff="${2:-}"
ytdlp="${3:-yt-dlp}"
mode="${4:-video}"
quality="${5:-best}"
output="${6:-}"
subs="${7:-0}"
force="${8:-0}"
sponsor="${9:-0}"
cookies="${10:-}"
audio="${11:-mp3}"
items="${12:-}"
embed="${13:-1}"
yt_args="${14:-}"
sub_langs="${15:-en.*,en}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"

if [[ ! "$url" =~ ^https?:// ]]; then
  printf "\n  ERR-13 - invalid URL  *  must start with http:// or https://\n" >&2
  exit 13
fi

if [ -n "$cookies" ] && [ ! -f "$cookies" ]; then
  printf "\n  ERR-14 - cookies file not found  *  pass a real path or remove COOKIES from downterm.conf\n" >&2
  printf "  %s\n" "$cookies" >&2
  exit 14
fi

case "$audio" in mp3|m4a|opus|wav|flac|aac) ;; *) audio=mp3 ;; esac

outTpl='%(title).200B [%(id)s].%(ext)s'
if [ -n "$output" ]; then
  mkdir -p "$output" 2>/dev/null || true
  outTpl="${output}/%(title).200B [%(id)s].%(ext)s"
fi

if [ "$mode" = "audio" ]; then
  aq='0'
  case "$quality" in
    medium) aq='5' ;;
    low)    aq='9' ;;
  esac
  args=(-x --audio-format "$audio" --audio-quality "$aq" -o "$outTpl" --newline --no-playlist)
else
  case "$quality" in
    2160) format='bv*[ext=mp4][height<=2160]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    1440) format='bv*[ext=mp4][height<=1440]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    1080) format='bv*[ext=mp4][height<=1080]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    720)  format='bv*[ext=mp4][height<=720]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    480)  format='bv*[ext=mp4][height<=480]+ba[ext=m4a]/b[ext=mp4]/b' ;;
    *)    format='bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b' ;;
  esac
  args=(-f "$format" --merge-output-format mp4 -o "$outTpl" --newline)
  if [[ ! "$url" =~ list= ]]; then
    args+=(--no-playlist)
  fi
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

if [ -n "$cookies" ]; then
  args+=(--cookies "$cookies")
fi

if [ "$mode" != "audio" ] && { [ "$subs" = "1" ] || [ "$subs" = "yes" ] || [ "$subs" = "true" ]; }; then
  args+=(--write-auto-subs --write-subs --sub-langs "$sub_langs" --embed-subs --convert-subs srt)
fi

if [ "$force" = "1" ] || [ "$force" = "yes" ] || [ "$force" = "true" ]; then
  args+=(--force-overwrites)
else
  args+=(--no-overwrites --continue)
fi

if [ "$mode" != "audio" ] && { [ "$sponsor" = "1" ] || [ "$sponsor" = "yes" ] || [ "$sponsor" = "true" ]; }; then
  args+=(--sponsorblock-remove "sponsor,selfpromo,interaction,intro,outro,preview")
fi

if [ -n "$items" ]; then
  args+=(--playlist-items "$items")
fi

if [ "$embed" = "1" ] || [ "$embed" = "yes" ] || [ "$embed" = "true" ]; then
  args+=(--embed-thumbnail --embed-metadata)
fi

if [ -n "$yt_args" ]; then
  # shellcheck disable=SC2206
  args+=($yt_args)
fi

args+=("$url")

skip_patterns='^\[youtube\]|^\[info\]|^\[Merger\]|^\[Deleting\]|^\[ExtractAudio\]|^\[EmbedSubtitle\]|^\[Metadata\]|^\[SponsorBlock\]|^\[SubtitlesConvertor\]|^\[download\]\s+Destination:'

err_buf="${TMPDIR:-/tmp}/downterm_err.$$"
: >"$err_buf"
trap 'rm -f "$err_buf" 2>/dev/null' EXIT
last_bar=false

set +e
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
    filled=""; empty=""
    for (( i=0; i<n; i++ )); do filled+='#'; done
    for (( i=n; i<30; i++ )); do empty+='-'; done
    printf "\r  %s%s  %s%%  %s MB/s  ETA %s   " "$filled" "$empty" "$pct" "$speed_mb" "$eta" >&2
    last_bar=true
  elif [[ "$line" =~ \[download\]\ +([0-9.]+)% ]]; then
    pct="${BASH_REMATCH[1]}"
    pct_int="${pct%.*}"
    [ -z "$pct_int" ] && pct_int=0
    n=$(( (pct_int * 30) / 100 ))
    filled=""; empty=""
    for (( i=0; i<n; i++ )); do filled+='#'; done
    for (( i=n; i<30; i++ )); do empty+='-'; done
    printf "\r  %s%s  %s%%   " "$filled" "$empty" "$pct" >&2
    last_bar=true
  elif echo "$line" | grep -qE "$skip_patterns"; then
    :
  elif [ -n "$line" ]; then
    if $last_bar; then printf '\n' >&2; last_bar=false; fi
    printf '%s\n' "$line" >&2
    printf '%s\n' "$line" >>"$err_buf"
  fi
done
pipe_ec=${PIPESTATUS[0]}
set +e

if $last_bar; then printf '\n' >&2; fi

if [ -f "$err_buf" ] && [ -s "$err_buf" ] && [ "${pipe_ec:-0}" -ne 0 ]; then
  err_out=$(cat "$err_buf" 2>/dev/null || true)
  err_lower=$(printf '%s' "$err_out" | tr '[:upper:]' '[:lower:]')
  case "$err_lower" in
    *"video unavailable"*) code="ERR-01"; msg="video unavailable (private/deleted)" ;;
    *"private video"*) code="ERR-02"; msg="private video - sign in required" ;;
    *"members-only"*) code="ERR-03"; msg="members-only content" ;;
    *"geo"*"restricted"*) code="ERR-04"; msg="geo-restricted in your region" ;;
    *"age restricted"*) code="ERR-05"; msg="age-restricted - needs cookies" ;;
    *"sign in to confirm"*) code="ERR-06"; msg="bot detection - try again later" ;;
    *"no video formats found"*) code="ERR-07"; msg="no downloadable formats found" ;;
    *"http error 4"*) code="ERR-08"; msg="HTTP 4xx from server" ;;
    *"http error 5"*) code="ERR-09"; msg="HTTP 5xx from server" ;;
    *"connection timed out"*|*"connection refused"*|*"connection reset"*) code="ERR-10"; msg="connection failed" ;;
    *ffmpeg*not*found*|*ffmpeg*not*installed*|*ffmpeg*missing*|*"unable to find"*ffmpeg*|*"could not find"*ffmpeg*) code="ERR-11"; msg="ffmpeg executable missing" ;;
    *deno*not*found*|*deno*not*installed*|*deno*missing*|*"unable to find"*deno*|*"could not find"*deno*) code="ERR-12"; msg="deno runtime missing" ;;
    *"unsupported url"*) code="ERR-13"; msg="unsupported URL - not a valid video link" ;;
    *) code="ERR-00"; msg="unknown error" ;;
  esac
  printf "\n  %s - %s  *  see github.com/onion3130/downterm/blob/main/docs/ERRORS.md\n" "$code" "$msg" >&2
  rm -f ./*.part ./*.temp 2>/dev/null || true
fi

exit "${pipe_ec:-0}"
