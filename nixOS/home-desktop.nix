# home-desktop.nix — home-manager level config specific to desktop
# hosts (currently janus). Imported conditionally by flake.nix
# based on that host's desktopEnable — never applied to the headless
# server hosts.
{ config, pkgs, lib, vars, ... }:

{
  # Cursor: Posy's Improved Cursors (simtrami/posy-improved-cursor-linux).
  # Installs the theme and sets it as the default for GTK, X11/XWayland
  # and ~/.icons/default; Hyprland picks it up via XCURSOR_THEME in
  # dotfiles/hypr/hyprland.lua. Ships only in 32/48/64/96/128 px, so the
  # size must be one of those or the cursor gets scaled and blurry.
  # Other variants in the same package: Posy_Cursor_Black,
  # Posy_Cursor_Mono, Posy_Cursor_Mono_Black, Posy_Cursor_Strokeless.
  home.pointerCursor = {
    name = "Posy_Cursor";
    package = pkgs.posy-cursors;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

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
