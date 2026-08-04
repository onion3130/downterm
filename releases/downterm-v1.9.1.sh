#!/usr/bin/env bash
# downterm v1.9.1 — Linux edition
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

# Find script dir (so filter.sh works regardless of cwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for yt-dlp
if ! command -v yt-dlp >/dev/null 2>&1; then
  if [ -x "${SCRIPT_DIR}/yt-dlp" ]; then
    YTDLP="${SCRIPT_DIR}/yt-dlp"
  else
    printf "${BAD}  yt-dlp not found.${R}\n"
    printf "${FAINT}  install: sudo pip install yt-dlp${R}\n"
    exit 1
  fi
else
  YTDLP="yt-dlp"
fi

# Check for ffmpeg (optional but recommended)
FFARG=""
if command -v ffmpeg >/dev/null 2>&1; then
  FFARG="$(command -v ffmpeg)"
elif [ -x "${SCRIPT_DIR}/ffmpeg" ]; then
  FFARG="${SCRIPT_DIR}/ffmpeg"
fi

start() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v1.9.1${R}\n"
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

  download
}

download() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v1.9.1${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}acquiring${R}\n"
  printf "  ${FAINT}%s${R}\n" "$url"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  bash "${SCRIPT_DIR}/filter.sh" "$url" "$FFARG" "$YTDLP"
  local ec=$?
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  if [ $ec -gt 0 ]; then
    printf "  ${WARN}finished with warnings.${R}  ${FAINT}check above${R}\n"
  else
    printf "  ${GOOD}saved.${R}  ${FAINT}next to yt-dlp${R}\n"
  fi
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
  printf "  ${FAINT}https://www.youtube.com/watch?v=y4gzlFhfvPQ${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  bash "${SCRIPT_DIR}/filter.sh" "https://www.youtube.com/watch?v=y4gzlFhfvPQ" "$FFARG" "$YTDLP"
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
  printf "\n"
  printf "  ${MUT}commands${R}\n"
  printf "    ${INK}?${R}   ${FAINT}this screen${R}\n"
  printf "    ${INK}t${R}   ${FAINT}self-test (download a sample, then delete)${R}\n"
  printf "    ${INK}q${R}   ${FAINT}quit${R}\n"
  printf "\n"
  printf "  ${MUT}requires${R}\n"
  printf "    ${FAINT}- yt-dlp (pip install yt-dlp)${R}\n"
  printf "    ${FAINT}- ffmpeg (apt install ffmpeg)${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"
  printf "  ${FAINT}any key to go back.${R}\n"
  read -rn1 -s
  start
}

start
