#!/usr/bin/env bash
# downterm v2.4 — Linux/macOS edition
# A quiet wrapper around yt-dlp.

set -u

ESC="\033"
R="${ESC}[0m"
B="${ESC}[1m"
MUT="${ESC}[38;5;145m"
FAINT="${ESC}[38;5;240m"
HAIR="${ESC}[38;5;238m"
GOOD="${ESC}[38;5;108m"
BAD="${ESC}[38;5;174m"
INK="${ESC}[38;5;255m"
ACC="${ESC}[38;5;153m"
WARN="${ESC}[38;5;179m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$SCRIPT_DIR"
HISTORY_FILE="$SCRIPT_DIR/.downterm_history"
LAST_FILE="$SCRIPT_DIR/.downterm_last.txt"

MODE="video"
QUALITY="best"
SUBS="0"
FORCE="0"
SPONSOR="0"
OUT=""

verify_hash() {
  local f="$1" expected="$2"
  local actual
  if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$f" | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    actual=$(shasum -a 256 "$f" | awk '{print $1}')
  else
    printf "  ${BAD}neither sha256sum nor shasum found.${R}\n"
    return 2
  fi
  if [ "$actual" = "$expected" ]; then
    return 0
  fi
  printf "  ${BAD}checksum mismatch.${R}\n"
  printf "  ${FAINT}expected: %s${R}\n" "$expected"
  printf "  ${FAINT}actual:   %s${R}\n" "$actual"
  return 1
}

setup_fail() {
  rm -f "$SCRIPT_DIR/yt-dlp.tmp" "$SCRIPT_DIR/deno.zip.tmp" "$SCRIPT_DIR/deno.zip" 2>/dev/null
  printf "\n"
  printf "  ${BAD}setup failed.${R}  ${FAINT}see message above.${R}\n"
  printf "  ${FAINT}github.com/onion3130/downterm/issues${R}\n"
  printf "\n  ${FAINT}press any key...${R}\n"
  read -rn1 -s
  return 1
}

