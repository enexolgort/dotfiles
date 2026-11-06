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

  # Catppuccin Mocha (mauve accent) for Qt/KDE apps like Dolphin. Read
  # through the "kde" Qt platform theme set in common/desktop.nix. KDE
  # apps take colours straight from these [Colors:*] groups (outside
  # Plasma nothing copies a .colors scheme in for them), so the palette
  # lives here. Values are Mocha as "R,G,B": https://catppuccin.com/palette
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
