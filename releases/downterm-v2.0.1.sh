#!/usr/bin/env bash
# downterm v2.0.1 — Linux edition
# A quiet wrapper around yt-dlp.

set -u

ESC="\033"
R="${ESC}[0m"
B="${ESC}[1m"
D="${ESC}[2m"
MUT="${ESC}[38;5;145m"
FAINT="${ESC}[38;5;240m"
HAIR="${ESC}[38;5;238m"
GOOD="${ESC}[38;5;108m"
BAD="${ESC}[38;5;174m"
INK="${ESC}[38;5;255m"
ACC="${ESC}[38;5;153m"
WARN="${ESC}[38;5;179m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for yt-dlp
if ! command -v yt-dlp >/dev/null 2>&1; then
  if [ -x "${SCRIPT_DIR}/yt-dlp" ]; then
    YTDLP="${SCRIPT_DIR}/yt-dlp"
  else
    printf "${BAD}  yt-dlp not found.${R}\n"
    printf "${FAINT}  install: pip install yt-dlp${R}\n"
    exit 1
  fi
else
  YTDLP="yt-dlp"
fi

# Check for ffmpeg
FFARG=""
if command -v ffmpeg >/dev/null 2>&1; then
  FFARG="$(command -v ffmpeg)"
elif [ -x "${SCRIPT_DIR}/ffmpeg" ]; then
  FFARG="${SCRIPT_DIR}/ffmpeg"
fi

start() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v2.0.1${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}a quiet wrapper around yt-dlp.${R}\n"
  printf "\n"
  printf "  ${FAINT}? help   t test   q quit${R}\n"
  printf "\n"
  printf "  ${INK}${B}<${R} "
  read -r url
  if [ -z "$url" ]; then
    printf "\n"
    printf "  ${BAD}nothing entered.${R}\n"
    printf "  ${FAINT}press any key...${R}\n"
    read -rn1 -s
    start
    return
  fi

  case "$url" in
    "?"|help) show_help; return ;;
    t|test) selftest; return ;;
    q|quit|exit) exit 0 ;;
  esac

  # Batch mode: input is an existing file
  if [ -f "$SCRIPT_DIR/$url" ] || [ -f "$url" ]; then
    local f="$url"
    [ -f "$SCRIPT_DIR/$url" ] && f="$SCRIPT_DIR/$url"
    batchmode "$f"
    return
  fi

  asktype
  askquality
  download "$url"
}

asktype() {
  printf "\n"
  printf "  ${FAINT}  v = video   a = audio (mp3)${R}\n"
  printf "  ${MUT}video or audio? (v/a) [${ink}v${MUT}]${R} "
  read -r mode
  case "$mode" in
    a|A|audio) MODE="audio" ;;
    *) MODE="video" ;;
  esac
}

askquality() {
  if [ "$MODE" = "audio" ]; then
    QUALITY="best"
    return
  fi
  printf "\n"
  printf "  ${FAINT}  b = best   1 = 1080p   7 = 720p   4 = 480p${R}\n"
  printf "  ${MUT}quality? (b/1/7/4) [${ink}b${MUT}]${R} "
  read -r quality
  case "$quality" in
    1) QUALITY="1080" ;;
    7) QUALITY="720" ;;
    4) QUALITY="480" ;;
    *) QUALITY="best" ;;
  esac
}

