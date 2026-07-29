#!/usr/bin/env bash
# Show the clipboard as a QR code so a phone can grab it without typing.
# Pairs with ezupload.sh, which already leaves its URL on the clipboard.
set -uo pipefail

app="qr"
out="/tmp/qr-clip.png" # ponytail: fixed path, a second invocation replaces it

mime="$(wl-paste --list-types 2>/dev/null | head -1)"
if [[ -z "$mime" ]]; then
    notify-send "QR" "Clipboard is empty" -a "$app"
    exit 1
fi
if [[ "$mime" == image/* ]]; then
    notify-send "QR" "Clipboard holds an image, not text" -a "$app"
    exit 1
fi

data="$(wl-paste --no-newline 2>/dev/null)"
if [[ -z "$data" ]]; then
    notify-send "QR" "Clipboard is empty" -a "$app"
    exit 1
fi

# A QR tops out near 2953 bytes even at the lowest EC level. Say so plainly
# rather than letting qrencode fail with something cryptic.
if (( ${#data} > 2900 )); then
    notify-send "QR" "Too long for a QR code (${#data} bytes)" -a "$app"
    exit 1
fi

if ! qrencode -o "$out" -s 12 -m 2 -- "$data" 2>/dev/null; then
    notify-send "QR" "Encode failed" -a "$app"
    exit 1
fi

imv "$out"
