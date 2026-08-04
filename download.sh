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

# --- Item 6: load config from downterm.conf if present ---
CFG_MODE=""
CFG_QUALITY=""
CFG_OUTPUT=""
if [ -f "$SCRIPT_DIR/downterm.conf" ]; then
  while IFS='=' read -r key val; do
    case "$key" in
      ''|\#*) continue ;;
      MODE)    CFG_MODE="$val" ;;
      QUALITY) CFG_QUALITY="$val" ;;
      OUTPUT)  CFG_OUTPUT="$val" ;;
    esac
  done < "$SCRIPT_DIR/downterm.conf"
fi

# --- Item 6: parse CLI flags ---
ARG_URL=""
ARG_MODE=""
ARG_QUALITY=""
ARG_OUTPUT=""
ARG_OP=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode=*)    ARG_MODE="${1#--mode=}" ;;
    --quality=*) ARG_QUALITY="${1#--quality=}" ;;
    --output=*)  ARG_OUTPUT="${1#--output=}" ;;
    --setup)     ARG_OP="setup" ;;
    --version)   ARG_OP="version" ;;
    --help|-h)   ARG_URL="--help" ;;
    --*)         ;;  # ignore unknown flags
    *)           if [ -z "$ARG_URL" ]; then ARG_URL="$1"; fi ;;
  esac
  shift
done

# Resolve yt-dlp + ffmpeg - look on system, then script-local. Setup ('s') fetches if missing.
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

# --- Item 6: non-interactive mode when URL passed on CLI ---
if [ "$ARG_OP" = "version" ]; then
  echo "downterm v2.2"
  exit 0
fi

if [ "$ARG_OP" = "setup" ]; then
  do_setup
  exit $?
fi

if [ -n "$ARG_URL" ] && [ "$ARG_URL" != "--help" ]; then
  if [ -z "$YTDLP" ]; then
    printf "  ${BAD}yt-dlp not found.${R}\n"
    printf "  ${FAINT}run 's' (interactively) to fetch it, or see bin/checksums.txt${R}\n"
    exit 1
  fi
  MODE="${ARG_MODE:-$CFG_MODE}"
  [ -z "$MODE" ] && MODE="video"
  QUALITY="${ARG_QUALITY:-$CFG_QUALITY}"
  [ -z "$QUALITY" ] && QUALITY="best"
  OUT="${ARG_OUTPUT:-$CFG_OUTPUT}"
  if [ -n "$OUT" ] && [ ! -d "$OUT" ]; then mkdir -p "$OUT" 2>/dev/null; fi
  printf "%s\n" "$ARG_URL" > "$SCRIPT_DIR/.downterm_last.txt"
  download "$ARG_URL"
  exit $?
fi

if [ "$ARG_URL" = "--help" ]; then
  show_help
  exit 0
fi

if [ -z "$YTDLP" ]; then
  printf "  ${BAD}yt-dlp not found.${R}\n"
  printf "  ${FAINT}run 's' to fetch it, or see bin/checksums.txt${R}\n"
fi

start() {
  clear
  printf "\n"
  printf "  ${ACC}${B}downterm${R}  ${FAINT}v2.0.1${R}\n"
  printf "  ${HAIR}...............................................${R}\n"
  printf "\n"
  printf "  ${MUT}a quiet wrapper around yt-dlp.${R}\n"
  printf "\n"
  printf "  ${FAINT}? help   t test   s setup   q quit${R}\n"
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
    s|setup) do_setup; return ;;
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

  bash "${SCRIPT_DIR}/filter.sh" "$dl_url" "$FFARG" "$YTDLP" "$MODE" "$QUALITY" "${OUT:-}"
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
  printf "  ${FAINT}https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"

  bash "${SCRIPT_DIR}/filter.sh" "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4" "$FFARG" "$YTDLP" "video" "best"
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