do_setup() {
  set +e
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}setup${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}fetching pinned binaries...${R}\n"
  printf "  ${FAINT}see bin/checksums.txt for versions and hashes${R}\n"
  printf "\n"

  local cf="$SCRIPT_DIR/bin/checksums.txt"
  if [ ! -f "$cf" ]; then
    printf "  ${BAD}bin/checksums.txt not found.${R}\n"
    printf "\n  ${FAINT}press any key...${R}\n"
    read -rn1 -s
    return 1
  fi

  local platkey denoplatkey
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64|Linux-amd64) platkey="yt-dlp_linux" ;;
    Linux-aarch64|Linux-arm64) platkey="yt-dlp_linux_aarch64" ;;
    Darwin-x86_64|Darwin-arm64) platkey="yt-dlp_macos" ;;
    *) platkey="yt-dlp_linux" ;;
  esac
  case "$(uname -s)-$(uname -m)" in
    Linux-*) denoplatkey="deno_linux" ;;
    Darwin-*) denoplatkey="deno_macos" ;;
    *) denoplatkey="deno_linux" ;;
  esac

  local yt_url yt_hash deno_url deno_hash
  while read -r k v h u rest; do
    case "$k" in
      ''|\#*) continue ;;
      "$platkey") yt_url="$u"; yt_hash="$h" ;;
      "$denoplatkey") deno_url="$u"; deno_hash="$h" ;;
    esac
  done < "$cf"

  local myytdlp="$SCRIPT_DIR/yt-dlp"
  if [ -x "$myytdlp" ] || command -v yt-dlp >/dev/null 2>&1; then
    printf "  ${FAINT}yt-dlp already present, skipping.${R}\n"
  elif [ -n "${yt_url:-}" ]; then
    printf "  ${MUT}fetching yt-dlp...${R}\n"
    if curl -fL -o "$myytdlp.tmp" "$yt_url" 2>/dev/null; then
      if verify_hash "$myytdlp.tmp" "$yt_hash"; then
        mv "$myytdlp.tmp" "$myytdlp"
        chmod +x "$myytdlp"
        YTDLP="$myytdlp"
        printf "  ${GOOD}yt-dlp verified.${R}\n"
      else
        rm -f "$myytdlp.tmp"
        setup_fail
        return 1
      fi
    else
      printf "  ${BAD}download failed for yt-dlp.${R}\n"
      setup_fail
      return 1
    fi
  else
    printf "  ${BAD}no checksum entry for $platkey.${R}\n"
    setup_fail
    return 1
  fi

  if command -v ffmpeg >/dev/null 2>&1; then
    printf "  ${FAINT}ffmpeg already on PATH, skipping.${R}\n"
  else
    printf "  ${WARN}ffmpeg not found.${R}  ${FAINT}install via package manager.${R}\n"
  fi

  local mydeno="$SCRIPT_DIR/deno"
  if [ -x "$mydeno" ] || command -v deno >/dev/null 2>&1; then
    printf "  ${FAINT}deno already present, skipping.${R}\n"
  elif [ -n "${deno_url:-}" ] && command -v unzip >/dev/null 2>&1; then
    printf "  ${MUT}fetching deno.zip...${R}\n"
    if curl -fL -o "$SCRIPT_DIR/deno.zip.tmp" "$deno_url" 2>/dev/null; then
      if verify_hash "$SCRIPT_DIR/deno.zip.tmp" "$deno_hash"; then
        mv "$SCRIPT_DIR/deno.zip.tmp" "$SCRIPT_DIR/deno.zip"
        (cd "$SCRIPT_DIR" && unzip -oq deno.zip && rm -f deno.zip)
        [ -x "$mydeno" ] && printf "  ${GOOD}deno verified.${R}\n"
      else
        rm -f "$SCRIPT_DIR/deno.zip.tmp"
        printf "  ${WARN}deno checksum failed; skipping.${R}\n"
      fi
    else
      printf "  ${WARN}deno download failed; skipping.${R}\n"
    fi
  fi

  printf "\n  ${GOOD}setup complete.${R}\n"
  printf "\n  ${FAINT}press any key...${R}\n"
  read -rn1 -s
  return 0
}

show_version() {
  echo "downterm v2.4"
  echo ""
  echo "  ${FAINT}pinned (bin/checksums.txt):${R}"
  echo "    yt-dlp  2026.07.04"
  echo "    ffmpeg  9.0"
  echo "    deno    2.9.4"
  echo ""
  echo "  ${FAINT}installed:${R}"
  if [ -x "$DIR/yt-dlp" ] || command -v yt-dlp >/dev/null 2>&1; then
    local ytdlpcmd="$DIR/yt-dlp"; [ -x "$ytdlpcmd" ] || ytdlpcmd="yt-dlp"
    echo "    yt-dlp  $("$ytdlpcmd" --version 2>/dev/null | head -1)"
  else
    echo "    yt-dlp  ${WARN}not installed - run 's'${R}"
  fi
  if command -v ffmpeg >/dev/null 2>&1; then
    echo "    ffmpeg $(ffmpeg -version 2>/dev/null | head -1 | awk '{print $1, $2, $3}')"
  else
    echo "    ffmpeg  ${WARN}not installed${R}"
  fi
  if [ -x "$DIR/deno" ] || command -v deno >/dev/null 2>&1; then
    local denocmd="$DIR/deno"; [ -x "$denocmd" ] || denocmd="deno"
    echo "    deno    $("$denocmd" --version 2>/dev/null | head -1)"
  else
    echo "    deno    ${WARN}not installed - run 's'${R}"
  fi
}

save_last() {
  printf '%s\n' "$1" > "$LAST_FILE"
}

save_history() {
  local u="$1"
  [ -z "$u" ] && return 0
  printf '%s\n' "$u" >> "$HISTORY_FILE"
  if [ -f "$HISTORY_FILE" ]; then
    tail -n 30 "$HISTORY_FILE" > "$HISTORY_FILE.tmp" 2>/dev/null && mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
  fi
}

