#!/usr/bin/env bash
# downterm 4.1.0 — minimal terminal UI (numbers only). no window GUI.
#   downterm              → menu
#   downterm --version
#   downterm --update     → refresh yt-dlp (pinned) + check wrapper updates
#   downterm --install    → link ~/.local/bin/downterm (PATH)
#   downterm --cookies=FILE  → authenticate restricted content
#   downterm --audio-format=mp3|m4a|opus|wav  → preset for audio downloads
#   downterm --no-embed   → skip thumbnail/metadata embedding
set -u
if [ -n "${NO_COLOR:-}" ] || [ "${TERM:-}" = "dumb" ] || [ ! -t 1 ]; then
  ESC=""; R=""; MUT=""; FAINT=""; HAIR=""; GOOD=""; BAD=""; INK=""; ACC=""; WARN=""
else
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
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HISTORY_FILE="$SCRIPT_DIR/.downterm_history"
LAST_FILE="$SCRIPT_DIR/.downterm_last.txt"
MODE=video
QUALITY=best
SUBS=0
FORCE=0
SPONSOR=0
OUT=""
COOKIES=""
AUDIO=mp3
ITEMS=""
EMBED=1

# optional local defaults (downterm.conf, gitignored)
if [ -f "$SCRIPT_DIR/downterm.conf" ]; then
  while IFS='=' read -r k v; do
    k="$(printf '%s' "$k" | tr -d '[:space:]')"
    v="$(printf '%s' "$v" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$k" in
      MODE)        MODE="$v" ;;
      QUALITY)     QUALITY="$v" ;;
      OUTPUT)      OUT="$v" ;;
      SUBS)        SUBS="$v" ;;
      FORCE)       FORCE="$v" ;;
      SPONSORBLOCK) SPONSOR="$v" ;;
      COOKIES)     COOKIES="$v" ;;
      AUDIO_FORMAT) AUDIO="$v" ;;
      EMBED)       EMBED="$v" ;;
    esac
  done < "$SCRIPT_DIR/downterm.conf"
fi

YTDLP=""
if command -v yt-dlp >/dev/null 2>&1; then YTDLP="yt-dlp"
elif [ -x "$SCRIPT_DIR/yt-dlp" ]; then YTDLP="$SCRIPT_DIR/yt-dlp"; fi
FFARG=""
if command -v ffmpeg >/dev/null 2>&1; then FFARG="$(command -v ffmpeg)"
elif [ -x "$SCRIPT_DIR/ffmpeg" ]; then FFARG="$SCRIPT_DIR/ffmpeg"; fi

for _a in "$@"; do
  case "$_a" in
    --cookies=*)      COOKIES="${_a#--cookies=}" ;;
    --audio-format=*) AUDIO="${_a#--audio-format=}" ;;
    --no-embed)       EMBED=0 ;;
  esac
done

case "${1:-}" in
  --version) echo "downterm 4.1.0"; exit 0 ;;
  --install)
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$SCRIPT_DIR/download.sh" "$HOME/.local/bin/downterm"
    chmod +x "$SCRIPT_DIR/download.sh" "$SCRIPT_DIR/filter.sh" 2>/dev/null || true
    printf "  linked %s\n" "$HOME/.local/bin/downterm"
    printf "  open a NEW shell, then type:  downterm\n"
    if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
      printf "  if needed, add to ~/.bashrc or ~/.zshrc:\n"
      printf "    export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
    fi
    exit 0
    ;;
  --uninstall)
    rm -f "$HOME/.local/bin/downterm"
    printf "  removed ~/.local/bin/downterm\n"
    exit 0
    ;;
  --update)
    printf "  refreshing tools (yt-dlp / deno) to pinned versions ...\n"
    bash "$SCRIPT_DIR/setup.sh" --force-tools 2>/dev/null || true
    lt=$(curl -fsSL --max-time 15 "https://api.github.com/repos/onion3130/downterm/releases/latest" 2>/dev/null | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
    if [ -n "$lt" ] && [ "$lt" != "4.1.0" ]; then
      printf "\n  a newer downterm is available: %s\n" "$lt"
      printf "  downloading into %s ...\n" "$SCRIPT_DIR"
      if tmp=$(mktemp -d) && curl -fsSL --max-time 120 -o "$tmp/dl.tar.gz" "https://github.com/onion3130/downterm/archive/refs/tags/$lt.tar.gz" && tar -xzf "$tmp/dl.tar.gz" -C "$tmp" --strip-components=1; then
        cp -f "$tmp/download.sh" "$tmp/filter.sh" "$tmp/setup.sh" "$SCRIPT_DIR/" 2>/dev/null || true
        [ -f "$tmp/setup.ps1" ] && cp -f "$tmp/setup.ps1" "$SCRIPT_DIR/" 2>/dev/null || true
        chmod +x "$SCRIPT_DIR"/download.sh "$SCRIPT_DIR"/filter.sh "$SCRIPT_DIR"/setup.sh 2>/dev/null || true
        rm -rf "$tmp"
        printf "  ${GOOD}downterm updated to %s. restart downterm.${R}\n" "$lt"
      else
        rm -rf "$tmp"
        printf "  download failed — grab it at the releases page.\n"
      fi
    else
      printf "\n  downterm scripts are up to date. tools refreshed.\n"
    fi
    exit 0
    ;;
  --setup) bash "$SCRIPT_DIR/setup.sh" --skip-path; exit $? ;;
