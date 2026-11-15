#!/bin/sh
# hyprpaper, falling back to swaybg. In VirtualBox it goes straight to
# swaybg: hyprpaper's GPU path crashes there and wedges the VM's 3D.

CONF="$HOME/.config/hypr/hyprpaper.conf"
IMG="$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' "$CONF" 2>/dev/null | head -n 1)"

if [ "$(systemd-detect-virt 2>/dev/null)" != "oracle" ]; then
    # hyprpaper runs until the session ends; a clean exit means nothing to do.
    hyprpaper && exit 0
fi

if [ -n "$IMG" ] && [ -f "$IMG" ]; then
    exec swaybg -m fill -i "$IMG"
fi