verify_hash() {
  # args: tmpfile expected_sha256
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

do_setup() {
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
    printf "  ${FAINT}cannot determine what to fetch. reinstall downterm.${R}\n"
    printf "\n  ${FAINT}press any key...${R}\n"
    read -rn1 -s
    return
  fi

  # detect platform key in checksums.txt
  local platkey
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64|Linux-amd64) platkey="yt-dlp_linux" ;;
    Linux-aarch64|Linux-arm64) platkey="yt-dlp_linux_aarch64" ;;
    Darwin-x86_64) platkey="yt-dlp_macos" ;;
    Darwin-arm64) platkey="yt-dlp_macos" ;;  # fallback to x86 build, rosetta runs it
    *) platkey="yt-dlp_linux" ;;
  esac
  local denoplatkey
  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64|Linux-amd64) denoplatkey="deno_linux" ;;
    Linux-aarch64|Linux-arm64) denoplatkey="deno_linux" ;;  # deno has aarch64 builds; see checksums
    Darwin-x86_64) denoplatkey="deno_macos" ;;
    Darwin-arm64) denoplatkey="deno_macos" ;;
    *) denoplatkey="deno_linux" ;;
  esac

  # parse checksums.txt into key/url/hash
  local yt_url yt_hash deno_url deno_hash
  while read -r k v h u rest; do
    case "$k" in
      ''|\#*) continue ;;
      "$platkey")       yt_url="$u"; yt_hash="$h" ;;
      "$denoplatkey")   deno_url="$u"; deno_hash="$h" ;;
    esac
  done < "$cf"

  # fetch yt-dlp
  local myytdlp="$SCRIPT_DIR/yt-dlp"
  if [ -x "$myytdlp" ] || command -v yt-dlp >/dev/null 2>&1; then
    printf "  ${FAINT}yt-dlp already present (system or local), skipping.${R}\n"
  elif [ -n "$yt_url" ]; then
    printf "  ${MUT}fetching yt-dlp...${R}\n"
    if curl -fL -o "$myytdlp.tmp" "$yt_url" 2>/dev/null; then
      if verify_hash "$myytdlp.tmp" "$yt_hash"; then
        mv "$myytdlp.tmp" "$myytdlp"
        chmod +x "$myytdlp"
        YTDLP="$myytdlp"
        printf "  ${GOOD}yt-dlp verified.${R}\n"
      else
        rm -f "$myytdlp.tmp"
        setup_fail; return
      fi
    else
      printf "  ${BAD}download failed for yt-dlp.${R}\n"
      setup_fail; return
    fi
  else
    printf "  ${BAD}no checksum entry for $platkey.${R}\n"
    setup_fail; return
  fi

  # ffmpeg: prefer system, warn-only if missing
  if command -v ffmpeg >/dev/null 2>&1; then
    printf "  ${FAINT}ffmpeg already on PATH, skipping.${R}\n"
  else
    printf "  ${WARN}ffmpeg not found.${R}  ${FAINT}install via your package manager:${R}\n"
    printf "    ${FAINT}apt install ffmpeg   (Debian/Ubuntu)${R}\n"
    printf "    ${FAINT}brew install ffmpeg  (macOS)${R}\n"
    printf "    ${FAINT}dnf install ffmpeg   (Fedora)${R}\n"
    printf "  ${FAINT}some downloads will fail without it.${R}\n"
  fi

  # deno (optional)
  local mydeno="$SCRIPT_DIR/deno"
  if [ -x "$mydeno" ] || command -v deno >/dev/null 2>&1; then
    printf "  ${FAINT}deno already present, skipping.${R}\n"
  elif [ -n "$deno_url" ] && command -v unzip >/dev/null 2>&1; then
    printf "  ${MUT}fetching deno.zip...${R}\n"
    if curl -fL -o "$SCRIPT_DIR/deno.zip.tmp" "$deno_url" 2>/dev/null; then
      if verify_hash "$SCRIPT_DIR/deno.zip.tmp" "$deno_hash"; then
        mv "$SCRIPT_DIR/deno.zip.tmp" "$SCRIPT_DIR/deno.zip"
        (cd "$SCRIPT_DIR" && unzip -oq deno.zip && rm -f deno.zip)
        if [ -x "$mydeno" ]; then
          printf "  ${GOOD}deno verified.${R}\n"
        else
          printf "  ${BAD}deno binary not found in zip.${R}\n"
          printf "  ${FAINT}optional - yt-dlp will run with limited JS retrieval.${R}\n"
        fi
      else
        rm -f "$SCRIPT_DIR/deno.zip.tmp"
        printf "  ${WARN}deno checksum failed; skipping (optional).${R}\n"
      fi
    else
      printf "  ${WARN}deno download failed; skipping (optional).${R}\n"
    fi
  else
    printf "  ${FAINT}deno not present and unzip unavailable; skipping (optional).${R}\n"
  fi

  printf "\n"
  printf "  ${GOOD}setup complete.${R}  ${FAINT}you can now paste a url.${R}\n"
  printf "\n  ${FAINT}press any key...${R}\n"
  read -rn1 -s
  return
}

setup_fail() {
  rm -f "$SCRIPT_DIR/yt-dlp.tmp" "$SCRIPT_DIR/deno.zip.tmp" "$SCRIPT_DIR/deno.zip" 2>/dev/null
  printf "\n"
  printf "  ${BAD}setup failed.${R}  ${FAINT}see message above.${R}\n"
  printf "  ${FAINT}delete the bad binary and re-run 's'. if it still fails,${R}\n"
  printf "  ${FAINT}the pinned build may have been re-uploaded. open an issue:${R}\n"
  printf "  ${FAINT}github.com/onion3130/downterm/issues${R}\n"
  printf "\n  ${FAINT}press any key...${R}\n"
  read -rn1 -s
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
  printf "    ${INK}s${R}   ${FAINT}setup (fetch yt-dlp, deno; check ffmpeg)${R}\n"
  printf "    ${INK}q${R}   ${FAINT}quit${R}\n"
  printf "\n"
  printf "  ${MUT}requires${R}\n"
  printf "    ${FAINT}- run 's' on first launch to fetch yt-dlp + deno${R}\n"
  printf "      ${FAINT}(verified by SHA256; see bin/checksums.txt)${R}\n"
  printf "    ${FAINT}- ffmpeg: apt/brew/dnf install ffmpeg${R}\n"
  printf "    ${FAINT}- bash 4+${R}\n"
  printf "\n"
  printf "  ${HAIR}-----------------------------------------------${R}\n"
  printf "\n"
  printf "  ${FAINT}any key to go back.${R}\n"
  read -rn1 -s
  start
}

start
