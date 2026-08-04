#!/usr/bin/env bash
# downterm filter.sh — progress bar filter for yt-dlp (Linux/macOS)
# Usage: filter.sh <url> <ffmpeg_path_or_empty> <yt-dlp_path>

url="${1:-}"
ff="${2:-}"
ytdlp="${3:-yt-dlp}"

args=(-f 'bv*+ba/b' --merge-output-format mp4 -o '%(title)s.%(ext)s' --newline)
if [ -n "$ff" ]; then
  args+=(--ffmpeg-location "$ff")
fi
args+=("$url")

last_bar=false
"$ytdlp" "${args[@]}" 2>&1 | while IFS= read -r line; do
  if [[ "$line" =~ \[download\]\ +([0-9.]+)% ]]; then
    pct="${BASH_REMATCH[1]}"
    # integer math for bar width (30 chars)
    pct_int="${pct%.*}"
    [ -z "$pct_int" ] && pct_int=0
    n=$(( (pct_int * 30) / 100 ))
    filled=""
    empty=""
    for (( i=0; i<n; i++ )); do filled+='#'; done
    for (( i=n; i<30; i++ )); do empty+='-'; done
    printf "\r  %s%s  %s%%   " "$filled" "$empty" "$pct" >&2
    last_bar=true
  else
    if $last_bar; then printf '\n' >&2; last_bar=false; fi
    [ -n "$line" ] && printf '%s\n' "$line" >&2
  fi
done
