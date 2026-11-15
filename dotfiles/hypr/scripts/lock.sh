#!/bin/sh
# hyprlock, or swaylock-effects in VirtualBox: hyprlock's GPU path crashes
# there and wedges the VM's 3D until reboot.

# Don't stack lock screens.
pidof hyprlock >/dev/null 2>&1 && exit 0
pidof swaylock >/dev/null 2>&1 && exit 0

if [ "$(systemd-detect-virt 2>/dev/null)" = "oracle" ]; then
    # -f so hypridle's lock_cmd returns
    exec swaylock -f
fi

exec hyprlock