esac

get_clip() {
  local clip="" hint=""
  if command -v wl-paste >/dev/null 2>&1; then clip=$(wl-paste 2>/dev/null | head -1)
  elif command -v xclip >/dev/null 2>&1; then clip=$(xclip -selection clipboard -o 2>/dev/null | head -1)
  elif command -v pbpaste >/dev/null 2>&1; then clip=$(pbpaste 2>/dev/null | head -1)
  fi
  clip=$(printf '%s' "$clip" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [[ "$clip" =~ https?://[^[:space:]]+ ]]; then
    hint="${BASH_REMATCH[0]}"; hint="${hint%%[)\].,\"\']}"
  fi
  while :; do
    printf "\n"
    if [ -n "$hint" ]; then
      printf "  ${MUT}link${R}  ${FAINT}[Enter] to use clipboard:${R}\n  ${FAINT}%s${R}\n  ${MUT}>${R} " "$hint"
      URL="$hint"; read -r URL
      [ -z "$URL" ] && URL="$hint"
    else
      printf "  ${MUT}link${R}  ${FAINT}paste a video link${R}\n  ${MUT}>${R} "
      read -r URL
    fi
    if [ -z "$URL" ]; then
      printf "  ${BAD}no link — paste a video URL.${R}\n"; read -rn1 -s; continue
    fi
    if [[ "$URL" =~ ^https?:// ]]; then
      printf "  ${MUT}link${R}  ${FAINT}%s${R}\n" "$URL"; return 0
    fi
    printf "  ${BAD}not a link — needs http:// or https://${R}\n"; read -rn1 -s
  done
}

read_key() {
  local k
  if [ -t 0 ]; then read -rsn1 k; printf '%s' "$k"
  else read -r k; printf '%s' "${k:0:1}"; fi
}

available_yt() {
  if [ -n "$YTDLP" ]; then printf '%s' "$YTDLP"
  elif [ -x "$SCRIPT_DIR/yt-dlp" ]; then printf '%s' "$SCRIPT_DIR/yt-dlp"
  elif command -v yt-dlp >/dev/null 2>&1; then printf 'yt-dlp'
  fi
}

run_dl() {
  clear
  printf "\n  ${ACC}downterm${R}\n  ${HAIR}..........................................${R}\n\n"
  printf "  ${MUT}downloading${R}\n  ${FAINT}%s${R}\n\n" "$URL"
  if [ -n "$ITEMS" ]; then printf "  ${FAINT}playlist items: ${INK}%s${R}\n\n" "$ITEMS"; fi
  printf "  ${HAIR}------------------------------------------${R}\n\n"
  if [ -z "$YTDLP" ] && [ ! -x "$SCRIPT_DIR/yt-dlp" ] && ! command -v yt-dlp >/dev/null 2>&1; then
    printf "  ${BAD}yt-dlp missing — setup first${R}\n"; read -rn1 -s; return
  fi
  printf '%s\n' "$URL" > "$LAST_FILE"
  printf '%s\n' "$URL" >> "$HISTORY_FILE"
  bash "$SCRIPT_DIR/filter.sh" "$URL" "$FFARG" "$YTDLP" "$MODE" "$QUALITY" "$OUT" "$SUBS" "$FORCE" "$SPONSOR" "$COOKIES" "$AUDIO" "$ITEMS" "$EMBED"
  local ec=$?
  printf "\n  ${HAIR}------------------------------------------${R}\n"
  if [ $ec -eq 0 ]; then printf "  ${GOOD}saved.${R}\n"; else printf "  ${WARN}not saved cleanly.${R}\n"; fi
  printf "\n  ${FAINT}any key...${R}\n"; read -rn1 -s
}

pick_quality() {
  clear
  printf "\n  ${ACC}quality${R}\n\n"
  printf "  ${INK}1${R} best  ${INK}2${R} 2160  ${INK}3${R} 1080  ${INK}4${R} 720  ${INK}5${R} 480  ${INK}6${R} 1440  ${INK}7${R} back\n\n  ${MUT}>${R} "
  local q; q=$(read_key); echo
  case "$q" in
    1) QUALITY=best ;; 2) QUALITY=2160 ;; 3) QUALITY=1080 ;; 4) QUALITY=720 ;;
    5) QUALITY=480 ;; 6) QUALITY=1440 ;; *) return 1 ;;
  esac
  printf "\n  ${INK}1${R} now  ${INK}2${R} +subs  ${INK}3${R} +sponsor  ${INK}4${R} both\n\n  ${MUT}>${R} "
  local e; e=$(read_key); echo
  SUBS=0; SPONSOR=0
  case "$e" in 2) SUBS=1 ;; 3) SPONSOR=1 ;; 4) SUBS=1; SPONSOR=1 ;; esac
  return 0
}

