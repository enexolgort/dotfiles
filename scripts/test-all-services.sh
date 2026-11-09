#!/usr/bin/env bash
# Checks every service on every host from any tailnet device. Relies on
# MagicDNS; use Tailscale IPs below if names don't resolve.

set -uo pipefail

MNEMOSYNE="mnemosyne"
HERMES="hermes"
ATHENA="athena"

PASS=0
FAIL=0

check_tcp() {
  local host="$1" port="$2" label="$3"
  if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
    echo "  [OK]   $label ($host:$port)"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label ($host:$port unreachable)"
    FAIL=$((FAIL + 1))
  fi
}

# Any HTTP response (even 4xx) counts as reachable.
check_http() {
  local host="$1" port="$2" path="$3" label="$4"
  local url="http://${host}:${port}${path}"
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null)"
  if [ -n "$code" ] && [ "$code" != "000" ]; then
    echo "  [OK]   $label (HTTP $code) — $url"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label unreachable — $url"
    FAIL=$((FAIL + 1))
  fi
}

# Like check_http, but the body must contain the expected string.
check_json_field() {
  local host="$1" port="$2" path="$3" label="$4" expected="$5"
  local url="http://${host}:${port}${path}"
  local body
  body="$(curl -s --max-time 5 "$url" 2>/dev/null)"
  if [ -n "$body" ] && echo "$body" | grep -q "$expected"; then
    echo "  [OK]   $label ($url) — got expected response"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label ($url) — expected to contain: $expected"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== mnemosyne (Jellyfin, SFTP, transmission-webUi, Forgejo) ==="
check_tcp "$MNEMOSYNE" 22 "SSH"
check_http "$MNEMOSYNE" 8096 "/" "Jellyfin"
check_http "$MNEMOSYNE" 3000 "/" "Forgejo"
check_http "$MNEMOSYNE" 4173 "/" "transmission-webUi"

echo
echo "=== hermes (transmission-API) ==="
check_tcp "$HERMES" 22 "SSH"
check_json_field "$HERMES" 3001 "/health" "transmission-API health" '"status":"ok"'

echo
echo "=== athena (local AI) ==="
check_tcp "$ATHENA" 22 "SSH"
check_http "$ATHENA" 11434 "/" "Ollama API"
check_http "$ATHENA" 8080 "/" "Open WebUI"


echo
echo "Summary: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi