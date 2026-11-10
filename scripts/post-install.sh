#!/usr/bin/env bash
# Run after `nixos-rebuild switch`: steps NixOS can't do declaratively.

set -euo pipefail

# Writes into $HOME; as root, every config would land in /root.
if [ "$(id -u)" -eq 0 ]; then
  echo "!! Don't run post-install.sh as root — it deploys configs into \$HOME ($HOME)." >&2
  echo "   Run it as your normal user; it uses sudo where needed:" >&2
  echo "     cd ~/dotFiles && ./scripts/post-install.sh" >&2
  exit 1
fi

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

# --- Doom Emacs: deploy dotfiles/doom, then sync.
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

# --- herdr-core (every host): lets herdr on another device add this one
# as a machine. Static binary, so it needs no nix-ld.
HC_INSTALL="curl -fsSL https://releases.herdr.dev/core/install.sh | sh"
if [ -e "$HOME/.local/bin/herdr-core" ]; then
  echo "==> herdr-core already installed, update it with: hc update"
else
  echo "==> Installing herdr-core: $HC_INSTALL"
  sh -c "$HC_INSTALL" || echo "!! herdr-core install failed - rerun: $HC_INSTALL"
fi
echo

# --- herdr desktop app (herdrEnable hosts): upstream installer, which puts
# herdr-app and herdr-core (hc) under ~/.local. Re-run it to update.
HERDR_ENABLE="false"
if [ -f "$VARS_FILE" ]; then
  HERDR_ENABLE="$(nix --extra-experimental-features 'nix-command' eval --file "$VARS_FILE" herdrEnable 2>/dev/null || echo "false")"
fi

HERDR_INSTALL="curl -fsSL https://releases.herdr.dev/app/install.sh | sh"
if [ "$HERDR_ENABLE" = "true" ]; then
  if [ -e "$HOME/.local/bin/herdr-app" ]; then
    echo "==> herdr app already installed, update it with: $HERDR_INSTALL"
  else
    echo "==> Installing the herdr app: $HERDR_INSTALL"
    sh -c "$HERDR_INSTALL" || echo "!! herdr install failed - rerun: $HERDR_INSTALL"
  fi
  echo
fi

# --- Desktop configs (desktop hosts only). Idempotent.
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
      # Deployed above.
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

    # --- Replace leftovers from the upstream dotfiles (43PR/dotfiles).
    grep -rl "/home/rp34" "$HOME/.config/hypr" "$HOME/.config/waybar" 2>/dev/null | while read -r f; do
      sed -i "s|/home/rp34|$HOME|g" "$f"
    done

    HYPR_CONF_FILE="$HOME/.config/hypr/hyprland.lua"
    if [ -f "$HYPR_CONF_FILE" ]; then
      sed -i 's/fileManager = "thunar"/fileManager = "dolphin"/' "$HYPR_CONF_FILE"
      sed -i 's/browser    = "brave"/browser    = "firefox"/' "$HYPR_CONF_FILE"
      sed -i 's/hl.exec_cmd("dunst")/hl.exec_cmd("mako")/' "$HYPR_CONF_FILE"
      # Arch-only polkit path.
      sed -i '/polkit-kde-authentication-agent/d' "$HYPR_CONF_FILE"
      # awww -> hyprpaper (configured via hyprpaper.conf below).
      sed -i 's/hl.exec_cmd("awww-daemon")/hl.exec_cmd("hyprpaper")/' "$HYPR_CONF_FILE"
      sed -i '/awww img/d' "$HYPR_CONF_FILE"
      sed -i 's/kb_layout = "us,latam"/kb_layout = "fr"/' "$HYPR_CONF_FILE"
    fi

    RULES_CONF_FILE="$HOME/.config/hypr/rules.lua"
    if [ -f "$RULES_CONF_FILE" ]; then
      sed -i 's/thunar|brave-browser/dolphin|firefox/' "$RULES_CONF_FILE"
    fi

    # --- Wallpaper. Override with WALLPAPER=pine.jpg; falls back to the
    # first image. hyprpaper >= 0.8 syntax; empty monitor = every output.
    WALLPAPER="${WALLPAPER:-flowers-21.png}"
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    if [ -d "$REPO_ROOT/images" ]; then
      mkdir -p "$WALLPAPER_DIR"
      find "$REPO_ROOT/images" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
        -exec cp -u {} "$WALLPAPER_DIR/" \;
      echo "==> Copied wallpapers from $REPO_ROOT/images to $WALLPAPER_DIR"
    fi

    WALLPAPER_PATH="$WALLPAPER_DIR/$WALLPAPER"
    if [ ! -f "$WALLPAPER_PATH" ]; then
      WALLPAPER_PATH="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort | head -1)"
    fi
    if [ -n "$WALLPAPER_PATH" ]; then
      mkdir -p "$HOME/.config/hypr"
      cat > "$HOME/.config/hypr/hyprpaper.conf" << EOF
# Written by scripts/post-install.sh — edit WALLPAPER there, not here.
splash = false

wallpaper {
    monitor =
    path = $WALLPAPER_PATH
    fit_mode = cover
}
EOF
      echo "    wrote hyprpaper.conf pointing at $WALLPAPER_PATH"
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