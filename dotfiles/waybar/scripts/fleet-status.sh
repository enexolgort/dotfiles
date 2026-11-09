#!/usr/bin/env bash
# Waybar module: fleet health from the Homepage dashboard API on mnemosyne.
set -uo pipefail

HOMEPAGE_URL="${HOMEPAGE_URL:-http://mnemosyne:8082}"
ICON="󰒍"

if ! services="$(curl -fsS -m 5 "$HOMEPAGE_URL/api/services" 2>/dev/null)"; then
  printf '{"text":"%s ?","class":"unreachable","tooltip":"Homepage unreachable (%s)"}\n' "$ICON" "$HOMEPAGE_URL"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Checks run in parallel with a timeout: Homepage never answers for a
# service whose host is offline.
count=0
while IFS=$'\t' read -r group name; do
  count=$((count + 1))
  (
    body="$(curl -sS -m 8 -G "$HOMEPAGE_URL/api/siteMonitor" \
      --data-urlencode "groupName=$group" \
      --data-urlencode "serviceName=$name" 2>/dev/null)" || body=""
    jq -nc --arg g "$group" --arg n "$name" --arg body "$body" \
      '{group: $g, name: $n} + (($body | fromjson?) // {})' >"$tmp/$count.json"
  ) &
done < <(jq -r '.[] | .name as $g | .services[]? | [$g, .name] | @tsv' <<<"$services" 2>/dev/null)
wait

for ((n = 1; n <= count; n++)); do
  cat "$tmp/$n.json"
done | jq -sc --arg icon "$ICON" '
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  # Same rule as Homepage: any HTTP status above 403 counts as down.
  map(. + {up: ((.status // 0) > 0 and (.status // 0) <= 403)}) as $s
  | ($s | map(select(.up)) | length) as $up
  | ($s | length) as $total
  | {
      text: "\($icon) \($up)/\($total)",
      class: (if $total == 0 then "unreachable"
              elif $up == $total then "ok"
              elif $up == 0 then "down"
              else "degraded" end),
      tooltip: (
        ($s | group_by(.group) | map(
          "<b>\(.[0].group | esc)</b>\n" + (map(
            (if .up then "<span color=\"#a6e3a1\">●</span> " else "<span color=\"#f38ba8\">●</span> " end)
            + (.name | esc)
            + (if .up then "  \((.latency // 0) | round) ms"
               elif .status then "  (\(.status))"
               else "  (no answer)" end)
          ) | join("\n"))
        ) | join("\n\n"))
        + "\n\nClick: open Homepage · Right-click: refresh"
      )
    }'
