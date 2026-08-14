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
DOOM_SRC_DIR="$REPO_ROOT/dotfiles/doom"

if [ -x "$DOOM_BIN" ]; then
  if [ ! -d "$DOOM_CONF" ]; then
    echo "==> Doom not bootstrapped yet, running 'doom install' first"
    "$DOOM_BIN" install --no-env -!
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
    echo "   (run 'mkdir ~/dotfiles/dotfiles/doom && cp ~/.config/doom/*.el ~/dotfiles/dotfiles/doom/' to start tracking it)"
  fi

  echo "==> Running 'doom sync' to install/update packages and apply config"
  "$DOOM_BIN" sync
else
  echo "!! $DOOM_BIN not found — Emacs/Doom may not have been cloned yet."
  echo "   Run 'sudo nixos-rebuild switch' again first, or check ~/.config/emacs exists."
fi

echo "==> Done."
echo

# --- Hyprland config: copy from your own tracked dotfiles/{hypr,waybar}
# staging folders (not an external clone) — same pattern as Doom Emacs
# above. Only for desktop hosts (desktopEnable = true). Safe to re-run
# any time — copying is a plain overwrite, and every sed fix below only
# matches text that hasn't already been fixed.
DOTFILES_STAGING="$REPO_ROOT/dotfiles"

DESKTOP_ENABLE="false"
if [ -f "$VARS_FILE" ]; then
  DESKTOP_ENABLE="$(nix --extra-experimental-features 'nix-command' eval --file "$VARS_FILE" desktopEnable 2>/dev/null || echo "false")"
fi

if [ "$DESKTOP_ENABLE" = "true" ]; then
  if [ -d "$DOTFILES_STAGING" ]; then
    mkdir -p "$HOME/.config"
    for dir in "$DOTFILES_STAGING"/*/; do
      name="$(basename "$dir")"
      # doom is handled separately above, from its own top-level doom/
      # folder — skip it here to avoid two mechanisms both writing to
      # ~/.config/doom.
      if [ "$name" = "doom" ]; then
        continue
      fi
      echo "==> Deploying tracked $name config from $dir to $HOME/.config/$name"
      mkdir -p "$HOME/.config/$name"
      cp -r "$dir." "$HOME/.config/$name/"
      echo "    copied $name"
    done

    if [ -d "$HOME/.config/hypr/scripts" ]; then
      find "$HOME/.config/hypr/scripts" -type f -exec chmod +x {} \;
    fi
    if [ -d "$HOME/.config/waybar/scripts" ]; then
      find "$HOME/.config/waybar/scripts" -type f -exec chmod +x {} \;
    fi

    # --- Fix known author-specific hardcodes ----------------------------
    # These files came from the 43PR/dotfiles upstream originally, which
    # has several values specific to that author's own machine/
    # preferences. Applied every run — sed -i on already-fixed text just
    # matches nothing the second time, so this stays safe to re-run.

    # Any hardcoded reference to the original author's own home
    # directory (found in hyprland.lua's wallpaper path AND separately
    # in waybar/config.jsonc's gpu_usage.sh path).
    grep -rl "/home/rp34" "$HOME/.config/hypr" "$HOME/.config/waybar" 2>/dev/null | while read -r f; do
      sed -i "s|/home/rp34|$HOME|g" "$f"
    done

    HYPR_CONF_FILE="$HOME/.config/hypr/hyprland.lua"
    if [ -f "$HYPR_CONF_FILE" ]; then
      # File manager: this repo installs Dolphin, not Thunar
      sed -i 's/fileManager = "thunar"/fileManager = "dolphin"/' "$HYPR_CONF_FILE"
      # Browser: opera was removed from nixpkgs, we use Firefox, not Brave
      sed -i 's/browser    = "brave"/browser    = "firefox"/' "$HYPR_CONF_FILE"
      # Notification daemon: we use mako, not dunst
      sed -i 's/hl.exec_cmd("dunst")/hl.exec_cmd("mako")/' "$HYPR_CONF_FILE"
      # polkit agent: hardcoded Arch path that doesn't exist on NixOS at
      # all (/nix/store paths, not /usr/lib) — but programs.hyprland
      # already handles polkit automatically, so just remove this line
      # rather than trying to fix the path.
      sed -i '/polkit-kde-authentication-agent/d' "$HYPR_CONF_FILE"
      # Wallpaper daemon: hyprpaper instead of awww (see common/desktop.nix
      # for why) — hyprpaper reads its own config file instead of a CLI
      # argument, so replace the daemon launch and drop the awww img line
      # entirely (hyprpaper.conf, written below, handles that instead).
      sed -i 's/hl.exec_cmd("awww-daemon")/hl.exec_cmd("hyprpaper")/' "$HYPR_CONF_FILE"
      sed -i '/awww img/d' "$HYPR_CONF_FILE"
      # Keyboard layout: this repo's whole vars.nix convention uses "fr"
      # (see hosts/defaults.nix) — was hardcoded to the original
      # author's own "us,latam".
      sed -i 's/kb_layout = "us,latam"/kb_layout = "fr"/' "$HYPR_CONF_FILE"
      # Monitor fallback: the upstream config only defines outputs named
      # after the original author's own laptop screens (eDP-1,
      # HDMI-A-1) — add a wildcard so *some* sane config applies
      # regardless of what this machine's actual output is named.
      if ! grep -q 'output = ""' "$HYPR_CONF_FILE"; then
        sed -i '/hl.monitor({ output = "eDP-1"/i hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })' "$HYPR_CONF_FILE"
      fi
    fi

    RULES_CONF_FILE="$HOME/.config/hypr/rules.lua"
    if [ -f "$RULES_CONF_FILE" ]; then
      # Cosmetic only — the opacity window-rule regex still lists
      # thunar/brave-browser by class name, so it'd silently never match
      # Dolphin/Firefox.
      sed -i 's/thunar|brave-browser/dolphin|firefox/' "$RULES_CONF_FILE"
    fi

    # hyprpaper's own config — only written if you actually have a
    # wallpaper somewhere to point it at. Nothing in your dotfiles/
    # staging folder provides one, so this is skipped cleanly (not an
    # error) unless you add images to ~/Pictures/Wallpapers/ yourself.
    FIRST_WALLPAPER="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null | sort | head -1)"
    if [ -n "$FIRST_WALLPAPER" ]; then
      mkdir -p "$HOME/.config/hypr"
      cat > "$HOME/.config/hypr/hyprpaper.conf" << EOF
preload = $FIRST_WALLPAPER
wallpaper = ,$FIRST_WALLPAPER
splash = false
EOF
      echo "    wrote hyprpaper.conf pointing at $FIRST_WALLPAPER"
    fi
  else
    echo "!! No dotfiles/ folder found at $DOTFILES_STAGING — leaving ~/.config as-is"
    echo "   (create ~/dotfiles/dotfiles/hypr/ etc. to start tracking your Hyprland config)"
  fi
fi

echo
echo "Still manual (not scriptable, need interactive input):"
echo "  - sudo tailscale up --ssh        # one-time tailnet login"
echo "  - passwd                          # replace the initial placeholder password"
echo "  - sudo smbpasswd -a $USERNAME     # only if you're using the Samba share"