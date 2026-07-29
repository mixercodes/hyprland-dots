#!/usr/bin/env bash
# Decode a QR code to the clipboard.
#   qr-decode.sh <image>   decode that file (quickshell region selector passes
#                          the already-cropped snip here)
#   qr-decode.sh           no quickshell: fall back to slurp + grim
set -uo pipefail

app="qr"
img="${1:-}"

if [[ -n "$img" ]]; then
    [[ -s "$img" ]] || { notify-send "QR" "Empty or missing image" -a "$app"; exit 1; }
else
    geom="$(slurp 2>/dev/null)" || exit 0 # cancelled
    [[ -z "$geom" ]] && exit 0
    img="$(mktemp --suffix=.png)"
    grim -g "$geom" "$img" 2>/dev/null
    trap 'rm -f "$img"' EXIT
fi

text="$(zbarimg --quiet --raw -- "$img" 2>/dev/null)"
text="${text%$'\n'}"

if [[ -z "$text" ]]; then
    notify-send "QR" "No QR code found in that region" -a "$app"
    exit 1
fi

printf '%s' "$text" | wl-copy
notify-send "QR decoded" "$text" -a "$app"
