{ config, pkgs, lib, vars, ... }:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-generations +2";
  };
  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    gh
    wget
    htop
    btop
    ncdu
    jq
    tmux
    restic
    ffmpeg
    docker-compose
    nodejs
  ] ++ lib.optionals (vars.ytdlpEnable or false) [
    yt-dlp
  ];

  # Claude Code (claudeEnable) and the herdr desktop app (herdrEnable) come
  # from their upstream installers in scripts/post-install.sh as prebuilt
  # binaries in ~/.local; nix-ld lets them run on NixOS.
  programs.nix-ld.enable = lib.mkIf (vars.claudeEnable || vars.herdrEnable) true;

  # herdr is a GPUI app: X11/Wayland, Vulkan and fonts are linked or dlopened.
  programs.nix-ld.libraries = lib.mkIf vars.herdrEnable (
    with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      libxkbcommon
      xorg.libxcb
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      wayland
      vulkan-loader
      fontconfig
      freetype
    ]
  );
  hardware.graphics.enable = lib.mkIf vars.herdrEnable true;
  fonts.enableDefaultPackages = lib.mkIf vars.herdrEnable true;
}