pick_audio() {
  clear
  printf "\n  ${ACC}audio format${R}\n\n"
  printf "  ${INK}1${R} mp3  ${INK}2${R} m4a  ${INK}3${R} opus  ${INK}4${R} wav\n\n  ${MUT}>${R} "
  local a; a=$(read_key); echo
  case "$a" in 2) AUDIO=m4a ;; 3) AUDIO=opus ;; 4) AUDIO=wav ;; *) AUDIO=mp3 ;; esac
}

playlist_pick() {
  clear
  printf "\n  ${ACC}playlist${R}\n  ${HAIR}..........................................${R}\n\n"
  local yt; yt=$(available_yt)
  if [ -z "$yt" ]; then
    printf "  ${BAD}yt-dlp missing — setup first${R}\n"; read -rn1 -s; return 1
  fi
  if ! get_clip; then
    printf "  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; return 1
  fi
  printf "  ${MUT}link${R}  ${FAINT}%s${R}\n" "$URL"
  local plist="$SCRIPT_DIR/.downterm_playlist"
  printf "  ${MUT}scanning playlist ...${R}\n"
  "$yt" --flat-playlist --print '%(id)s|%(title)s' --no-warnings "$URL" > "$plist" 2>/dev/null || true
  local i=0 row
  local rows=()
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    rows[$i]=$line; i=$((i+1))
    [ $i -ge 25 ] && break
  done < "$plist"
  if [ ${#rows[@]} -eq 0 ]; then
    printf "  ${BAD}no items found — not a playlist?${R}\n"; read -rn1 -s; return 1
  fi
  clear
  printf "\n  ${ACC}playlist${R}\n\n"
  local n=0
  for row in "${rows[@]:-}"; do
    n=$((n+1))
    printf "  ${INK}%2d${R}  %s\n" "$n" "${row#*|}"
  done
  printf "\n  pick:  all  |  1-3  |  2,5,7   (Enter)\n  ${MUT}>${R} "
  local sel; read -r sel
  case "$sel" in
    *all*|'') ITEMS= ;;
    *) ITEMS="$(printf '%s' "$sel" | tr -d '[:space:]')" ;;
  esac
  if [ -n "$ITEMS" ]; then printf "  ${FAINT}items: %s${R}\n" "$ITEMS"; fi
  MODE=video; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0
  printf "\n${INK}1${R} download  ${INK}2${R} audio\n  ${MUT}>${R} "
  local pb; pb=$(read_key); echo
  if [ "$pb" = "2" ]; then MODE=audio; fi
  return 0
}

install_path() {
  clear
  printf "\n  ${ACC}install PATH${R}\n  ${HAIR}..........................................${R}\n\n"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$SCRIPT_DIR/download.sh" "$HOME/.local/bin/downterm"
  chmod +x "$SCRIPT_DIR/download.sh" "$SCRIPT_DIR/filter.sh" 2>/dev/null || true
  printf "  ${GOOD}linked${R}  ${FAINT}%s${R}\n" "$HOME/.local/bin/downterm"
  printf "\n  ${FAINT}open a new shell, then type:${R}\n\n    ${INK}downterm${R}\n"
  if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    printf "\n  ${WARN}add to shell rc if needed:${R}\n"
    printf "    export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
  fi
  printf "\n  ${FAINT}any key...${R}\n"; read -rn1 -s
}

