#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
LOG="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder-replay.log"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder-replay.pid"
STATEFILE="${XDG_STATE_HOME:-$HOME/.local/state}/gpu-screen-recorder-replay.on"

cfg() {
    local v
    v=$(jq -r "$1 // empty" "$CONFIG_FILE" 2>/dev/null)
    if [[ -n "$v" && "$v" != "null" ]]; then echo "$v"; else echo "$2"; fi
}

notify() {
    notify-send "$1" "$2" -a 'Instant Replay' & disown
}

running() {
    local pid
    pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
    [[ -n "$pid" ]] || return 1
    [[ "$(cat "/proc/$pid/comm" 2>/dev/null)" == gpu-screen-reco* ]]
}

audio_args() {
    if [[ "$(jq -r '.clip.sound' "$CONFIG_FILE" 2>/dev/null)" == "false" ]]; then
        return
    fi
    echo "-a default_output"
}

active_monitor() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -1
}

start() {
    if running; then
        notify "Instant replay" "Already on"
        return
    fi

    local dir fps res secs mon
    dir=$(cfg '.clip.savePath' "$HOME/Videos/Clips")
    fps=$(cfg '.clip.fps' 60)
    res=$(cfg '.clip.resolution' 0x0)
    secs=$(cfg '.clip.bufferSeconds' 60)
    mon=$(active_monitor)
    [[ -n "$mon" ]] || mon="screen"

    if ! mkdir -p "$dir"; then
        notify "Instant replay failed" "Cannot create $dir"
        return 1
    fi

    # shellcheck disable=SC2046
    nohup gpu-screen-recorder -w "$mon" -f "$fps" -s "$res" -c mp4 -r "$secs" \
        -o "$dir" -sc "$(realpath "$0")" -v no $(audio_args) > "$LOG" 2>&1 &
    echo $! > "$PIDFILE"
    disown

    sleep 1
    if running; then
        mkdir -p "$(dirname "$STATEFILE")" && touch "$STATEFILE"
        notify "Instant replay on" "Last ${secs}s · ${fps} fps · ${res/0x0/native}"
    else
        notify "Instant replay failed" "$(tail -n 2 "$LOG")"
        return 1
    fi
}

stop() {
    if ! running; then
        notify "Instant replay" "Turn it on first"
        return 1
    fi
    kill -INT "$(cat "$PIDFILE")"
    rm -f "$PIDFILE" "$STATEFILE"
    notify "Instant replay off" "Buffer discarded"
}

save() {
    if ! running; then
        notify "Instant replay" "Turn it on first"
        return 1
    fi
    kill -USR1 "$(cat "$PIDFILE")"
}

case "$1" in
    start) start ;;
    stop) stop ;;
    save) save ;;
    status) running ;;
    restore) [[ -e "$STATEFILE" ]] && start ;;
    toggle | "")
        if running; then stop; else start; fi
        ;;
    *) notify "Clip saved" "$1" ;;
esac