show_help() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}help  v2.4${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}usage${R}\n"
  printf "    ${INK}<${R}  ${FAINT}url or urls.txt${R}\n"
  printf "\n"
  printf "  ${MUT}prompts${R}\n"
  printf "    ${INK}v/a${R}         ${FAINT}video or audio${R}\n"
  printf "    ${INK}b/k/2/1/7/4${R}  ${FAINT}best/4K/1440/1080/720/480${R}\n"
  printf "    ${INK}subs / sponsor / force${R}\n"
  printf "\n"
  printf "  ${MUT}commands${R}\n"
  printf "    ${INK}p${R} paste clipboard   ${INK}h${R} history   ${INK}o${R} open folder\n"
  printf "    ${INK}i${R} info              ${INK}t${R} test      ${INK}r${R} redo\n"
  printf "    ${INK}s${R} setup             ${INK}?${R} help      ${INK}q${R} quit\n"
  printf "\n"
  printf "  ${MUT}flags${R}\n"
  printf "    ${FAINT}--mode= --quality= --output= --subs --force --sponsorblock${R}\n"
  printf "\n"
  printf "  ${FAINT}any key to go back.${R}\n"
  read -rn1 -s
  start
}

asktype() {
  printf "\n"
  printf "  ${FAINT}  v = video   a = audio (mp3)${R}\n"
  printf "  ${MUT}video or audio? (v/a) [v]${R} "
  read -r mode
  case "$mode" in
    a|A|audio) MODE="audio" ;;
    *) MODE="video" ;;
  esac
}

askquality() {
  if [ "$MODE" = "audio" ]; then
    printf "\n"
    printf "  ${FAINT}  b = best   m = medium   l = low${R}\n"
    printf "  ${MUT}audio quality? (b/m/l) [b]${R} "
    read -r quality
    case "$quality" in
      m|M|medium) QUALITY="medium" ;;
      l|L|low) QUALITY="low" ;;
      *) QUALITY="best" ;;
    esac
    return
  fi
  printf "\n"
  printf "  ${FAINT}  b=best  k=4K  2=1440  1=1080  7=720  4=480${R}\n"
  printf "  ${MUT}quality? (b/k/2/1/7/4) [b]${R} "
  read -r quality
  case "$quality" in
    k|K) QUALITY="2160" ;;
    2) QUALITY="1440" ;;
    1) QUALITY="1080" ;;
    7) QUALITY="720" ;;
    4) QUALITY="480" ;;
    *) QUALITY="best" ;;
  esac
}

askextras() {
  if [ "$MODE" = "audio" ]; then
    SUBS="0"
    SPONSOR="0"
  else
    printf "\n"
    printf "  ${MUT}embed English subs? (y/n) [n]${R} "
    read -r s
    case "$s" in y|Y) SUBS="1" ;; *) SUBS="0" ;; esac
    printf "  ${MUT}SponsorBlock remove? (y/n) [n]${R} "
    read -r sp
    case "$sp" in y|Y) SPONSOR="1" ;; *) SPONSOR="0" ;; esac
  fi
  printf "  ${MUT}overwrite if exists? (y/n) [n]${R} "
  read -r f
  case "$f" in y|Y) FORCE="1" ;; *) FORCE="0" ;; esac
}

download() {
  local dl_url="$1"
  local counter="${2:-}"
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v2.4${R}\n"
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

  bash "${SCRIPT_DIR}/filter.sh" "$dl_url" "$FFARG" "$YTDLP" "$MODE" "$QUALITY" "${OUT:-}" "$SUBS" "$FORCE" "$SPONSOR"
  local ec=$?
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  if [ $ec -gt 0 ]; then
    printf "  ${WARN}finished with warnings.${R}\n"
  else
    printf "  ${GOOD}saved.${R}\n"
  fi
  printf "\n"

  if [ -z "$counter" ]; then
    printf "  ${FAINT}any key to run again.${R}\n"
    read -rn1 -s
    start
  fi
  return $ec
}

