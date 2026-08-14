#!/usr/bin/env bash
# post-install.sh
# One-time manual steps to run after `nixos-rebuild switch` succeeds.
# These aren't things NixOS can set declaratively (loginctl linger state
# isn't managed by a nix option, tailscale/passwd need interactive input),
# so they live here instead of in configuration.nix.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CURRENT_HOST="$(hostname)"
VARS_FILE="$REPO_ROOT/nixOS/hosts/$CURRENT_HOST/vars.nix"

if [ -f "$VARS_FILE" ]; then
  USERNAME="$(nix --extra-experimental-features 'nix-command' eval --raw --file "$VARS_FILE" username)"
else
  echo "!! Could not find $VARS_FILE (this machine's hostname is '$CURRENT_HOST' — does hosts/$CURRENT_HOST/ exist in the repo?), falling back to \$USER ($USER)"
  USERNAME="$USER"
fi

echo "==> Enabling linger for $USERNAME (keeps user services, e.g. the Emacs daemon, running without an active login session)"
sudo loginctl enable-linger "$USERNAME"

# --- Doom Emacs: bootstrap if needed, deploy your tracked config from
# the repo's doom/ folder, then sync. Safe to re-run any time — copying
# is a plain overwrite and `doom sync` is idempotent.
DOOM_BIN="$HOME/.config/emacs/bin/doom"
DOOM_CONF="$HOME/.config/doom"
DOOM_SRC_DIR="$REPO_ROOT/doom"

if [ -x "$DOOM_BIN" ]; then
  if [ ! -d "$DOOM_CONF" ]; then
    echo "==> Doom not bootstrapped yet, running 'doom install' first"
    "$DOOM_BIN" install --no-env --no-fonts -!
  fi

  if [ -d "$DOOM_SRC_DIR" ]; then
    echo "==> Deploying tracked Doom config from $DOOM_SRC_DIR to $DOOM_CONF"
    mkdir -p "$DOOM_CONF"
    for f in init.el config.el packages.el; do
      if [ -f "$DOOM_SRC_DIR/$f" ]; then
        cp "$DOOM_SRC_DIR/$f" "$DOOM_CONF/$f"
        echo "    copied $f"
      fi
    done
  else
    echo "!! No doom/ folder found at $DOOM_SRC_DIR — leaving \$DOOM_CONF as-is"
    echo "   (run 'mkdir ~/dotFiles/doom && cp ~/.config/doom/*.el ~/dotFiles/doom/' to start tracking it)"
  fi

  echo "==> Running 'doom sync' to install/update packages and apply config"
  "$DOOM_BIN" sync
else
  echo "!! $DOOM_BIN not found — Emacs/Doom may not have been cloned yet."
  echo "   Run 'sudo nixos-rebuild switch' again first, or check ~/.config/emacs exists."
fi

echo "==> Done."
echo

# --- 43PR/dotfiles: only for desktop hosts (desktopEnable = true) --------
# Manually-triggered here rather than a home.activation script — that
# approach only re-runs when the system generation actually changes, and
# a no-op rebuild silently skipped it entirely with zero error shown.
# Re-running this is always safe: skips the clone if already cached,
# and the copy is a plain overwrite.
DESKTOP_ENABLE="false"
if [ -f "$VARS_FILE" ]; then
  DESKTOP_ENABLE="$(nix --extra-experimental-features 'nix-command' eval --raw --file "$VARS_FILE" desktopEnable 2>/dev/null || echo "false")"
fi

if [ "$DESKTOP_ENABLE" = "true" ]; then
  echo "==> desktopEnable = true for '$CURRENT_HOST' — setting up 43PR/dotfiles"
  DOTFILES_CACHE="$HOME/.cache/43pr-dotfiles"

  if [ ! -d "$DOTFILES_CACHE" ]; then
    echo "==> Cloning 43PR/dotfiles..."
    if ! git clone --depth 1 https://github.com/43PR/dotfiles "$DOTFILES_CACHE"; then
      echo "!! 43PR/dotfiles clone failed — check network and retry this script"
      DOTFILES_CACHE=""
    fi
  else
    echo "==> 43PR/dotfiles already cloned, skipping (delete $DOTFILES_CACHE to re-clone fresh)"
  fi

  if [ -n "$DOTFILES_CACHE" ] && [ -d "$DOTFILES_CACHE/.config" ]; then
    mkdir -p "$HOME/.config"
    for dir in "$DOTFILES_CACHE"/.config/*/; do
      name="$(basename "$dir")"
      # Skip neofetch specifically — it's already managed separately by
      # home.nix's own xdg.configFile declaration (a home-manager-managed
      # read-only symlink into the Nix store), which a plain cp can't
      # write over and would fail on otherwise.
      if [ "$name" = "neofetch" ]; then
        echo "    skipped neofetch (managed separately by home.nix)"
        continue
      fi
      cp -rT "$dir" "$HOME/.config/$name"
      echo "    copied $name"
    done
  fi
fi

echo
echo "Still manual (not scriptable, need interactive input):"
echo "  - sudo tailscale up --ssh        # one-time tailnet login"
echo "  - passwd                          # replace the initial placeholder password"
echo "  - sudo smbpasswd -a $USERNAME     # only if you're using the Samba share"