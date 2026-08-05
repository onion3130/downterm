#!/usr/bin/env bash
# downterm v2.5 — menu-first (no URL typing). numbers only.

set -u
ESC="\033"
R="${ESC}[0m"
MUT="${ESC}[38;5;145m"
FAINT="${ESC}[38;5;240m"
HAIR="${ESC}[38;5;238m"
GOOD="${ESC}[38;5;108m"
BAD="${ESC}[38;5;174m"
INK="${ESC}[38;5;255m"
ACC="${ESC}[38;5;153m"
WARN="${ESC}[38;5;179m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="$SCRIPT_DIR/.downterm_history"
LAST_FILE="$SCRIPT_DIR/.downterm_last.txt"
MODE=video
QUALITY=best
SUBS=0
FORCE=0
SPONSOR=0
OUT=""

YTDLP=""
if command -v yt-dlp >/dev/null 2>&1; then YTDLP="yt-dlp"
elif [ -x "$SCRIPT_DIR/yt-dlp" ]; then YTDLP="$SCRIPT_DIR/yt-dlp"; fi
FFARG=""
if command -v ffmpeg >/dev/null 2>&1; then FFARG="$(command -v ffmpeg)"
elif [ -x "$SCRIPT_DIR/ffmpeg" ]; then FFARG="$SCRIPT_DIR/ffmpeg"; fi

if [ "${1:-}" = "--version" ]; then echo "downterm v2.5"; exit 0; fi
if [ "${1:-}" = "--setup" ]; then
  # minimal: point users at interactive setup path via menu item 7
  echo "Run ./download.sh and press 7 for setup."
  exit 0
fi

get_clip() {
  local clip=""
  if command -v wl-paste >/dev/null 2>&1; then clip=$(wl-paste 2>/dev/null | head -1)
  elif command -v xclip >/dev/null 2>&1; then clip=$(xclip -selection clipboard -o 2>/dev/null | head -1)
  elif command -v pbpaste >/dev/null 2>&1; then clip=$(pbpaste 2>/dev/null | head -1)
  fi
  clip=$(printf '%s' "$clip" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ "$clip" =~ https?://[^[:space:]]+ ]]; then
    URL="${BASH_REMATCH[0]}"
    URL="${URL%%[)\].,\"\']}"
    return 0
  fi
  return 1
}

read_key() {
  # single character, no enter required when possible
  local k
  if [ -t 0 ]; then
    read -rsn1 k
    printf '%s' "$k"
  else
    read -r k
    printf '%s' "${k:0:1}"
  fi
}

run_dl() {
  clear
  printf "\n  ${ACC}downterm${R}\n"
  printf "  ${HAIR}..........................................${R}\n\n"
  printf "  ${MUT}downloading${R}\n  ${FAINT}%s${R}\n\n" "$URL"
  printf "  ${HAIR}------------------------------------------${R}\n\n"
  if [ -z "$YTDLP" ]; then
    printf "  ${BAD}yt-dlp missing — press 7 for setup${R}\n"
    read -rn1 -s
    return
  fi
  printf '%s\n' "$URL" > "$LAST_FILE"
  printf '%s\n' "$URL" >> "$HISTORY_FILE"
  bash "$SCRIPT_DIR/filter.sh" "$URL" "$FFARG" "$YTDLP" "$MODE" "$QUALITY" "$OUT" "$SUBS" "$FORCE" "$SPONSOR"
  local ec=$?
  printf "\n  ${HAIR}------------------------------------------${R}\n"
  if [ $ec -eq 0 ]; then printf "  ${GOOD}saved.${R}\n"; else printf "  ${WARN}not saved cleanly.${R}\n"; fi
  printf "\n  ${FAINT}any key...${R}\n"
  read -rn1 -s
}

pick_quality() {
  clear
  printf "\n  ${ACC}quality${R}\n  ${HAIR}..........................................${R}\n\n"
  printf "  ${INK}1${R}  best\n  ${INK}2${R}  1080p\n  ${INK}3${R}  720p\n  ${INK}4${R}  480p\n  ${INK}5${R}  1440p\n  ${INK}6${R}  4K\n  ${INK}7${R}  back\n\n  ${MUT}>${R} "
  local q; q=$(read_key); echo
  case "$q" in
    1) QUALITY=best ;;
    2) QUALITY=1080 ;;
    3) QUALITY=720 ;;
    4) QUALITY=480 ;;
    5) QUALITY=1440 ;;
    6) QUALITY=2160 ;;
    *) return 1 ;;
  esac
  printf "\n  ${FAINT}extras?${R}\n  ${INK}1${R} now  ${INK}2${R} +subs  ${INK}3${R} +sponsor  ${INK}4${R} both\n\n  ${MUT}>${R} "
  local e; e=$(read_key); echo
  SUBS=0; SPONSOR=0
  case "$e" in
    2) SUBS=1 ;;
    3) SPONSOR=1 ;;
    4) SUBS=1; SPONSOR=1 ;;
  esac
  return 0
}

