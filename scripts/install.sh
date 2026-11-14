#!/usr/bin/env bash
# Usage: ./install.sh [host] [--regen-hardware]
#   1. Picks the host (argument or menu).
#   2. --regen-hardware overwrites the repo's hardware-configuration.nix
#      for that host, discarding manual edits.
#   3. Copies all of nixOS/ into /etc/nixos (every host must exist for the
#      flake to evaluate), keeping real hardware-configuration.nix files.
#   4. Clones or pulls the host's projectRepos and (re)starts any compose
#      projects.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NIXOS_SRC_DIR="$REPO_ROOT/nixOS"
NIXOS_DIR="/etc/nixos"

if [ ! -d "$NIXOS_SRC_DIR" ]; then
  echo "!! Expected nix files at $NIXOS_SRC_DIR but that folder doesn't exist."
  echo "   Adjust NIXOS_SRC_DIR at the top of this script if your repo layout differs."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "!! This script needs 'jq'. On a fresh machine before the first rebuild: nix-shell -p jq" >&2
  exit 1
fi

# --- 0. Pick which host, and check for --regen-hardware ------------------
REGEN_HARDWARE=false
HOST=""
for arg in "$@"; do
  case "$arg" in
    --regen-hardware) REGEN_HARDWARE=true ;;
    *) HOST="$arg" ;;
  esac
done