batchmode() {
  local file="$1"
  printf "\n"
  printf "  ${MUT}batch file detected.${R}  ${FAINT}%s${R}\n" "$file"
  asktype
  askquality
  askextras

  local total=0
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    total=$((total + 1))
  done < "$file"

  if [ $total -lt 1 ]; then
    printf "  ${BAD}no URLs found${R}\n"
    read -rn1 -s
    start
    return
  fi

  local current=0
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    current=$((current + 1))
    save_history "$line"
    download "$line" "[$current/$total]"
  done < "$file"

  printf "\n  ${GOOD}%s done.${R}\n" "$total"
  printf "  ${FAINT}any key...${R}\n"
  read -rn1 -s
  start
}

paste_clip() {
  local clip=""
  if command -v wl-paste >/dev/null 2>&1; then
    clip=$(wl-paste 2>/dev/null | head -1 | tr -d '\r')
  elif command -v xclip >/dev/null 2>&1; then
    clip=$(xclip -selection clipboard -o 2>/dev/null | head -1 | tr -d '\r')
  elif command -v xsel >/dev/null 2>&1; then
    clip=$(xsel --clipboard --output 2>/dev/null | head -1 | tr -d '\r')
  elif command -v pbpaste >/dev/null 2>&1; then
    clip=$(pbpaste 2>/dev/null | head -1 | tr -d '\r')
  fi
  clip=$(printf '%s' "$clip" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  if [ -z "$clip" ]; then
    printf "\n  ${BAD}clipboard empty or no paste tool (wl-paste/xclip/pbpaste).${R}\n"
    read -rn1 -s
    start
    return
  fi
  printf "\n  ${MUT}clipboard:${R}  ${FAINT}%s${R}\n" "$clip"
  save_last "$clip"
  save_history "$clip"
  if [ -f "$clip" ] || [ -f "$SCRIPT_DIR/$clip" ]; then
    local f="$clip"; [ -f "$SCRIPT_DIR/$clip" ] && f="$SCRIPT_DIR/$clip"
    batchmode "$f"
    return
  fi
  asktype
  askquality
  askextras
  download "$clip"
}

show_history() {
  clear
  printf "\n  ${ACC}${B}downterm${R}  ${FAINT}history${R}\n"
  printf "  ${HAIR}...............................................${R}\n\n"
  if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
    printf "  ${FAINT}  no history yet.${R}\n\n"
    read -rn1 -s
    start
    return
  fi
  mapfile -t lines < <(grep -v '^[[:space:]]*$' "$HISTORY_FILE" | tail -n 12)
  local i=1
  for line in "${lines[@]}"; do
    printf "  ${MUT}%s${R}  ${FAINT}%s${R}\n" "$i" "$line"
    i=$((i + 1))
  done
  printf "\n  ${MUT}number to redownload (or enter)${R} "
  read -r pick
  if [ -z "$pick" ] || ! [[ "$pick" =~ ^[0-9]+$ ]]; then
    start
    return
  fi
  local idx=$((pick - 1))
  if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#lines[@]}" ]; then
    start
    return
  fi
  local url="${lines[$idx]}"
  save_last "$url"
  asktype
  askquality
  askextras
  download "$url"
}

open_folder() {
  local d="${OUT:-$SCRIPT_DIR}"
  [ -d "$d" ] || d="$SCRIPT_DIR"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$d" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$d" >/dev/null 2>&1 &
  else
    printf "  ${FAINT}%s${R}\n" "$d"
    read -rn1 -s
  fi
  start
}

info_mode() {
  printf "\n  ${MUT}url to inspect${R}  ${INK}<${R} "
  read -r url
  [ -z "$url" ] && { start; return; }
  if [ -z "${YTDLP:-}" ]; then
    printf "  ${BAD}yt-dlp not found.${R}\n"
    read -rn1 -s
    start
    return
  fi
  printf "\n  ${MUT}fetching info...${R}\n\n"
  if "$YTDLP" --no-download --print "%(title)s" --print "%(duration_string)s" --print "%(uploader)s" --print "%(webpage_url)s" "$url" 2>/dev/null; then
    printf "\n  ${FAINT}  d = download   other = back${R}\n"
    printf "  ${MUT}next?${R} "
    read -r next
    if [ "$next" = "d" ] || [ "$next" = "D" ]; then
      save_last "$url"
      save_history "$url"
      asktype
      askquality
      askextras
      download "$url"
      return
    fi
  else
    printf "  ${WARN}could not fetch info.${R}\n"
  fi
  read -rn1 -s
  start
}

redolast() {
  if [ ! -f "$LAST_FILE" ]; then
    printf "\n  ${FAINT}  no previous download.${R}\n"
    read -rn1 -s
    start
    return
  fi
  local url
  url=$(head -1 "$LAST_FILE" | tr -d '\r')
  if [ -z "$url" ]; then
    printf "\n  ${FAINT}  no previous download.${R}\n"
    read -rn1 -s
    start
    return
  fi
  printf "\n  ${MUT}redoing:${R}  ${FAINT}%s${R}\n" "$url"
  asktype
  askquality
  askextras
  download "$url"
}

selftest() {
  clear
  printf "\n  ${ACC}${B}downterm${R}  ${FAINT}self-test${R}\n"
  printf "  ${HAIR}...............................................${R}\n\n"
  printf "  ${MUT}downloading test video...${R}\n"
  printf "  ${FAINT}https://media.w3.org/2010/05/sintel/trailer.mp4${R}\n\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n\n"

  bash "${SCRIPT_DIR}/filter.sh" "https://media.w3.org/2010/05/sintel/trailer.mp4" "$FFARG" "$YTDLP" "video" "best" "" "0" "1" "0"
  local ec=$?
  printf "\n  ${HAIR}-----------------------------------------------${R}\n\n"
  if [ $ec -gt 0 ]; then
    printf "  ${BAD}test failed.${R}\n"
    read -rn1 -s
    start
    return
  fi
  printf "  ${GOOD}downloaded ok.${R}  ${MUT}cleaning up...${R}\n\n"
  local cleaned=0
  shopt -s nullglob
  for f in *.mp4 *.mkv *.webm *.mp3 *.m4a; do
    [ -f "$f" ] && rm -f -- "$f" && cleaned=1
  done
  shopt -u nullglob
  [ $cleaned -eq 1 ] && printf "  ${GOOD}test file removed.${R}\n" || printf "  ${FAINT}nothing to delete.${R}\n"
  printf "\n  ${FAINT}press any key...${R}\n"
  read -rn1 -s
  start
}

start() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v2.4${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}a quiet wrapper around yt-dlp.${R}\n"
  printf "\n"
  printf "  ${FAINT}url  p paste  h history  o open  i info${R}\n"
  printf "  ${FAINT}? help  t test  r redo  s setup  q quit${R}\n"
  printf "\n"
  printf "  ${INK}${B}<${R} "
  read -r url
  if [ -z "$url" ]; then
    printf "\n  ${BAD}nothing entered.${R}\n"
    read -rn1 -s
    start
    return
  fi

  case "$url" in
    "?"|help) show_help; return ;;
    t|test) selftest; return ;;
    s|setup) do_setup; return ;;
    p|paste) paste_clip; return ;;
    h|history) show_history; return ;;
    o|open) open_folder; return ;;
    i|info) info_mode; return ;;
    r|redo) redolast; return ;;
    q|quit|exit) exit 0 ;;
  esac

  save_last "$url"
  save_history "$url"

  if [ -f "$SCRIPT_DIR/$url" ] || [ -f "$url" ]; then
    local f="$url"
    [ -f "$SCRIPT_DIR/$url" ] && f="$SCRIPT_DIR/$url"
    batchmode "$f"
    return
  fi

  asktype
  askquality
  askextras
  download "$url"
}

