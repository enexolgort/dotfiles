#!/bin/sh
# ~/.config/hypr/scripts/wallpaper.sh — started from hyprland.lua's autostart.
#
# Runs hyprpaper, falling back to swaybg (CPU-drawn) with the image that
# post-install.sh wrote into hyprpaper.conf. Inside VirtualBox (janus-vm)
# hyprpaper's GPU (EGL) path aborts a few seconds in, and that crash
# wedges VirtualBox's 3D until the VM reboots — so there it goes straight
# to swaybg without trying hyprpaper at all.

CONF="$HOME/.config/hypr/hyprpaper.conf"
IMG="$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' "$CONF" 2>/dev/null | head -n 1)"

if [ "$(systemd-detect-virt 2>/dev/null)" != "oracle" ]; then
    # hyprpaper runs until the session ends; a clean exit means nothing to do.
    hyprpaper && exit 0
fi

if [ -n "$IMG" ] && [ -f "$IMG" ]; then
    exec swaybg -m fill -i "$IMG"
fi
