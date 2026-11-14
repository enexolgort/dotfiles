#!/usr/bin/env bash
# Checks one host's services from any device on the tailnet.
#
# Usage:
#   ./check-remote.sh --host <name-or-ip> [--sftp-user <name>] [--sftp-key <path>] [--samba]
#
#   --sftp-user   Also try a real SFTP login (default: port check only)
#   --sftp-key    Private key for that login
#   --samba       Also check Samba (real-machine hosts only)
#
# Exits 1 if any check failed.

set -uo pipefail

HOST=""
SFTP_USER=""
SFTP_KEY=""
CHECK_SAMBA=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --sftp-user) SFTP_USER="$2"; shift 2 ;;
    --sftp-key) SFTP_KEY="$2"; shift 2 ;;
    --samba) CHECK_SAMBA=true; shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^#//'
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ -t 1 ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  ${GREEN}✓${RESET} $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  ${RED}✗${RESET} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
warn() { echo "  ${YELLOW}!${RESET} $1"; }
section() { echo; echo "${BOLD}$1${RESET}"; }

if [ -z "$HOST" ]; then
  echo "!! --host is required, e.g.: $0 --host mnemosyne" >&2
  exit 1
fi

# TCP check via bash's /dev/tcp (no netcat needed).
check_port() {
  local host="$1" port="$2" label="$3"
  if timeout 5 bash -c "exec 3<>/dev/tcp/$host/$port" 2>/dev/null; then
    exec 3<&- 3>&- 2>/dev/null
    pass "$label (port $port open)"
    return 0
  else
    fail "$label (port $port unreachable — timeout or refused)"
    return 1
  fi
}

echo "${BOLD}Checking remote services on: $HOST${RESET}"

# --- 1. Tailscale
section "Tailscale"
if command -v tailscale >/dev/null 2>&1; then
  if tailscale ping -c 1 "$HOST" >/dev/null 2>&1; then
    pass "tailscale ping to $HOST succeeded"
  else
    fail "tailscale ping to $HOST failed — check Tailscale is connected on this device"
  fi
else
  warn "tailscale CLI not found on this client — skipping ping test, falling back to plain TCP checks only"
fi

# --- 2. SSH
section "SSH"
check_port "$HOST" 22 "SSH"

# --- 3. SFTP
section "SFTP"
if [ -n "$SFTP_USER" ] && [ -n "$SFTP_KEY" ]; then
  if [ ! -f "$SFTP_KEY" ]; then
    fail "SFTP key not found at $SFTP_KEY"
  elif timeout 10 sftp -o StrictHostKeyChecking=accept-new -o BatchMode=yes \
        -i "$SFTP_KEY" "$SFTP_USER@$HOST" <<< "pwd" >/dev/null 2>&1; then
    pass "SFTP login as $SFTP_USER succeeded"
  else
    fail "SFTP login as $SFTP_USER failed (bad key, wrong user, or chroot misconfigured)"
  fi
else
  warn "No --sftp-user/--sftp-key given — skipping actual login test (port already checked above via SSH)"
fi

# --- 4. Jellyfin
section "Jellyfin"
if command -v curl >/dev/null 2>&1; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://$HOST:8096" 2>/dev/null)"
  if [ "$code" = "200" ] || [ "$code" = "302" ]; then
    pass "Jellyfin responding (HTTP $code) at http://$HOST:8096"
  else
    fail "Jellyfin not responding as expected (got HTTP '${code:-no response}') at http://$HOST:8096"
  fi
else
  check_port "$HOST" 8096 "Jellyfin"
fi

# --- 5. CouchDB
section "CouchDB / Obsidian sync"
if command -v curl >/dev/null 2>&1; then
  body="$(curl -s --max-time 5 "http://$HOST:5984" 2>/dev/null)"
  if echo "$body" | grep -q '"couchdb":"Welcome"'; then
    pass "CouchDB responding correctly at http://$HOST:5984"
  else
    fail "CouchDB not responding as expected at http://$HOST:5984"
  fi
else
  check_port "$HOST" 5984 "CouchDB"
fi

# --- 6. Samba
if [ "$CHECK_SAMBA" = true ]; then
  section "Samba"
  check_port "$HOST" 445 "Samba"
else
  section "Samba"
  warn "Skipped (pass --samba to check; not applicable on the WSL target at all)"
fi

# --- Summary
echo
echo "${BOLD}Summary: $PASS_COUNT passed, $FAIL_COUNT failed${RESET}"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