# --- config ---
CFG_MODE=""
CFG_QUALITY=""
CFG_OUTPUT=""
CFG_SUBS=""
CFG_FORCE=""
CFG_SPONSOR=""
if [ -f "$SCRIPT_DIR/downterm.conf" ]; then
  while IFS='=' read -r key val; do
    case "$key" in
      ''|\#*) continue ;;
      MODE) CFG_MODE="$val" ;;
      QUALITY) CFG_QUALITY="$val" ;;
      OUTPUT) CFG_OUTPUT="$val" ;;
      SUBS) CFG_SUBS="$val" ;;
      FORCE) CFG_FORCE="$val" ;;
      SPONSORBLOCK) CFG_SPONSOR="$val" ;;
    esac
  done < "$SCRIPT_DIR/downterm.conf"
fi

# --- CLI ---
ARG_URL=""
ARG_MODE=""
ARG_QUALITY=""
ARG_OUTPUT=""
ARG_SUBS=""
ARG_FORCE=""
ARG_SPONSOR=""
ARG_OP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode=*) ARG_MODE="${1#--mode=}" ;;
    --quality=*) ARG_QUALITY="${1#--quality=}" ;;
    --output=*) ARG_OUTPUT="${1#--output=}" ;;
    --subs) ARG_SUBS="1" ;;
    --force) ARG_FORCE="1" ;;
    --sponsorblock) ARG_SPONSOR="1" ;;
    --setup) ARG_OP="setup" ;;
    --version) ARG_OP="version" ;;
    --help|-h) ARG_URL="--help" ;;
    --*) ;;
    *) [ -z "$ARG_URL" ] && ARG_URL="$1" ;;
  esac
  shift