download() {
  local dl_url="$1"
  local counter="${2:-}"
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v2.0.1${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  if [ -n "$counter" ]; then
    printf "  ${MUT}%s${R}  ${FAINT}%s${R}\n" "$counter" "$dl_url"
  else
    printf "  ${MUT}acquiring${R}  ${FAINT}%s${R}\n" "$dl_url"
  fi
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  bash "${SCRIPT_DIR}/filter.sh" "$dl_url" "$FFARG" "$YTDLP" "$MODE" "$QUALITY"
  local ec=$?
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  if [ $ec -gt 0 ]; then
    printf "  ${WARN}finished with warnings.${R}  ${FAINT}check above${R}\n"
  else
    printf "  ${GOOD}saved.${R}\n"
  fi
  printf "\n"

  if [ -z "$counter" ]; then
    printf "  ${FAINT}any key to run again.${R}\n"
    read -rn1 -s
    start
  fi
}

batchmode() {
  local file="$1"
  printf "\n"
  printf "  ${MUT}batch file detected.${R}  ${FAINT}%s${R}\n" "$file"
  asktype
  askquality

  # Count URLs
  local total=0
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    total=$((total + 1))
  done < "$file"

  if [ $total -lt 1 ]; then
    printf "  ${BAD}no URLs found in %s${R}\n" "$file"
    printf "  ${FAINT}press any key...${R}\n"
    read -rn1 -s
    start
    return
  fi

  local current=0
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    current=$((current + 1))
    download "$line" "[$current/$total]"
  done < "$file"

  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "  ${GOOD}${total} done.${R}\n"
  printf "\n"
  printf "  ${FAINT}any key to run again.${R}\n"
  read -rn1 -s
  start
}

selftest() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}self-test${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}downloading test video...${R}\n"
  printf "  ${FAINT}https://www.youtube.com/watch?v=Rfyr7-dQnAg${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  bash "${SCRIPT_DIR}/filter.sh" "https://www.youtube.com/watch?v=Rfyr7-dQnAg" "$FFARG" "$YTDLP" "video" "best"
  local ec=$?
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  if [ $ec -gt 0 ]; then
    printf "  ${BAD}test failed.${R}  ${FAINT}check above for errors${R}\n"
    printf "\n"
    printf "  ${FAINT}press any key...${R}\n"
    read -rn1 -s
    start
    return
  fi

  printf "  ${GOOD}downloaded ok.${R}  ${MUT}cleaning up...${R}\n"
  printf "\n"

  local cleaned=0
  shopt -s nullglob
  for f in *.mp4 *.mkv *.webm *.mp3 *.m4a; do
    [ -f "$f" ] && rm -f -- "$f" && cleaned=1
  done
  shopt -u nullglob

  if [ $cleaned -eq 1 ]; then
    printf "  ${GOOD}test file removed.${R}\n"
  else
    printf "  ${FAINT}no downloaded file found to delete.${R}\n"
  fi
  printf "\n"
  printf "  ${FAINT}setup is working. press any key to go back.${R}\n"
  read -rn1 -s
  start
}

show_help() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}help${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}usage${R}\n"
  printf "    ${INK}<${R}  ${FAINT}url, then enter${R}\n"
  printf "    ${INK}<${R}  ${FAINT}urls.txt  (batch mode)${R}\n"
  printf "\n"
  printf "  ${MUT}prompts${R}\n"
  printf "    ${INK}v/a${R}     ${FAINT}video or audio (default: video)${R}\n"
  printf "    ${INK}b/1/7/4${R}  ${FAINT}best/1080p/720p/480p (default: best)${R}\n"
  printf "\n"
  printf "  ${MUT}commands${R}\n"
  printf "    ${INK}?${R}   ${FAINT}this screen${R}\n"
  printf "    ${INK}t${R}   ${FAINT}self-test (download a sample, then delete)${R}\n"
  printf "    ${INK}q${R}   ${FAINT}quit${R}\n"
  printf "\n"
  printf "  ${MUT}requires${R}\n"
  printf "    ${FAINT}- yt-dlp (pip install yt-dlp)${R}\n"
  printf "    ${FAINT}- ffmpeg (apt install ffmpeg)${R}\n"
  printf "    ${FAINT}- deno (curl -fsSL https://deno.land/install.sh | sh)${R}\n"
  printf "    ${FAINT}- bash 4+${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"
  printf "  ${FAINT}any key to go back.${R}\n"
  read -rn1 -s
  start
}

start