menu() {
  while true; do
    clear
    printf "\n  ${ACC}downterm${R}  ${FAINT}v2.5${R}\n"
    printf "  ${HAIR}..........................................${R}\n\n"
    printf "  ${MUT}no typing. pick a number.${R}\n\n"
    printf "  ${INK}1${R}  paste link  ·  download best video\n"
    printf "  ${INK}2${R}  paste link  ·  pick quality\n"
    printf "  ${INK}3${R}  paste link  ·  audio only\n"
    printf "  ${INK}4${R}  history\n"
    printf "  ${INK}5${R}  open folder\n"
    printf "  ${INK}6${R}  help\n"
    printf "  ${INK}7${R}  setup\n"
    printf "  ${INK}8${R}  quit\n\n  ${MUT}>${R} "
    local c; c=$(read_key); echo
    case "$c" in
      1)
        if get_clip; then MODE=video; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0; run_dl
        else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi
        ;;
      2)
        if get_clip; then MODE=video; FORCE=0
          if pick_quality; then run_dl; fi
        else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi
        ;;
      3)
        if get_clip; then MODE=audio; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0; run_dl
        else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi
        ;;
      4)
        clear
        printf "\n  ${ACC}history${R}\n\n"
        if [ ! -s "$HISTORY_FILE" ]; then printf "  ${FAINT}empty${R}\n"; read -rn1 -s; continue; fi
        mapfile -t lines < <(grep -v '^[[:space:]]*$' "$HISTORY_FILE" | tail -n 9)
        local i=1
        for line in "${lines[@]}"; do printf "  ${INK}%s${R}  %s\n" "$i" "$line"; i=$((i+1)); done
        printf "  ${INK}0${R}  back\n\n  ${MUT}>${R} "
        local h; h=$(read_key); echo
        [[ "$h" =~ ^[1-9]$ ]] || continue
        local idx=$((h-1))
        [ "$idx" -lt "${#lines[@]}" ] || continue
        URL="${lines[$idx]}"
        MODE=video; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0
        run_dl
        ;;
      5)
        if command -v xdg-open >/dev/null 2>&1; then xdg-open "$SCRIPT_DIR" >/dev/null 2>&1 &
        elif command -v open >/dev/null 2>&1; then open "$SCRIPT_DIR" >/dev/null 2>&1 &
        fi
        ;;
      6)
        clear
        printf "\n  ${ACC}help${R}\n\n"
        printf "  Copy a video link in your browser.\n"
        printf "  Press ${INK}1${R} here — best video downloads.\n"
        printf "  Press ${INK}2${R} to pick quality with numbers only.\n\n"
        printf "  ${FAINT}any key...${R}\n"; read -rn1 -s
        ;;
      7)
        clear
        printf "\n  ${ACC}setup${R}\n\n"
        if [ -x "$SCRIPT_DIR/yt-dlp" ] || command -v yt-dlp >/dev/null 2>&1; then
          printf "  ${FAINT}yt-dlp present${R}\n"
        else
          printf "  ${MUT}fetching yt-dlp...${R}\n"
          # reuse old setup logic lightly via checksums if present
          if [ -f "$SCRIPT_DIR/bin/checksums.txt" ]; then
            plat=yt-dlp_linux
            case "$(uname -s)-$(uname -m)" in Darwin-*) plat=yt-dlp_macos ;; Linux-aarch64|Linux-arm64) plat=yt-dlp_linux_aarch64 ;; esac
            url=$(awk -v p="$plat" '$1==p{print $4}' "$SCRIPT_DIR/bin/checksums.txt")
            hash=$(awk -v p="$plat" '$1==p{print $3}' "$SCRIPT_DIR/bin/checksums.txt")
            if [ -n "$url" ]; then
              curl -fL -o "$SCRIPT_DIR/yt-dlp.tmp" "$url" && \
              echo "$hash  $SCRIPT_DIR/yt-dlp.tmp" | (sha256sum -c - 2>/dev/null || shasum -a 256 -c -) && \
              mv "$SCRIPT_DIR/yt-dlp.tmp" "$SCRIPT_DIR/yt-dlp" && chmod +x "$SCRIPT_DIR/yt-dlp" && YTDLP="$SCRIPT_DIR/yt-dlp" && \
              printf "  ${GOOD}yt-dlp ok${R}\n" || printf "  ${BAD}fetch failed${R}\n"
            fi
          fi
        fi
        if command -v ffmpeg >/dev/null 2>&1; then printf "  ${FAINT}ffmpeg present${R}\n"
        else printf "  ${WARN}install ffmpeg via package manager${R}\n"; fi
        printf "\n  ${FAINT}any key...${R}\n"; read -rn1 -s
        ;;
      8|q|Q) exit 0 ;;
    esac
  done
}

menu
