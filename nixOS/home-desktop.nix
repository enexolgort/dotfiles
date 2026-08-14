# home-desktop.nix — home-manager level config specific to desktop
# hosts (currently just headfull). Imported conditionally by flake.nix
# based on that host's desktopEnable — never applied to the headless
# server hosts.
{ config, pkgs, lib, vars, ... }:

{
  # 43PR/dotfiles — clones fresh if missing, then copies its .config/*
  # subdirectories into the real ~/.config/. Deliberately NOT copying
  # the whole repo (it also contains README.md and several large
  # screenshot PNGs at the root that aren't actual config, just
  # documentation images).
  home.activation.install43PRDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DOTFILES_CACHE="$HOME/.cache/43pr-dotfiles"

    if [ ! -d "$DOTFILES_CACHE" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/43PR/dotfiles "$DOTFILES_CACHE" \
        || echo "43PR/dotfiles clone failed — run it manually as the ${vars.username} user"
    fi

    if [ -d "$DOTFILES_CACHE/.config" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config"
      for dir in "$DOTFILES_CACHE"/.config/*/; do
        name="$(basename "$dir")"
        # Skip neofetch specifically — it's already managed separately
        # by home.nix's own xdg.configFile declaration (a home-manager-
        # managed read-only symlink into the Nix store), which this
        # blind copy can't write over and would crash on otherwise.
        if [ "$name" = "neofetch" ]; then
          continue
        fi
        $DRY_RUN_CMD cp -rT "$dir" "$HOME/.config/$name"
      done
    fi
  '';

  # LazyVim — official starter template, cloned fresh only if
  # ~/.config/nvim doesn't already exist (never overwrites an existing
  # config, same caution as the Doom Emacs bootstrap above).
  home.activation.installLazyVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_CONF="$HOME/.config/nvim"

    if [ ! -d "$NVIM_CONF" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/LazyVim/starter "$NVIM_CONF" \
        || echo "LazyVim starter clone failed — run it manually as the ${vars.username} user"
      $DRY_RUN_CMD rm -rf "$NVIM_CONF/.git"
    fi
  '';
}