done

YTDLP=""
if command -v yt-dlp >/dev/null 2>&1; then
  YTDLP="yt-dlp"
elif [ -x "${SCRIPT_DIR}/yt-dlp" ]; then
  YTDLP="${SCRIPT_DIR}/yt-dlp"
fi

FFARG=""
if command -v ffmpeg >/dev/null 2>&1; then
  FFARG="$(command -v ffmpeg)"
elif [ -x "${SCRIPT_DIR}/ffmpeg" ]; then
  FFARG="${SCRIPT_DIR}/ffmpeg"
fi

if [ "$ARG_OP" = "version" ]; then
  show_version
  exit 0
fi

if [ "$ARG_OP" = "setup" ]; then
  do_setup
  exit $?
fi

if [ -n "$ARG_URL" ] && [ "$ARG_URL" != "--help" ]; then
  if [ -z "$YTDLP" ]; then
    printf "  ${BAD}yt-dlp not found. run setup (s).${R}\n"
    exit 1
  fi
  MODE="${ARG_MODE:-$CFG_MODE}"; [ -z "$MODE" ] && MODE="video"
  QUALITY="${ARG_QUALITY:-$CFG_QUALITY}"; [ -z "$QUALITY" ] && QUALITY="best"
  OUT="${ARG_OUTPUT:-$CFG_OUTPUT}"
  SUBS="${ARG_SUBS:-$CFG_SUBS}"; [ -z "$SUBS" ] && SUBS="0"
  FORCE="${ARG_FORCE:-$CFG_FORCE}"; [ -z "$FORCE" ] && FORCE="0"
  SPONSOR="${ARG_SPONSOR:-$CFG_SPONSOR}"; [ -z "$SPONSOR" ] && SPONSOR="0"
  [ -n "$OUT" ] && mkdir -p "$OUT" 2>/dev/null || true
  save_last "$ARG_URL"
  save_history "$ARG_URL"
  download "$ARG_URL"
  exit $?
fi

if [ "$ARG_URL" = "--help" ]; then
  show_help
  exit 0
fi

# interactive defaults from conf
[ -n "$CFG_MODE" ] && MODE="$CFG_MODE"
[ -n "$CFG_QUALITY" ] && QUALITY="$CFG_QUALITY"
[ -n "$CFG_OUTPUT" ] && OUT="$CFG_OUTPUT"
[ -n "$CFG_SUBS" ] && SUBS="$CFG_SUBS"
[ -n "$CFG_FORCE" ] && FORCE="$CFG_FORCE"
[ -n "$CFG_SPONSOR" ] && SPONSOR="$CFG_SPONSOR"

if [ -z "$YTDLP" ]; then
  printf "  ${BAD}yt-dlp not found.${R}\n"
  printf "  ${FAINT}run 's' to fetch it${R}\n"
fi

start
