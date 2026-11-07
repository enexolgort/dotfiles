#!/bin/sh
# ~/.config/hypr/scripts/bluetooth-menu.sh — waybar Bluetooth click, Super+Shift+B.
#
# Opens Blueman's device manager. Without a Bluetooth adapter (e.g. the
# janus-vm VirtualBox guest) bluetoothd never starts and blueman-manager
# only shows a "Connection to BlueZ failed" error, so say so in a
# notification instead.

if [ -z "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]; then
    exec notify-send -a Bluetooth -i bluetooth-disabled \
        "Bluetooth" "No Bluetooth adapter found on this machine."
fi

exec blueman-manager
