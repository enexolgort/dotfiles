#!/bin/sh
# ~/.config/hypr/scripts/wallpaper.sh — started from hyprland.lua's autostart.
#
# Runs hyprpaper. If it fails — as on janus-vm, where its GPU (EGL) path
# crashes under VirtualBox a few seconds in ("ASSERTION FAILED ...
# Backend.cpp", core dumped) — falls back to swaybg, which draws on the
# CPU, using the same image that post-install.sh wrote into
# hyprpaper.conf.

CONF="$HOME/.config/hypr/hyprpaper.conf"
IMG="$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' "$CONF" 2>/dev/null | head -n 1)"

# hyprpaper runs until the session ends; a clean exit means nothing to do.
hyprpaper && exit 0

if [ -n "$IMG" ] && [ -f "$IMG" ]; then
    exec swaybg -m fill -i "$IMG"
fi
