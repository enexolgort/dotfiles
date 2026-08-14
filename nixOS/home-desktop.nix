# home-desktop.nix — home-manager level config specific to desktop
# hosts (currently just headfull). Imported conditionally by flake.nix
# based on that host's desktopEnable — never applied to the headless
# server hosts.
#
# NOTE: 43PR/dotfiles cloning+copying used to live here as a home.activation
# script, but moved to scripts/post-install.sh instead — a manually-
# triggered step is more predictable than relying on home-manager's
# activation-script timing, which only runs again when the system
# generation actually changes (a real gap we hit: a no-op rebuild
# silently skipped re-running it entirely, with zero error shown).
{ config, pkgs, lib, vars, ... }:

{
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
