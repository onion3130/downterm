# downterm error reference

When downterm hits an error, it shows a short code like `ERR-01` with a one-line message. This page explains each code and how to fix it.

---

## ERR-00 — unknown error
yt-dlp returned an error we don't have a specific code for. Look at the full output above the error line — yt-dlp usually prints the raw cause. If it's reproducible, [open an issue](https://github.com/onion3130/downterm/issues) and paste the output.

## ERR-01 — video unavailable (private/deleted)
The video was removed, made private, or doesn't exist. Nothing you can do from downterm — the video is gone.

## ERR-02 — private video — sign in required
The video requires a Google account to access. downterm doesn't handle authentication. If you have cookies exported from your browser, you can pass them to yt-dlp manually — but downterm by design doesn't expose that.

## ERR-03 — members-only content
The video is restricted to channel members. You need a paid membership to that channel to watch/download it.

## ERR-04 — geo-restricted in your region
The video is blocked in your country. Options:
- Use a VPN to a region where the video is available
- Try a different source if the content exists elsewhere

## ERR-05 — age-restricted — needs cookies
The video requires age verification. You need to export cookies from a browser where you're signed in (over 18). downterm doesn't expose cookie options — use yt-dlp directly with `--cookies cookies.txt` for this case.

## ERR-06 — bot detection — try again later
YouTube flagged your IP for suspicious activity. Wait ~10–30 minutes and try again. If it persists:
- Restart your router (new IP)
- Try later from a different network

## ERR-07 — no downloadable formats found
yt-dlp couldn't find any stream for the URL. Common causes:
- The video is still processing (try again in a few minutes)
- The URL is a premiere/live stream that hasn't started
- The format requested isn't available (try `best` quality instead of 1080p/720p/4:p)

## ERR-08 — HTTP 4xx from server
The server returned a client error (e.g. 403 Forbidden, 404 Not Found). Usually transient — try again. If it persists, the content may have been moved or restricted.

## ERR-09 — HTTP 5xx from server
The server is having issues. Wait a few minutes and retry. Nothing wrong on your end.

## ERR-10 — connection failed
Network connectivity issue. Check:
- Your internet connection
- Firewall/proxy settings (yt-dlp needs outbound HTTPS to youtube.com)
- If you're on a restricted network (school/work), they may block video sites

## ERR-11 — ffmpeg executable missing
`ffmpeg.exe` isn't in the downterm folder, and yt-dlp needs it to merge video+audio. Fix:
- Download the full Windows zip from the [latest release](https://github.com/onion3130/downterm/releases/latest) (ffmpeg bundled)
- Or download [ffmpeg](https://www.gyan.dev/ffmpeg/builds/) and place `ffmpeg.exe` next to `download.bat`

## ERR-12 — deno runtime missing
`deno.exe` isn't in the folder. Without it, YouTube extraction degrades (lower quality formats, warning messages). Fix:
- Download the full Windows zip (deno bundled)
- Or install deno: `winget install DenoLand.Deno` (Linux: `curl -fsSL https://deno.land/install.sh | sh`)

## ERR-13 — unsupported URL — not a valid video link
The URL you pasted isn't one yt-dlp recognizes. Make sure it's a full video link (e.g. `https://www.youtube.com/watch?v=...` or `https://youtu.be/...`). Shortened or malformed URLs won't work.

## SKIP — already downloaded
You've downloaded this video before in this folder. downterm keeps an archive (`.downterm_archive.txt`) and skips videos that are already there. To re-download:
- Delete the `.downterm_archive.txt` file
- Or remove the video's ID from that file

---

## Reporting new errors

If you get `ERR-00` for something that seems like a known yt-dlp error, [open an issue](https://github.com/onion3130/downterm/issues) with:
1. The error code shown
2. The full output above the error line
3. The URL (if it's not private)
4. Your OS (Windows / Linux / macOS)

We'll add a specific code for it in the next version.
