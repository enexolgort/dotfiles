#!/bin/bash
# wifi-menu.sh — pick a WiFi network with rofi -dmenu, connect via nmcli.
# Known networks connect straight away; new secured ones prompt for the
# password in a second rofi box. nm-applet / nm-connection-editor stay
# around for anything more advanced (VPN, static IPs, hidden SSIDs).

# Nerd Font glyphs, spelled as escapes so they survive any editor
LOCK=$''      # nf-fa-lock
WIFI_ON=$'\U000f05a9'  # nf-md-wifi
WIFI_OFF=$'\U000f05aa' # nf-md-wifi_off

notify() { notify-send -a "WiFi" "$1" "${2:-}"; }

connect() {
    if nmcli "$@" >/dev/null 2>&1; then
        notify "Connected" "$ssid"
    else
        notify "Failed to connect" "$ssid"
    fi
}

if [ "$(nmcli -t -f WIFI radio)" = "enabled" ]; then
    menu="$WIFI_OFF  Turn WiFi off"
    # SSID list: strongest first, one line per SSID, lock if secured,
    # "*" marker on the network we're currently connected to.
    networks="$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan auto 2>/dev/null \
        | awk -F: -v lock_icon="$LOCK" '{
            # SSID is the last field and may itself contain (escaped)
            # colons, so take everything after the third separator.
            ssid = $0; sub(/^[^:]*:[^:]*:[^:]*:/, "", ssid); gsub(/\\:/, ":", ssid)
            if (ssid == "" || seen[ssid]++) next
            lock = ($3 == "" || $3 == "--") ? " " : lock_icon
            mark = ($1 == "*") ? "*" : " "
            printf "%s %s %3s%%  %s\n", mark, lock, $2, ssid
        }')"
    [ -n "$networks" ] && menu="$menu"$'\n'"$networks"
else
    menu="$WIFI_ON  Turn WiFi on"
fi

choice="$(printf '%s\n' "$menu" | rofi -dmenu -i -p "WiFi")"
[ -z "$choice" ] && exit 0

case "$choice" in
    *"Turn WiFi off") nmcli radio wifi off; notify "WiFi off"; exit 0 ;;
    *"Turn WiFi on")  nmcli radio wifi on;  notify "WiFi on";  exit 0 ;;
esac

# Everything after the first "%  " (the signal column) is the SSID —
# the marker/lock/signal columns before it never contain a "%".
ssid="${choice#*%  }"

# Already-saved network: just bring it up
if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    connect connection up id "$ssid"
elif [[ "$choice" == *"$LOCK"* ]]; then
    pass="$(rofi -dmenu -password -p "Password for $ssid" < /dev/null)"
    [ -z "$pass" ] && exit 0
    connect device wifi connect "$ssid" password "$pass"
else
    connect device wifi connect "$ssid"
fi
