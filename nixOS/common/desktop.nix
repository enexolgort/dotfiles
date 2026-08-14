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

  # SDDM as the login screen. A themed version is a manual follow-up if
  # wanted later, not something auto-applied.
  #
  # wayland.enable is required explicitly — SDDM's NixOS module asserts
  # that either services.xserver.enable or this must be true. Since
  # Hyprland is pure Wayland (no X server at all), this is the one that
  # applies.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Hint Electron apps (Obsidian, Spotify's Electron-based client) to
  # use Wayland natively rather than falling back to XWayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # NetworkManager itself is already enabled in configuration.nix — this
  # is just the graphical tray applet on top of it, for connecting to
  # WiFi without the command line.
  #
  # KNOWN RELIABILITY CAVEAT: a NixOS Discourse thread reports this
  # module's systemd-user-service autostart specifically not reliably
  # working under Hyprland+SDDM (this exact combo), despite being
  # designed to. If the applet doesn't appear after rebooting, the
  # documented workaround is adding `exec-once = nm-applet --indicator`
  # directly to your hyprland.conf rather than relying on this module's
  # own autostart.
  programs.nm-applet.enable = true;

  # Dolphin (KDE's file manager) rather than Thunar, per request.
  # kdePackages.kio/-fuse/-extras are the wiki-documented required
  # companions (kio itself became required separately starting in
  # nixos-25.11, not bundled automatically) — without them Dolphin runs
  # but loses basic functionality (remote/SFTP browsing, etc.).
  #
  # HONEST CAVEAT, confirmed via an open nixpkgs issue (NixOS/nixpkgs
  # #409986): Dolphin's "open with" file-association suggestions are
  # known not to work correctly on non-Plasma window managers —
  # Hyprland included. It'll browse/launch files fine; app suggestions
  # specifically may not appear. A workaround exists (pointing
  # environment.etc."xdg/menus/applications.menu" at Plasma's own menu
  # file) but isn't applied here — flagging rather than silently
  # papering over a real limitation.

  environment.systemPackages = with pkgs; [
    # Core Hyprland ecosystem components
    kitty         # terminal — required for Hyprland's own default config
    rofi          # app launcher (plain package; rofi-wayland exists as
                   # an alternative fork if this has Wayland issues —
                   # untested here, flagging rather than guessing)
    waybar        # status bar
    wlogout       # logout menu
    btop          # already used elsewhere in this repo for servers too
    cava          # audio visualizer
    nwg-look      # GTK theme switcher GUI

    # Standard companions for any real Hyprland setup:
    hyprpaper       # wallpaper daemon (Hyprland-native)
    hyprlock        # lock screen (Hyprland-native)
    mako            # notification daemon — GTK/Electron apps expect
                     # notifications to work
    grim            # screenshot capture
    slurp           # screen region selection (paired with grim)
    wl-clipboard    # clipboard access under Wayland
    cliphist        # clipboard history manager
    pavucontrol     # audio mixer GUI
    brightnessctl   # brightness control
    kdePackages.dolphin      # file manager
    kdePackages.kio          # required separately since nixos-25.11
    kdePackages.kio-fuse     # mount remote filesystems via FUSE
    kdePackages.kio-extras   # protocol support: sftp, fish, etc.
    nerd-fonts.jetbrains-mono  # icon glyphs for waybar/rofi to render correctly

    # Requested apps
    firefox
    obsidian
    spotify
    neovim
  ];
}