list_hosts() {
  find "$NIXOS_SRC_DIR/hosts" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

if [ -z "$HOST" ]; then
  mapfile -t AVAILABLE < <(list_hosts)
  if [ ${#AVAILABLE[@]} -eq 0 ]; then
    echo "!! No hosts found under $NIXOS_SRC_DIR/hosts" >&2
    exit 1
  fi
  if [ -t 0 ]; then
    echo "Which host are you installing/updating?"
    select choice in "${AVAILABLE[@]}"; do
      if [ -n "$choice" ]; then
        HOST="$choice"
        break
      fi
    done
  else
    echo "!! No host given and not an interactive terminal. Usage: $0 <host>" >&2
    echo "   Available hosts: ${AVAILABLE[*]}" >&2
    exit 1
  fi
fi

if [ ! -d "$NIXOS_SRC_DIR/hosts/$HOST" ]; then
  echo "!! Unknown host '$HOST' — no directory at $NIXOS_SRC_DIR/hosts/$HOST" >&2
  exit 1
fi

echo "==> Installing/updating host: $HOST"

# --- 0b. Warn if shared default passwords are still in hosts/defaults.nix ---
check_default_passwords() {
  local vars_file="$1"
  local found_defaults=()

  if [ ! -f "$vars_file" ]; then
    return 0
  fi

  grep -q 'initialPassword[[:space:]]*=[[:space:]]*"changeme"' "$vars_file" \
    && found_defaults+=("initialPassword ('changeme')")

  grep -q 'couchdbAdminPass[[:space:]]*=[[:space:]]*"changeme-couchdb"' "$vars_file" \
    && found_defaults+=("couchdbAdminPass ('changeme-couchdb')")

  grep -q 'gitAdminPass[[:space:]]*=[[:space:]]*"changeme-git"' "$vars_file" \
    && found_defaults+=("gitAdminPass ('changeme-git')")

  if [ ${#found_defaults[@]} -eq 0 ]; then
    return 0
  fi

  echo "!! WARNING: hosts/defaults.nix still has default placeholder password(s), shared by every host:"
  for d in "${found_defaults[@]}"; do
    echo "     - $d"
  done

  if [ ! -t 0 ]; then
    echo "   (non-interactive shell, continuing anyway — fix this before relying on the server)"
    return 0
  fi

  read -rp "   Continue anyway with these default passwords? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *)
      echo "Aborted. Edit $vars_file to set real passwords, then re-run this script."
      exit 1
      ;;
  esac
}

check_default_passwords "$NIXOS_SRC_DIR/hosts/defaults.nix"

# --- 0c. Optionally regenerate hardware-configuration.nix -----------------
if [ "$REGEN_HARDWARE" = true ]; then
  echo "==> Regenerating hardware-configuration.nix for '$HOST' from this machine's actual hardware..."
  sudo nixos-generate-config
  sudo cp /etc/nixos/hardware-configuration.nix "$NIXOS_SRC_DIR/hosts/$HOST/hardware-configuration.nix"
  sudo chown "$(id -u):$(id -g)" "$NIXOS_SRC_DIR/hosts/$HOST/hardware-configuration.nix"
  echo "==> Updated $NIXOS_SRC_DIR/hosts/$HOST/hardware-configuration.nix"
  echo "    Review it, then commit it to git once the rebuild below succeeds."
fi

# --- 1. Copy the whole nixOS/ tree into /etc/nixos -----------------------
echo "==> Copying $NIXOS_SRC_DIR into $NIXOS_DIR"
sudo mkdir -p "$NIXOS_DIR"

# Keep real hardware-configuration.nix files over the repo's placeholders.
# If the repo ships a real one (janus-vm), the repo wins.
HW_PLACEHOLDER_MARK="PLACEHOLDER — DO NOT USE AS-IS"
is_placeholder() { [ -f "$1" ] && grep -q "$HW_PLACEHOLDER_MARK" "$1"; }

TMP_HW_BACKUP="$(mktemp -d)"
if [ -d "$NIXOS_DIR/hosts" ]; then
  for hostDir in "$NIXOS_DIR"/hosts/*/; do
    [ -d "$hostDir" ] || continue
    hwFile="$hostDir/hardware-configuration.nix"
    if [ -f "$hwFile" ] && ! is_placeholder "$hwFile"; then
      hostName="$(basename "$hostDir")"
      mkdir -p "$TMP_HW_BACKUP/$hostName"
      sudo cp "$hwFile" "$TMP_HW_BACKUP/$hostName/hardware-configuration.nix"
    fi
  done
fi

sudo rm -rf "$NIXOS_DIR"
sudo mkdir -p "$NIXOS_DIR"
sudo cp -r "$NIXOS_SRC_DIR"/. "$NIXOS_DIR"/

for hostNameDir in "$TMP_HW_BACKUP"/*/; do
  [ -d "$hostNameDir" ] || continue
  hostName="$(basename "$hostNameDir")"
  # Host removed from the repo.
  if [ ! -d "$NIXOS_DIR/hosts/$hostName" ]; then
    echo "==> Skipping hardware-configuration.nix for '$hostName' (host no longer in repo)"
    continue
  fi
  if ! is_placeholder "$NIXOS_SRC_DIR/hosts/$hostName/hardware-configuration.nix"; then
    echo "==> Using the repo's hardware-configuration.nix for host '$hostName'"
    continue
  fi
  if [ -f "$hostNameDir/hardware-configuration.nix" ]; then
    sudo cp "$hostNameDir/hardware-configuration.nix" "$NIXOS_DIR/hosts/$hostName/hardware-configuration.nix"
    echo "==> Preserved existing real hardware-configuration.nix for host '$hostName'"
  fi
done
rm -rf "$TMP_HW_BACKUP"

# Only exists after the doc/secrets.md setup.
SECRETS_SRC="$REPO_ROOT/secrets.yaml"
if [ -f "$SECRETS_SRC" ]; then
  sudo cp "$SECRETS_SRC" "$NIXOS_DIR/secrets.yaml"
  echo "==> Copied secrets.yaml"
fi

# --- 2. Clone this host's project repos ----------------------------------
PROJECTS_DIR="$(nix --extra-experimental-features 'nix-command' eval --raw --file "$NIXOS_SRC_DIR/hosts/defaults.nix" projectsDir 2>/dev/null || echo "/data/projects")"

mapfile -t REPOS < <(
  nix --extra-experimental-features 'nix-command' eval --json \
    --file "$NIXOS_SRC_DIR/hosts/$HOST/vars.nix" projectRepos 2>/dev/null \
    | jq -r '.[]' 2>/dev/null || true
)

# Skipped when Docker isn't usable yet (before the first rebuild).
rebuild_compose_project() {
  local name="$1" dir="$2" f compose_file=""
  for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
    if [ -f "$dir/$f" ]; then compose_file="$f"; break; fi
  done
  [ -n "$compose_file" ] || return 0

  local compose=()
  if docker compose version >/dev/null 2>&1; then
    compose=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    compose=(docker-compose)
  fi
  if [ ${#compose[@]} -eq 0 ] || ! docker info >/dev/null 2>&1; then
    echo "!! Docker not available yet, skipping rebuild of $name"
    echo "   After nixos-rebuild: (cd \"$dir\" && docker compose up -d --build)"
    return 0
  fi

  echo "==> Rebuilding and restarting $name ($compose_file)..."
  if ! (cd "$dir" && "${compose[@]}" -f "$compose_file" up -d --build); then
    echo "!! Docker rebuild failed for $name — check the output above"
  fi
}

if [ ${#REPOS[@]} -eq 0 ]; then
  echo "==> No projectRepos declared for host '$HOST', skipping project cloning"
else
  sudo mkdir -p "$PROJECTS_DIR"
  sudo chown "$(id -u):$(id -g)" "$PROJECTS_DIR"
  echo "==> Projects dir: $PROJECTS_DIR"

  for repo_url in "${REPOS[@]}"; do
    name="$(basename "$repo_url")"
    target="$PROJECTS_DIR/$name"

    if [ -d "$target/.git" ]; then
      echo "==> $name already cloned, pulling latest..."
      # A failed pull only warns.
      if ! git -C "$target" pull --ff-only; then
        echo "!! Could not fast-forward $name (local changes or diverged history?), skipping its rebuild"
        continue
      fi
      rebuild_compose_project "$name" "$target"
      continue
    fi

    echo "==> Cloning $name..."
    if ! git clone "$repo_url" "$target"; then
      echo "!! Could not clone $name from $repo_url, skipping it"
      continue
    fi
    rebuild_compose_project "$name" "$target"
  done
fi

echo "==> Done."
echo "    Run: sudo nixos-rebuild switch --flake $NIXOS_DIR#$HOST"
