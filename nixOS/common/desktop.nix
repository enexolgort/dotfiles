# common/desktop.nix — Hyprland desktop environment. Off unless a host
# sets desktopEnable = true (currently just headfull).
#
# programs.hyprland.enable already handles polkit, xdg-desktop-portal-
# hyprland, graphics drivers, fonts, dconf, and XWayland automatically —
# confirmed via the official Hyprland-on-NixOS wiki page, not something
# built up manually piece by piece here.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.desktopEnable {
  programs.hyprland.enable = true;

  # SDDM as the login screen — matches the 43PR/dotfiles rice, which
  # references a custom SDDM theme (samaritan-sddm-theme) as an optional
  # add-on. Plain SDDM here; the themed version is a manual follow-up if
  # wanted later, not something auto-applied.
  services.displayManager.sddm.enable = true;

  # Hint Electron apps (Obsidian, Spotify's Electron-based client) to
  # use Wayland natively rather than falling back to XWayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # Core rice components from 43PR/dotfiles
    kitty         # terminal — required for Hyprland's own default config
    rofi          # app launcher (plain package; rofi-wayland exists as
                   # an alternative fork if this has Wayland issues —
                   # untested here, flagging rather than guessing)
    waybar        # status bar
    wlogout       # logout menu
    btop          # already used elsewhere in this repo for servers too
    cava          # audio visualizer
    nwg-look      # GTK theme switcher GUI
    # quickshell  # referenced in the dotfiles' .config, but I couldn't
                   # confirm this package name/availability with
                   # confidence — verify with `nix search nixpkgs
                   # quickshell` on first rebuild before assuming it's
                   # missing entirely, rather than silently dropping it

    # Genuinely useful additions beyond what's in the dotfiles repo
    # itself — standard companions for any real Hyprland setup:
    hyprpaper       # wallpaper daemon (Hyprland-native)
    hyprlock        # lock screen (Hyprland-native)
    mako            # notification daemon — nothing in the dotfiles repo
                     # covers this, but GTK/Electron apps expect
                     # notifications to work
    grim            # screenshot capture
    slurp           # screen region selection (paired with grim)
    wl-clipboard    # clipboard access under Wayland
    cliphist        # clipboard history manager
    pavucontrol     # audio mixer GUI
    brightnessctl   # brightness control
    thunar          # file manager — lightweight, commonly paired with
                     # minimal-WM rices rather than pulling in GNOME's
                     # full nautilus dependency chain
    nerd-fonts.jetbrains-mono  # icon glyphs for waybar/rofi to render correctly

    # Requested apps
    opera
    obsidian
    spotify
    neovim
  ];

  # spicetify (Spotify re-theming, present in the dotfiles' .config) is
  # deliberately NOT wired up here — it patches the actual Spotify
  # installation's files, which is awkward under NixOS's read-only
  # /nix/store without the community spicetify-nix flake specifically
  # built to handle that. Worth adding as a real follow-up if wanted,
  # not something to fake here.
}
