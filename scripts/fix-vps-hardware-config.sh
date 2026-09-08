#!/usr/bin/env bash
# fix-vps-hardware-config.sh
# Run this ON THE VPS ITSELF (not on your dev machine) once it's installed
# and booted normally. hosts/vps/hardware-configuration.nix started out as
# a generic placeholder, and a manual `nixos-generate-config --root /mnt` +
# cp round-trip during initial setup ended up dropping the fileSystems."/"
# block entirely, which is why `nixos-rebuild switch --flake .#vps` kept
# failing with "The 'fileSystems' option does not specify your root file
# system." This regenerates the file directly from the *running* system
# (no /mnt needed at this point — it's already installed) and rebuilds.
#
# Safe to re-run any time: nixos-generate-config's output is fully
# regenerated each run, not patched.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "!! Must run as root (needs to read disk UUIDs and rebuild). Re-run with sudo." >&2
  exit 1
fi

# Locate the flake root. Two layouts exist in the wild: a flattened
# checkout (e.g. /etc/nixos, flake.nix directly at the root) and the
# original dotfiles clone (flake.nix nested one level down, at nixOS/).
# Walk up from this script and check both possibilities at each level.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIR="$SCRIPT_DIR"
REPO_ROOT=""
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/flake.nix" ]; then
    REPO_ROOT="$DIR"
    break
  elif [ -f "$DIR/nixOS/flake.nix" ]; then
    REPO_ROOT="$DIR/nixOS"
    break
  fi
  DIR="$(dirname "$DIR")"
done

if [ -z "$REPO_ROOT" ]; then
  echo "!! Could not find flake.nix (directly, or under nixOS/) by walking up from $SCRIPT_DIR — is this script still inside the flake repo?" >&2
  exit 1
fi

HW_FILE="$REPO_ROOT/hosts/vps/hardware-configuration.nix"

if [ ! -d "$REPO_ROOT/hosts/vps" ]; then
  echo "!! $REPO_ROOT/hosts/vps does not exist — nothing to fix." >&2
  exit 1
fi

echo "==> Flake root: $REPO_ROOT"
echo "==> Backing up current $HW_FILE to ${HW_FILE}.bak"
cp -f "$HW_FILE" "${HW_FILE}.bak" 2>/dev/null || true

echo "==> Regenerating hardware-configuration.nix from the running system"
nixos-generate-config --show-hardware-config > "$HW_FILE"

if ! grep -q 'fileSystems."/"' "$HW_FILE"; then
  echo "!! Generated file still has no fileSystems.\"/\" block — something is wrong with disk detection on this machine." >&2
  echo "   Restoring backup and aborting." >&2
  mv -f "${HW_FILE}.bak" "$HW_FILE" 2>/dev/null || true
  exit 1
fi

echo "==> New hardware-configuration.nix:"
cat "$HW_FILE"
echo

# If this is a git checkout, make sure the file is actually tracked/staged —
# an untracked file inside a git-based flake source can be silently ignored
# by Nix's flake evaluation.
if [ -d "$REPO_ROOT/.git" ]; then
  echo "==> Staging hosts/vps/hardware-configuration.nix in git (required for flakes to see it)"
  git -C "$REPO_ROOT" add "hosts/vps/hardware-configuration.nix"
fi

echo "==> Rebuilding vps"
nixos-rebuild switch --flake "$REPO_ROOT#vps"

echo
echo "==> Done. Still manual (not scriptable, need interactive input):"
echo "  - tailscale up --ssh   # one-time tailnet login"
echo "  - passwd               # replace the initial placeholder password"
