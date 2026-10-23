#!/usr/bin/env bash
# test-all-services.sh
# Run from your laptop (or any device on your tailnet) — checks every
# service across every host in one shot. Companion to check-remote.sh,
# which is scoped to a single host at a time; this one covers the whole
# fleet. Uses bare hostnames (mnemosyne, hermes, athena, argus) assuming
# Tailscale MagicDNS resolves them — if that's not working for you, edit
# the host variables below to use tailscale IPs instead.

set -uo pipefail

MNEMOSYNE="mnemosyne"
HERMES="hermes"
ATHENA="athena"
ARGUS="argus"

PASS=0
FAIL=0

# TCP-only reachability check (no HTTP involved) — used for SSH.
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

# HTTP reachability check — any response at all (even a redirect or 4xx)
# counts as "reachable", since this is a smoke test for connectivity,
# not a check that every service is fully configured/logged into.
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

# Like check_http, but also verifies the response body contains an
# expected string — for endpoints where "responded with something"
# isn't precise enough and you actually want to confirm the right
# content came back (e.g. a health-check endpoint's expected JSON).
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

echo "=== mnemosyne (Jellyfin, SFTP, transmission-webUi) ==="
check_tcp "$MNEMOSYNE" 22 "SSH"
check_http "$MNEMOSYNE" 8096 "/" "Jellyfin"
check_http "$MNEMOSYNE" 4173 "/" "transmission-webUi"

echo
echo "=== hermes (Obsidian/CouchDB, transmission-API) ==="
check_tcp "$HERMES" 22 "SSH"
check_http "$HERMES" 5984 "/" "CouchDB"
check_json_field "$HERMES" 3001 "/health" "transmission-API health" '"status":"ok"'

echo
echo "=== athena (local AI) ==="
check_tcp "$ATHENA" 22 "SSH"
check_http "$ATHENA" 11434 "/" "Ollama API"
check_http "$ATHENA" 8080 "/" "Open WebUI"

echo
echo "=== argus (monitoring hub — skip/ignore if not installed yet) ==="
check_tcp "$ARGUS" 22 "SSH"
check_http "$ARGUS" 9090 "/" "Prometheus"
check_http "$ARGUS" 3000 "/" "Grafana"
check_http "$ARGUS" 8000 "/" "restic REST server"

echo
echo "Summary: $PASS passed, $FAIL failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi