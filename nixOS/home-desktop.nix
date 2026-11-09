# home-manager config for desktopEnable hosts.
{ config, pkgs, lib, vars, ... }:

{
  home.packages = [ pkgs.curl ]; # waybar fleet-status.sh

  # Only ships in 32/48/64/96/128 px; other sizes get blurry.
  home.pointerCursor = {
    name = "Posy_Cursor";
    package = pkgs.posy-cursors;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  # Catppuccin Mocha for Qt/KDE apps. Outside Plasma, KDE apps read colours
  # only from these [Colors:*] groups.
  xdg.configFile."kdeglobals".text =
    let
      base = "30,30,46";
      mantle = "24,24,37";
      crust = "17,17,27";
      surface0 = "49,50,68";
      surface1 = "69,71,90";
      overlay0 = "108,112,134";
      subtext0 = "166,173,200";
      text = "205,214,244";
      mauve = "203,166,247";
      lavender = "180,190,254";
      blue = "137,180,250";
      red = "243,139,168";
      yellow = "249,226,175";
      green = "166,227,161";
      group = name: bg: alt: fg: ''
        [Colors:${name}]
        BackgroundNormal=${bg}
        BackgroundAlternate=${alt}
        ForegroundNormal=${fg}
        ForegroundInactive=${subtext0}
        ForegroundActive=${mauve}
        ForegroundLink=${blue}
        ForegroundVisited=${lavender}
        ForegroundNegative=${red}
        ForegroundNeutral=${yellow}
        ForegroundPositive=${green}
        DecorationFocus=${mauve}
        DecorationHover=${lavender}
      '';
    in
    ''
      [General]
      ColorScheme=CatppuccinMochaMauve
      AccentColor=${mauve}
      TerminalApplication=kitty
      TerminalService=kitty.desktop

      [Icons]
      Theme=breeze-dark

      [KDE]
      contrast=4
    ''
    + group "Window" base mantle text
    + group "View" base mantle text
    + group "Button" surface0 surface1 text
    + group "Header" mantle crust text
    + group "Tooltip" mantle crust text
    + group "Complementary" crust mantle text
    + group "Selection" mauve lavender crust
    + ''
      [WM]
      activeBackground=${mantle}
      activeForeground=${text}
      inactiveBackground=${crust}
      inactiveForeground=${overlay0}
    '';

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
        accents = [ "mauve" ];
      };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "mauve";
      };
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    # home-manager warns until this is set explicitly.
    gtk4.theme = config.gtk.theme;
  };
  # libadwaita/GTK4 apps ignore GTK themes but follow this dark preference.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  # force: apps rewrite mimeapps.list, which would otherwise break activation.
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        browser = "firefox.desktop";
        images = "org.kde.gwenview.desktop";
        media = "mpv.desktop";
      in
      {
        "inode/directory" = "org.kde.dolphin.desktop";
        "text/html" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
        "application/pdf" = browser;
        "text/plain" = "nvim.desktop";
        "image/png" = images;
        "image/jpeg" = images;
        "image/gif" = images;
        "image/webp" = images;
        "image/svg+xml" = images;
        "video/mp4" = media;
        "video/webm" = media;
        "video/x-matroska" = media;
        "audio/mpeg" = media;
        "audio/flac" = media;
        "audio/ogg" = media;
      };
  };
  xdg.configFile."mimeapps.list".force = true;

  # Never overwrites an existing ~/.config/nvim.
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
