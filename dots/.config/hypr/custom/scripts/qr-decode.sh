#!/usr/bin/env bash
# Select a screen region holding a QR code, decode it onto the clipboard.
set -uo pipefail

app="qr"

geom="$(slurp 2>/dev/null)" || exit 0 # cancelled
[[ -z "$geom" ]] && exit 0

text="$(grim -g "$geom" - 2>/dev/null | zbarimg --quiet --raw - 2>/dev/null)"
text="${text%$'\n'}"

if [[ -z "$text" ]]; then
    notify-send "QR" "No QR code found in that region" -a "$app"
    exit 1
fi

printf '%s' "$text" | wl-copy
notify-send "QR decoded" "$text" -a "$app"
