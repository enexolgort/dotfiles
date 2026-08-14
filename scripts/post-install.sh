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

# --- Hyprland dotfiles (43PR/dotfiles, Lua-based Hyprland config) —
# only for desktop hosts (desktopEnable = true) ---------------------------
# Manually-triggered here rather than a home.activation script — that
# approach only re-runs when the system generation actually changes, and
# a no-op rebuild silently skipped it entirely with zero error shown.
# Re-running this is always safe: pulls latest if already cloned, and
# every copy/edit below is idempotent (plain overwrite, sed -i on
# already-corrected text just matches nothing the second time).
DESKTOP_ENABLE="false"
if [ -f "$VARS_FILE" ]; then
  DESKTOP_ENABLE="$(nix --extra-experimental-features 'nix-command' eval --raw --file "$VARS_FILE" desktopEnable 2>/dev/null || echo "false")"
fi

if [ "$DESKTOP_ENABLE" = "true" ]; then
  echo "==> desktopEnable = true for '$CURRENT_HOST' — setting up Hyprland dotfiles"
  DOTFILES_CACHE="$HOME/.cache/43pr-dotfiles"

  if [ ! -d "$DOTFILES_CACHE" ]; then
    echo "==> Cloning 43PR/dotfiles..."
    if ! git clone --depth 1 https://github.com/43PR/dotfiles "$DOTFILES_CACHE"; then
      echo "!! 43PR/dotfiles clone failed — check network and retry this script"
      DOTFILES_CACHE=""
    fi
  else
    echo "==> Already cloned — pulling latest (the upstream repo has changed format before, from .conf to .lua)"
    git -C "$DOTFILES_CACHE" pull --ff-only || echo "!! git pull failed, using whatever's already cached"
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

    # Wallpapers — the dotfiles author's own install.sh does this too.
    if [ -d "$DOTFILES_CACHE/Wallpapers" ]; then
      mkdir -p "$HOME/Pictures/Wallpapers"
      cp -rT "$DOTFILES_CACHE/Wallpapers" "$HOME/Pictures/Wallpapers"
      echo "    copied Wallpapers"
    fi

    # --- Fix known author-specific hardcodes ----------------------------
    # The upstream config has several values specific to the original
    # author's own machine/preferences that don't apply here. Applied
    # every run — sed -i on already-fixed text just matches nothing the
    # second time, so this stays safe to re-run.

    # Any hardcoded reference to the original author's own home
    # directory (found in hyprland.lua's wallpaper path AND separately
    # in waybar/config.jsonc's gpu_usage.sh path) — broad sweep across
    # every copied file catches both plus anything else with the same
    # pattern, rather than tracking each file individually.
    grep -rl "/home/rp34" "$HOME/.config/hypr" "$HOME/.config/waybar" 2>/dev/null | while read -r f; do
      sed -i "s|/home/rp34|$HOME|g" "$f"
    done

    HYPR_CONF="$HOME/.config/hypr/hyprland.lua"
    if [ -f "$HYPR_CONF" ]; then
      # File manager: this repo installs Dolphin, not Thunar
      sed -i 's/fileManager = "thunar"/fileManager = "dolphin"/' "$HYPR_CONF"
      # Browser: opera was removed from nixpkgs, we use Firefox, not Brave
      sed -i 's/browser    = "brave"/browser    = "firefox"/' "$HYPR_CONF"
      # Notification daemon: we use mako, not dunst
      sed -i 's/hl.exec_cmd("dunst")/hl.exec_cmd("mako")/' "$HYPR_CONF"
      # polkit agent: hardcoded Arch path that doesn't exist on NixOS at
      # all (/nix/store paths, not /usr/lib) — but programs.hyprland
      # already handles polkit automatically, so just remove this line
      # rather than trying to fix the path.
      sed -i '/polkit-kde-authentication-agent/d' "$HYPR_CONF"
      # Wallpaper daemon: hyprpaper instead of awww (see common/desktop.nix
      # for why) — hyprpaper reads its own config file instead of a CLI
      # argument, so replace the daemon launch and drop the awww img line
      # entirely (hyprpaper.conf, written below, handles that instead).
      sed -i 's/hl.exec_cmd("awww-daemon")/hl.exec_cmd("hyprpaper")/' "$HYPR_CONF"
      sed -i '/awww img/d' "$HYPR_CONF"
      # Keyboard layout: this repo's whole vars.nix convention uses "fr"
      # (see hosts\/defaults.nix) — was hardcoded to the original
      # author's own "us,latam".
      sed -i 's/kb_layout = "us,latam"/kb_layout = "fr"/' "$HYPR_CONF"
      # Monitor fallback: the upstream config only defines outputs named
      # after the original author's own laptop screens (eDP-1,
      # HDMI-A-1) — add a wildcard so *some* sane config applies
      # regardless of what this machine's actual output is named
      # (VirtualBox's virtual display almost certainly isn't either of
      # those names). Inserted only if not already present, so this
      # stays safe to re-run.
      if ! grep -q 'output = ""' "$HYPR_CONF"; then
        sed -i '/hl.monitor({ output = "eDP-1"/i hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })' "$HYPR_CONF"
      fi
    fi

    RULES_CONF="$HOME/.config/hypr/rules.lua"
    if [ -f "$RULES_CONF" ]; then
      # Cosmetic only — the opacity window-rule regex still lists
      # thunar/brave-browser by class name, so it'd silently never match
      # Dolphin/Firefox. Not broken without this, just inconsistent.
      sed -i 's/thunar|brave-browser/dolphin|firefox/' "$RULES_CONF"
    fi

    # hyprpaper's own config — points at a real wallpaper that actually
    # exists on this machine now that Wallpapers/ has been copied in,
    # rather than the upstream config's hardcoded author-specific path.
    FIRST_WALLPAPER="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" \) 2>/dev/null | sort | head -1)"
    if [ -n "$FIRST_WALLPAPER" ]; then
      mkdir -p "$HOME/.config/hypr"
      cat > "$HOME/.config/hypr/hyprpaper.conf" << EOF
preload = $FIRST_WALLPAPER
wallpaper = ,$FIRST_WALLPAPER
splash = false
EOF
      echo "    wrote hyprpaper.conf pointing at $FIRST_WALLPAPER"
    else
      echo "!! No wallpaper found in $HOME/Pictures/Wallpapers — hyprpaper.conf not created, add one manually"
    fi

    # Matches what the dotfiles' own (Arch-specific) install.sh does —
    # scripts need to actually be executable to run from exec-once/binds.
    if [ -d "$HOME/.config/hypr/scripts" ]; then
      find "$HOME/.config/hypr/scripts" -type f -exec chmod +x {} \;
    fi
    if [ -d "$HOME/.config/waybar/scripts" ]; then
      find "$HOME/.config/waybar/scripts" -type f -exec chmod +x {} \;
    fi
  fi
fi

echo
echo "Still manual (not scriptable, need interactive input):"
echo "  - sudo tailscale up --ssh        # one-time tailnet login"
echo "  - passwd                          # replace the initial placeholder password"
echo "  - sudo smbpasswd -a $USERNAME     # only if you're using the Samba share"