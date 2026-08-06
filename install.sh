#!/usr/bin/env bash
# downterm installer — Linux / macOS
#
#   curl -fsSL https://raw.githubusercontent.com/onion3130/downterm/main/install.sh | bash
#
# Downloads the latest release source, runs setup.sh (tools + PATH), so a
# brand-new terminal can run:  downterm
set -euo pipefail

REPO=onion3130/downterm
TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' | head -1 | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')"
[ -n "${TAG:-}" ] || { echo "could not reach GitHub — check connectivity." >&2; exit 1; }

TARGET="${DOWNTERM_DIR:-$HOME/.downterm}"
TGZ="$(mktemp)"
trap 'rm -f "$TGZ"' EXIT

echo "  latest release:  $TAG"
echo "  installing to:   $TARGET"
echo "  downloading ..."
curl -fsSL "https://github.com/$REPO/archive/refs/tags/$TAG.tar.gz" -o "$TGZ"

mkdir -p "$TARGET"
tar -xzf "$TGZ" -C "$TARGET" --strip-components=1
chmod +x "$TARGET"/setup.sh "$TARGET"/download.sh "$TARGET"/filter.sh 2>/dev/null || true

echo "  running setup (tools + PATH) ..."
bash "$TARGET/setup.sh"

echo ""
echo "  done."
echo ""
echo "  1. Open a NEW terminal"
echo "  2. Type:  downterm"
echo ""
echo "  To remove later:"
echo "      $HOME/.local/bin/downterm   (delete this link)"
echo "      $TARGET                     (delete this folder)"
echo ""
exit 0