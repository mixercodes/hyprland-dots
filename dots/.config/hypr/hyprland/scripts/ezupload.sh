#!/usr/bin/env bash
# Upload a file to e-z.host, copy the resulting URL to the Wayland clipboard, notify.
# Usage: ezupload.sh <file>   (any media type: png, mp4, ...)
set -uo pipefail

url="https://api.e-z.host/files"
app="e-z upload"

# API key is kept OUT of git: read $EZ_HOST_KEY, else ~/.config/e-z.host/key (chmod 600).
auth="${EZ_HOST_KEY:-$(cat "$HOME/.config/e-z.host/key" 2>/dev/null)}"

file="${1:-}"
if [[ ! -s "$file" ]]; then
    notify-send "Upload failed" "Missing or empty file: $file" -a "$app"
    exit 1
fi
if [[ -z "$auth" ]]; then
    notify-send "Upload failed" "No API key (set EZ_HOST_KEY or ~/.config/e-z.host/key)" -a "$app"
    exit 1
fi

resp=$(curl -sS -X POST -F "file=@${file}" -H "key: ${auth}" "$url") || {
    notify-send "Upload failed" "Network error" -a "$app"; exit 1; }

if ! jq -e '.success == true' >/dev/null 2>&1 <<<"$resp"; then
    notify-send "Upload failed" "$(jq -r '.error // "Unknown error"' <<<"$resp" 2>/dev/null)" -a "$app"
    exit 1
fi

link=$(jq -r '.imageUrl // .rawUrl // empty' <<<"$resp")
if [[ -z "$link" ]]; then
    notify-send "Upload failed" "No URL in response" -a "$app"
    exit 1
fi

printf '%s' "$link" | wl-copy

# This notif daemon treats -i as an image PATH (loaded async), not an icon name.
# Callers delete the capture right after we return, so point the thumbnail at a stable
# copy instead of the soon-gone source. Video has no loadable image -> omit -i and let
# the "recording" keyword in the summary pick a glyph.
# ponytail: single fixed thumb path; a rapid second upload overwrites it (old notif then
# shows the newer image). Use a unique temp if that ever matters.
if [[ "$(file -b --mime-type "$file")" == image/* ]]; then
    thumb="/tmp/ezupload-thumb.png"
    cp -f "$file" "$thumb" 2>/dev/null
    notify-send "Screenshot uploaded — URL copied" "$link" -a "$app" -i "$thumb"
else
    notify-send "Recording uploaded — URL copied" "$link" -a "$app"
fi
