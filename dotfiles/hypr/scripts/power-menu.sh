#!/bin/sh
# ~/.config/hypr/scripts/power-menu.sh — waybar power button, Super+Escape.
#
# Opens wlogout (style + icons in ~/.config/wlogout) as one row of five
# square tiles centred on the focused screen, with the uptime written at
# the bottom. wlogout only takes pixel margins, so the tile size is
# worked out from the screen size here, and the uptime is drawn into an
# SVG used as the window background. Pressing it again closes the menu.

pkill -x wlogout && exit 0

# Focused monitor: logical size (pixels / scale).
read -r W H <<EOF
$(hyprctl monitors | awk '
    /^Monitor/            { res = ""; scale = 1 }
    /^\t[0-9]+x[0-9]+@/   { split($1, a, /[x@]/); w = a[1]; h = a[2] }
    /^\tscale:/           { scale = $2 }
    /^\tfocused: yes/     { printf "%d %d\n", w / scale, h / scale; exit }')
EOF
[ -n "$W" ] || { W=1920; H=1080; }

TILE=$((W * 11 / 100))                 # ~11% of the width, like the photo
[ "$TILE" -gt 240 ] && TILE=240
[ "$TILE" -lt 150 ] && TILE=150
SIDE=$(((W - 5 * TILE) / 2))
TOP=$(((H - TILE) / 2))

# "Uptime 1 hour 57 min"
SECS=$(cut -d. -f1 /proc/uptime)
HRS=$((SECS / 3600)); MINS=$((SECS % 3600 / 60))
if [ "$HRS" -eq 0 ]; then UP="$MINS min"
elif [ "$HRS" -eq 1 ]; then UP="1 hour $MINS min"
else UP="$HRS hours $MINS min"; fi

DIR="${XDG_RUNTIME_DIR:-/tmp}/power-menu"
mkdir -p "$DIR"
cat > "$DIR/uptime.svg" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="$W" height="$H" viewBox="0 0 $W $H">
  <text x="$((W / 2))" y="$((H - 40))" text-anchor="middle"
        font-family="JetBrainsMono Nerd Font" font-size="17" font-weight="bold"
        fill="#cdd6f4">Uptime $UP</text>
</svg>
EOF
cat > "$DIR/style.css" <<EOF
@import url("file://$HOME/.config/wlogout/style.css");
window {
    background-image: url("file://$DIR/uptime.svg");
    background-size: 100% 100%;
    background-repeat: no-repeat;
}
EOF

exec wlogout -b 5 -T "$TOP" -B "$TOP" -L "$SIDE" -R "$SIDE" -C "$DIR/style.css"
