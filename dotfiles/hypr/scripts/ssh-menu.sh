#!/bin/bash
# Pick a Linux machine on the tailnet with rofi, SSH into it in kitty.

ONLINE=$'\U000f0318'  # nf-md-lan_connect
OFFLINE=$'\U000f0319' # nf-md-lan_disconnect

notify() { notify-send -a "SSH" "$1" "${2:-}"; }

# Short MagicDNS name (first DNSName label): HostName may contain spaces.
hosts="$(tailscale status --json 2>/dev/null | jq -r --arg on "$ONLINE" --arg off "$OFFLINE" '
    [.Peer[]? | select(.OS == "linux")
     | {name: (.DNSName | split(".")[0]), online: .Online}]
    | sort_by((.online | not), .name)[]
    | "\(if .online then $on else $off end)  \(.name)"')"

if [ -z "$hosts" ]; then
    notify "No tailnet machines found" "Is tailscale up?"
    exit 1
fi

choice="$(printf '%s\n' "$hosts" | rofi -dmenu -i -p "SSH")"
[ -z "$choice" ] && exit 0

host="${choice##* }"
exec kitty --title "ssh $host" ssh "$host"
