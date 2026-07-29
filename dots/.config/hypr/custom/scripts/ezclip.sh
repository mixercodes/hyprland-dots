#!/usr/bin/env bash
# Upload whatever is on the clipboard, image or text, via ezupload.sh.
# ezupload handles the key, the API call, the notify and the URL-to-clipboard.
set -uo pipefail

app="e-z upload"
ez="$HOME/.config/hypr/hyprland/scripts/ezupload.sh"

mime="$(wl-paste --list-types 2>/dev/null | head -1)"
if [[ -z "$mime" ]]; then
    notify-send "Upload failed" "Clipboard is empty" -a "$app"
    exit 1
fi

if [[ "$mime" == image/* ]]; then
    f="$(mktemp --suffix=".${mime#image/}")"
    wl-paste --type "$mime" >"$f" 2>/dev/null
else
    f="$(mktemp --suffix=.txt)"
    wl-paste --no-newline >"$f" 2>/dev/null
fi

if [[ -s "$f" ]]; then
    "$ez" "$f"
else
    notify-send "Upload failed" "Nothing on the clipboard to upload" -a "$app"
fi
rm -f "$f"
