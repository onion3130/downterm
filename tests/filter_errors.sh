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
run_case ERR-13 'ERROR: Unsupported URL: zzz'

# ERR-14 - cookies file missing (checked before yt-dlp runs)
output="$(cd "$TMP" && bash "$ROOT/filter.sh" "https://example.test/video" "" "$FAKE" video best "" 0 0 0 "$TMP/no-such-cookies.txt" 0 0 0 2>&1)" || true
if ! grep -Fq 'ERR-14' <<<"$output"; then
  printf 'FAIL: missing cookies file did not produce ERR-14\n%s\n' "$output" >&2
  exit 1
fi
printf 'ok: missing cookies file -> ERR-14\n'

# --playlist-items and audio format flow to yt-dlp untouched
cat > "$TMP/fake-dl" <<'FAKE2'
#!/usr/bin/env bash
printf '%s\n' "$*"
exit 0
FAKE2
chmod +x "$TMP/fake-dl"
cat > "$TMP/cookies.txt" <<'CK'
# Netscape HTTP Cookie File
CK
out="$(cd "$TMP" && bash "$ROOT/filter.sh" "https://example.test/video?list=PLx" "" "$TMP/fake-dl" video 1080 "" 0 0 0 "$TMP/cookies.txt" m4a "1,3-5" 1 2>&1)"
for tok in "--playlist-items" "--cookies" "--embed-thumbnail" "1,3-5"; do
  grep -Fq -- "$tok" <<<"$out" || { printf 'FAIL: missing token %s in %s\n' "$tok" "$out" >&2; exit 1; }
done
printf 'ok: playlist-items + cookies + embed args forwarded\n'

out2="$(cd "$TMP" && bash "$ROOT/filter.sh" "https://example.test/song" "" "$TMP/fake-dl" audio best "" 0 0 0 "" m4a "" 0 2>&1)"
case "$out2" in *"--audio-format m4a"*) : ;; *) printf 'FAIL: audio m4a not forwarded\n%s\n' "$out2" >&2; exit 1 ;; esac
printf 'ok: audio format m4a forwarded\n'
