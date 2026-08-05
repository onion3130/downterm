#!/usr/bin/env bash
set -euo pipefail

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAKE="$TMP/fake-yt-dlp"
cat > "$FAKE" <<'FAKE'
#!/usr/bin/env bash
printf '%s\n' "${FAKE_ERROR:?}"
exit 1
FAKE
chmod +x "$FAKE"

run_case() {
  local expected="$1"
  local message="$2"
  local output
  local status
  set +e
  output="$(cd "$TMP" && FAKE_ERROR="$message" bash "$ROOT/filter.sh" "https://example.test/video" "" "$FAKE" video best "" 0 1 0 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    printf 'FAIL: %s unexpectedly succeeded\n%s\n' "$message" "$output" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" <<<"$output"; then
    printf 'FAIL: %s did not produce %s\n%s\n' "$message" "$expected" "$output" >&2
    exit 1
  fi
  printf 'ok: %s -> %s\n' "$message" "$expected"
}

run_case ERR-08 'ERROR: HTTP Error 403: Forbidden'
run_case ERR-09 'ERROR: HTTP Error 503: Service Unavailable'
run_case ERR-10 'ERROR: Connection timed out'
run_case ERR-10 'ERROR: Connection refused'
run_case ERR-10 'ERROR: Connection reset by peer'
run_case ERR-11 'ERROR: FFmpeg executable not installed'
run_case ERR-12 'ERROR: unable to find deno runtime'
