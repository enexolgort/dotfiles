# Hyprland desktop (desktopEnable). programs.hyprland already brings polkit,
# the Hyprland portal, graphics drivers, fonts, dconf and XWayland.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.desktopEnable {
  programs.hyprland.enable = true;

  # Without this, SDDM's default "Hyprland (uwsm-managed)" session fails
  # instantly (wayland-session-bindpid exit status 5, black screen).
  programs.hyprland.withUWSM = true;

  # The module (not just the package) adds the PAM service hyprlock needs to unlock.
  programs.hyprlock.enable = true;

  # The Catppuccin theme is Qt6, so SDDM must be the Qt6 build. The module
  # asserts xserver or wayland is enabled; there is no X server here.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.package = pkgs.kdePackages.sddm;
  services.displayManager.sddm.theme = "catppuccin-mocha-mauve";

  # The Hyprland portal has no file chooser; use the GTK one.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  programs.obs-studio.enable = true;

  # Without it, CSS-loaded SVGs (power menu icons) silently don't render.
  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];

  # Mount USB drives without root (Dolphin / GTK file dialogs).
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # swayosd's udev rules let the user change the backlight.
  services.udev.packages = [ pkgs.swayosd ];

  # "kde" makes Qt apps read ~/.config/kdeglobals (written by home-desktop.nix).
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  # Electron apps: native Wayland instead of XWayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Autostart is unreliable under Hyprland+SDDM; if the applet is missing,
  # start `nm-applet --indicator` from hyprland.lua instead.
  programs.nm-applet.enable = true;

  # WiFi changes without a polkit prompt; backlight without sudo.
  users.users.${vars.username}.extraGroups = [ "networkmanager" "video" ];

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # programs.hyprland enables polkit but no auth agent; without one, GUI
  # admin actions fail silently. hyprland.lua starts this user unit.
  systemd.packages = [ pkgs.hyprpolkitagent ];

  services.upower.enable = true;

  # Known issue (NixOS/nixpkgs#409986): Dolphin's "Open with" suggestions
  # are empty outside Plasma.

  security.rtkit.enable = true;
  services.pulseaudio.enable = false; # conflicts with PipeWire's pulse emulation
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  environment.systemPackages = with pkgs; [
    kitty
    rofi
    waybar
    wlogout
    btop
    cava
    nwg-look

    hyprpaper
    swaybg          # fallback when hyprpaper can't start (janus-vm), see hypr/scripts/wallpaper.sh
    hypridle
    hyprpolkitagent
    mako
    libnotify
    grim
    slurp
    wl-clipboard
    cliphist
    pavucontrol
    networkmanagerapplet
    brightnessctl
    swayosd
    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font = "JetBrainsMono Nerd Font";
      fontSize = "11";
    })
    playerctl
    kdePackages.dolphin
    kdePackages.breeze-icons
    kdePackages.kio          # no longer pulled in by Dolphin since nixos-25.11
    kdePackages.kio-fuse
    kdePackages.kio-extras   # sftp:// etc. in Dolphin
    nerd-fonts.jetbrains-mono
    font-awesome

    firefox
    obsidian
    spotify
    neovim
    kdePackages.gwenview
    mpv
    gsimplecal
    hoppscotch
    filezilla
    blender
    discord
  ];
}
