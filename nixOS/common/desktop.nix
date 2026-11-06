# common/desktop.nix — Hyprland desktop environment. Off unless a host
# sets desktopEnable = true (currently only janus).
#
# programs.hyprland.enable already handles polkit, xdg-desktop-portal-
# hyprland, graphics drivers, fonts, dconf, and XWayland automatically —
# confirmed via the official Hyprland-on-NixOS wiki page, not something
# built up manually piece by piece here.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.desktopEnable {
  programs.hyprland.enable = true;

  # Run Hyprland under uwsm (the "Hyprland (uwsm-managed)" session SDDM
  # offers first). Without this the session entry still exists but uwsm's
  # systemd user units aren't installed, so logging in fails instantly
  # with "wayland-session-bindpid@….service returned exit status 5" and
  # drops to a black screen.
  programs.hyprland.withUWSM = true;

  # Lock screen. The NixOS module (not just the package) is what adds
  # the `hyprlock` PAM service — without it hyprlock can lock the screen
  # but can't verify your password to unlock it. Its config is
  # dotfiles/hypr/hyprlock.conf (Catppuccin Mocha), deployed to
  # ~/.config/hypr by scripts/post-install.sh.
  programs.hyprlock.enable = true;

  # SDDM as the login screen. A themed version is a manual follow-up if
  # wanted later, not something auto-applied.
  #
  # wayland.enable is required explicitly — SDDM's NixOS module asserts
  # that either services.xserver.enable or this must be true. Since
  # Hyprland is pure Wayland (no X server at all), this is the one that
  # applies.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  # Qt/KDE apps (Dolphin) outside Plasma: the "kde" platform theme
  # (plasma-integration) makes them read colours/icons from
  # ~/.config/kdeglobals, which home-desktop.nix fills with Catppuccin
  # Mocha. Breeze is the widget style; breeze-icons provides the dark
  # icon set kdeglobals selects.
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

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

  # networkmanager group = connect/forget WiFi networks (nm-applet,
  # nmcli, the rofi wifi menu) without a polkit password prompt each
  # time. video = brightnessctl on the backlight without sudo.
  users.users.${vars.username}.extraGroups = [ "networkmanager" "video" ];

  # Bluetooth — BlueZ plus blueman's tray applet/manager GUI (rules.lua
  # already floats blueman-manager). powerOnBoot so headphones reconnect
  # without opening the manager first.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # programs.hyprland turns polkit itself on, but NOT an authentication
  # agent — without one, anything asking for admin rights from the GUI
  # (mounting a drive in Dolphin, NetworkManager system connections)
  # just fails silently. hyprpolkitagent is the Hyprland-native one;
  # systemd.packages makes its user unit available so hyprland.lua can
  # `systemctl --user start` it.
  systemd.packages = [ pkgs.hyprpolkitagent ];

  # Battery/power info for waybar's battery module and for apps that ask
  # over D-Bus. Harmless on a desktop with no battery.
  services.upower.enable = true;

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

  # Audio — PipeWire is what the actual dotfiles (packages.txt) expect
  # (pipewire, pipewire-pulse, wireplumber), and this was a genuine gap:
  # nothing configured audio at all before this. rtkit is required for
  # PipeWire's realtime scheduling.
  security.rtkit.enable = true;
  services.pulseaudio.enable = false; # must be off — conflicts with PipeWire's own pulse emulation
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Wallpaper daemon: hyprpaper (Hyprland-native, already confirmed
  # available in mainstream nixpkgs). Its actual config
  # (~/.config/hypr/hyprpaper.conf) is part of your own tracked hypr/
  # folder, copied in by scripts/post-install.sh — not written here.

  environment.systemPackages = with pkgs; [
    # Core Hyprland ecosystem components
    kitty         # terminal — required for Hyprland's own default config
    rofi          # app launcher + dmenu (`rofi -dmenu`) for the clipboard,
                   # opacity and wifi pickers. Native Wayland since rofi
                   # 2.0 — the separate rofi-wayland fork was merged back
                   # into this package (rofi-wayland is just an alias now).
    waybar        # status bar
    wlogout       # logout menu
    btop          # already used elsewhere in this repo for servers too
    cava          # audio visualizer
    nwg-look      # GTK theme switcher GUI

    # Standard companions for any real Hyprland setup:
    hyprpaper       # wallpaper daemon (Hyprland-native)
    swaybg          # CPU-only wallpaper fallback when hyprpaper can't start
                     # (janus-vm) — see dotfiles/hypr/scripts/wallpaper.sh
    hypridle        # idle daemon — dims, locks, then sleeps the screen
                     # (config in dotfiles/hypr/hypridle.conf)
    hyprpolkitagent # polkit auth prompts, see systemd.packages above
    mako            # notification daemon — GTK/Electron apps expect
                     # notifications to work
    libnotify       # notify-send, used by hypr/scripts/wifi-menu.sh
    grim            # screenshot capture
    slurp           # screen region selection (paired with grim)
    wl-clipboard    # clipboard access under Wayland
    cliphist        # clipboard history manager
    pavucontrol     # audio mixer GUI (waybar volume click / Super+A)
    networkmanagerapplet # nm-connection-editor, for the advanced WiFi /
                          # VPN settings nm-applet's menu links to
    brightnessctl   # brightness control
    playerctl       # media key controls (play/pause/next/prev) — used in keybinds.lua
    kdePackages.dolphin      # file manager
    kdePackages.breeze-icons # breeze-dark icons for Dolphin (kdeglobals [Icons])
    kdePackages.kio          # required separately since nixos-25.11
    kdePackages.kio-fuse     # mount remote filesystems via FUSE
    kdePackages.kio-extras   # protocol support: sftp, fish, etc.
    nerd-fonts.jetbrains-mono  # icon glyphs for waybar/rofi to render correctly
    font-awesome               # additional icon set the dotfiles' packages.txt expects

    # Requested apps
    firefox
    obsidian
    spotify
    neovim
    claude-code     # Claude Code CLI (`claude`; unfree, allowed in base.nix) — Super+C opens it in kitty
  ];
}
