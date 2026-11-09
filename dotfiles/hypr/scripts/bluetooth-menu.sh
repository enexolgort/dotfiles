#!/bin/sh
# Opens Blueman, or a notification when there's no Bluetooth adapter.

if [ -z "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]; then
    exec notify-send -a Bluetooth -i bluetooth-disabled \
        "Bluetooth" "No Bluetooth adapter found on this machine."
fi

exec blueman-manager
