#!/bin/sh
# ~/.config/hypr/scripts/lock.sh — lock the screen (Super+Tab, hypridle).
#
# hyprlock normally. Inside VirtualBox (janus-vm) hyprlock's GPU (EGL)
# path aborts, and the crash wedges VirtualBox's 3D so Hyprland itself
# can't start again until the VM reboots — so there we use
# swaylock-effects instead, which draws on the CPU. Both are themed
# Catppuccin Mocha (hypr/hyprlock.conf, swaylock/config).

# Don't stack lock screens.
pidof hyprlock >/dev/null 2>&1 && exit 0
pidof swaylock >/dev/null 2>&1 && exit 0

if [ "$(systemd-detect-virt 2>/dev/null)" = "oracle" ]; then
    # -f: fork once locked, so hypridle's lock_cmd returns immediately
    exec swaylock -f
fi

exec hyprlock
