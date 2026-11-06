#!/bin/sh
# ~/.config/hypr/scripts/wallpaper.sh — started from hyprland.lua's autostart.
#
# Runs hyprpaper. If it dies right away — as on janus-vm, where its GPU
# (EGL) path crashes under VirtualBox ("ASSERTION FAILED ... Backend.cpp")
# — falls back to swaybg, which draws on the CPU, using the same image
# that post-install.sh wrote into hyprpaper.conf.

CONF="$HOME/.config/hypr/hyprpaper.conf"
IMG="$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' "$CONF" 2>/dev/null | head -n 1)"

hyprpaper &
pid=$!
sleep 3

if kill -0 "$pid" 2>/dev/null; then
    wait "$pid"
elif [ -n "$IMG" ] && [ -f "$IMG" ]; then
    exec swaybg -m fill -i "$IMG"
fi