menu() {
  while true; do
    clear
    printf "\n  ${ACC}downterm${R}  ${FAINT}4.1.0${R}\n"
    printf "  ${HAIR}..........................................${R}\n\n"
    printf "  ${MUT}pick a number, then paste a link.${R}\n\n"
    printf "  ${INK}1${R}  best video\n"
    printf "  ${INK}2${R}  pick quality\n"
    printf "  ${INK}3${R}  audio only\n"
    printf "  ${INK}4${R}  history\n"
    printf "  ${INK}5${R}  open folder\n"
    printf "  ${INK}6${R}  setup tools\n"
    printf "  ${INK}7${R}  add to PATH  →  type  downterm  anywhere\n"
    printf "  ${INK}8${R}  help\n"
    printf "  ${INK}9${R}  quit\n"
    printf "  ${INK}0${R}  playlist · pick items\n\n  ${MUT}>${R} "
    local c; c=$(read_key); echo
    case "$c" in
      1) if get_clip; then MODE=video; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0; ITEMS=; run_dl
         else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi ;;
      2) if get_clip; then MODE=video; FORCE=0; ITEMS=; pick_quality && run_dl
         else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi ;;
      3) if get_clip; then MODE=audio; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0; ITEMS=; pick_audio && run_dl
         else printf "\n  ${BAD}no link in clipboard.${R}\n"; read -rn1 -s; fi ;;
      4)
        clear; printf "\n  ${ACC}history${R}\n\n"
        if [ ! -s "$HISTORY_FILE" ]; then printf "  ${FAINT}empty${R}\n"; read -rn1 -s; continue; fi
        mapfile -t lines < <(grep -v '^[[:space:]]*$' "$HISTORY_FILE" | tail -n 9)
        local i=1; for line in "${lines[@]}"; do printf "  ${INK}%s${R}  %s\n" "$i" "$line"; i=$((i+1)); done
        printf "  ${INK}0${R}  back\n\n  ${MUT}>${R} "
        local h; h=$(read_key); echo
        [[ "$h" =~ ^[1-9]$ ]] || continue
        local idx=$((h-1)); [ "$idx" -lt "${#lines[@]}" ] || continue
        URL="${lines[$idx]}"; MODE=video; QUALITY=best; SUBS=0; SPONSOR=0; FORCE=0; ITEMS=; run_dl
        ;;
      5) command -v xdg-open >/dev/null 2>&1 && xdg-open "$SCRIPT_DIR" >/dev/null 2>&1 &
         command -v open >/dev/null 2>&1 && open "$SCRIPT_DIR" >/dev/null 2>&1 &
         ;;
      6)
        clear; printf "\n  ${ACC}setup${R}\n\n"
        if [ -n "$YTDLP" ]; then printf "  ${FAINT}yt-dlp present${R}\n"
        elif [ -f "$SCRIPT_DIR/bin/checksums.txt" ]; then
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
        if command -v ffmpeg >/dev/null 2>&1; then printf "  ${FAINT}ffmpeg present${R}\n"
        else printf "  ${WARN}install ffmpeg via package manager${R}\n"; fi
        printf "\n  ${FAINT}any key...${R}\n"; read -rn1 -s
        ;;
      7) install_path ;;
      8)
        clear
        printf "\n  ${ACC}help${R}  ${FAINT}4.1.0${R}\n\n"
        printf "  Copy a link → press 1 for best video.\n"
        printf "  Press 7 once (or: ./download.sh --install)\n"
        printf "  Open a NEW shell → type:  downterm\n\n"
        printf "  ${ACC}new in 4.0${R}\n"
        printf "   0  playlist      pick which items\n"
        printf "   3  audio mp3     use --audio-format=m4a|opus|wav\n"
        printf "   cookies          downterm --cookies=file.txt\n"
        printf "   metadata         embedded by default (--no-embed to skip)\n"
        printf "   update           ./download.sh --update\n\n"
        printf "  ${FAINT}any key...${R}\n"; read -rn1 -s
        ;;
      9|q|Q) exit 0 ;;
    esac
  done
}

menu