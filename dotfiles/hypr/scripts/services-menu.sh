#!/bin/bash
# Pick a homelab service from the Homepage dashboard with rofi, open it.

HOMEPAGE_URL="${HOMEPAGE_URL:-http://mnemosyne:8082}"
DASHBOARD=$'\U000f04b6' # nf-md-view_dashboard

notify() { notify-send -a "Services" "$1" "${2:-}"; }

if ! services="$(curl -fsS -m 5 "$HOMEPAGE_URL/api/services" 2>/dev/null)"; then
    notify "Homepage unreachable" "$HOMEPAGE_URL"
    exit 1
fi

# One line per tile: "name (host)<TAB>url". rofi only shows the first field.
entries="$(jq -r '.[] | .name as $g | .services[]? | "\(.name) (\($g))\t\(.href)"' <<<"$services")"
entries="$DASHBOARD  Homepage"$'\t'"$HOMEPAGE_URL"$'\n'"$entries"

idx="$(printf '%s\n' "$entries" | cut -f1 | rofi -dmenu -i -p "Services" -format i)"
[ -z "$idx" ] && exit 0

url="$(printf '%s\n' "$entries" | sed -n "$((idx + 1))p" | cut -f2)"
exec xdg-open "$url"
