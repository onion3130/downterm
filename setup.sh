#!/usr/bin/env bash
# downterm setup (Linux / macOS)
# - fetches yt-dlp (+ deno when possible)
# - ALWAYS links ~/.local/bin/downterm (PATH entry)
#
#   chmod +x setup.sh && ./setup.sh
#   ./setup.sh --path-only
#   ./setup.sh --skip-path

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PATH_ONLY=0
SKIP_PATH=0
FORCE_TOOLS=0
for a in "$@"; do
  case "$a" in
    --path-only|-PathOnly) PATH_ONLY=1 ;;
    --skip-path|-SkipPath) SKIP_PATH=1 ;;
    --force-tools|-ForceTools) FORCE_TOOLS=1 ;;
  esac
done

ESC="\033"
GOOD="${ESC}[32m"
WARN="${ESC}[33m"
BAD="${ESC}[31m"
CYAN="${ESC}[36m"
R="${ESC}[0m"

step() { printf "  ${CYAN}%s${R}\n" "$*"; }
ok() { printf "  ${GOOD}%s${R}\n" "$*"; }
warn() { printf "  ${WARN}%s${R}\n" "$*"; }
bad() { printf "  ${BAD}%s${R}\n" "$*"; }

printf "\n  downterm setup\n"
printf "  ..........................................\n\n"

# ---------- tools ----------
if [ "$PATH_ONLY" -eq 0 ]; then
  CF="$SCRIPT_DIR/bin/checksums.txt"
  if [ ! -f "$CF" ]; then
    bad "bin/checksums.txt missing"
    exit 1
  fi

  plat=yt-dlp_linux
  denoplat=deno_linux
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64|Darwin-aarch64) plat=yt-dlp_macos; denoplat=deno_macos_aarch64 ;;
    Darwin-*) plat=yt-dlp_macos; denoplat=deno_macos ;;
    Linux-aarch64|Linux-arm64) plat=yt-dlp_linux_aarch64; denoplat=deno_linux_aarch64 ;;
    Linux-x86_64|Linux-amd64) plat=yt-dlp_linux; denoplat=deno_linux ;;
  esac

  pin_line() { awk -v k="$1" '$1==k{print; exit}' "$CF"; }

  verify() {
    local f="$1" expect="$2"
    local actual
    if command -v sha256sum >/dev/null 2>&1; then
      actual=$(sha256sum "$f" | awk '{print $1}')
    else
      actual=$(shasum -a 256 "$f" | awk '{print $1}')
    fi
    [ "$actual" = "$expect" ]
  }

  # yt-dlp
  if [ -x "$SCRIPT_DIR/yt-dlp" ] && [ "$FORCE_TOOLS" -eq 0 ]; then
    printf "  yt-dlp already present — skip\n"
  elif command -v yt-dlp >/dev/null 2>&1 && [ "$FORCE_TOOLS" -eq 0 ]; then
    printf "  yt-dlp on PATH — skip\n"
  else
    line=$(pin_line "$plat")
    if [ -n "$line" ]; then
      ver=$(echo "$line" | awk '{print $2}')
      hash=$(echo "$line" | awk '{print $3}')
      url=$(echo "$line" | awk '{print $4}')
      step "fetching yt-dlp ($ver) ..."
      if curl -fL --max-time 180 -o "$SCRIPT_DIR/yt-dlp.tmp" "$url" && verify "$SCRIPT_DIR/yt-dlp.tmp" "$hash"; then
        mv "$SCRIPT_DIR/yt-dlp.tmp" "$SCRIPT_DIR/yt-dlp"
        chmod +x "$SCRIPT_DIR/yt-dlp"
        ok "yt-dlp ok"
      else
        rm -f "$SCRIPT_DIR/yt-dlp.tmp"
        warn "yt-dlp fetch/verify failed"
      fi
    fi
  fi

  # ffmpeg (system)
  if command -v ffmpeg >/dev/null 2>&1; then
    printf "  ffmpeg present — skip\n"
  else
    warn "ffmpeg not found — install with apt/brew/dnf"
  fi

  # deno optional
  if [ -x "$SCRIPT_DIR/deno" ] || command -v deno >/dev/null 2>&1; then
    printf "  deno present — skip\n"
  else
    line=$(pin_line "$denoplat")
    if [ -n "$line" ] && command -v unzip >/dev/null 2>&1; then
      hash=$(echo "$line" | awk '{print $3}')
      url=$(echo "$line" | awk '{print $4}')
      step "fetching deno ..."
      if curl -fL --max-time 300 -o "$SCRIPT_DIR/deno.zip.tmp" "$url" && verify "$SCRIPT_DIR/deno.zip.tmp" "$hash"; then
        mv "$SCRIPT_DIR/deno.zip.tmp" "$SCRIPT_DIR/deno.zip"
        (cd "$SCRIPT_DIR" && unzip -oq deno.zip && rm -f deno.zip)
        [ -x "$SCRIPT_DIR/deno" ] && ok "deno ok" || warn "deno extract failed"
      else
        rm -f "$SCRIPT_DIR/deno.zip.tmp"
        warn "deno fetch failed (optional)"
      fi
    fi
  fi
  printf "\n"
fi

# ---------- PATH (default: always) ----------
if [ "$SKIP_PATH" -eq 0 ]; then
  step "linking downterm on PATH ..."
  mkdir -p "$HOME/.local/bin"
  chmod +x "$SCRIPT_DIR/download.sh" "$SCRIPT_DIR/filter.sh" "$SCRIPT_DIR/setup.sh" 2>/dev/null || true
  ln -sfn "$SCRIPT_DIR/download.sh" "$HOME/.local/bin/downterm"
  ok "linked $HOME/.local/bin/downterm"
  touch "$SCRIPT_DIR/.downterm_path_ok"
  if ! echo ":$PATH:" | grep -q ":$HOME/.local/bin:"; then
    warn "~/.local/bin is not on PATH yet. Add to ~/.bashrc or ~/.zshrc:"
    printf "    export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
  fi
else
  warn "skipped PATH (--skip-path). Re-run: ./setup.sh --path-only"
fi

printf "\n"
ok "setup complete"
printf "\n"
printf "  Next:\n"
printf "    1. Open a NEW terminal\n"
printf "    2. Type:  downterm\n"
printf "\n"
printf "  Manual PATH only (anytime):\n"
printf "    ./setup.sh --path-only\n"
printf "    ./download.sh --install\n"
printf "    menu → 7\n"
printf "\n"
exit 0
