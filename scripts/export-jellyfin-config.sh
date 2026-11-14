#!/usr/bin/env bash
# Snapshots Jellyfin's config, libraries and users. Run on the server.
#
# Usage:
#   ./export-jellyfin-config.sh [--api-key <key>] [--output-dir <path>] [--url <jellyfin-url>]
#
# --api-key    Optional; adds JSON summaries via the API
#              (Dashboard -> API Keys -> '+').
# --output-dir Default: ./jellyfin
# --url        Default: http://localhost:8096

set -euo pipefail

JELLYFIN_DATA_DIR="/var/lib/jellyfin"
OUTPUT_DIR="./jellyfin"
API_KEY=""
JELLYFIN_URL="http://localhost:8096"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key) API_KEY="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --url) JELLYFIN_URL="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^#//'
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [ ! -d "$JELLYFIN_DATA_DIR" ]; then
  echo "!! $JELLYFIN_DATA_DIR not found — is Jellyfin installed and has it run at least once?" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR/raw"

echo "==> Copying raw config from $JELLYFIN_DATA_DIR"
# cache/, metadata/ and transcodes/ are skipped: regenerable and large.
for sub in config data root plugins; do
  if [ -d "$JELLYFIN_DATA_DIR/$sub" ]; then
    sudo cp -r "$JELLYFIN_DATA_DIR/$sub" "$OUTPUT_DIR/raw/$sub"
    sudo chown -R "$(id -u):$(id -g)" "$OUTPUT_DIR/raw/$sub"
    echo "    copied $sub/"
  else
    echo "    (skipped $sub/ — not present)"
  fi
done

echo "==> Deriving library path list from root/ symlinks"
{
  echo "# Jellyfin libraries (name -> real path)"
  echo "# Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  if [ -d "$OUTPUT_DIR/raw/root" ]; then
    find "$OUTPUT_DIR/raw/root" -mindepth 2 -maxdepth 2 -type l 2>/dev/null | while read -r link; do
      name="$(basename "$link")"
      target="$(readlink -f "$link" || echo "(broken symlink)")"
      echo "$name -> $target"
    done
  fi
} > "$OUTPUT_DIR/libraries.txt"
cat "$OUTPUT_DIR/libraries.txt"

if [ -n "$API_KEY" ]; then
  echo "==> Fetching library and user summary via Jellyfin API"
  curl -fsS -H "X-Emby-Token: $API_KEY" "$JELLYFIN_URL/Library/VirtualFolders" \
    -o "$OUTPUT_DIR/libraries-api.json" \
    && echo "    saved libraries-api.json"
  curl -fsS -H "X-Emby-Token: $API_KEY" "$JELLYFIN_URL/Users" \
    -o "$OUTPUT_DIR/users-api.json" \
    && echo "    saved users-api.json (no passwords in there — Jellyfin's API never exposes those)"
else
  echo "==> No --api-key given, skipping the API-based JSON summary"
  echo "    (libraries.txt above already has the library paths; get an API key from"
  echo "     Settings -> API Keys -> '+' in the Jellyfin dashboard for the fuller JSON export)"
fi

echo "==> Done. Output in $OUTPUT_DIR/"
