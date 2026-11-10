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
  ] ++ lib.optionals vars.claudeEnable [
    claude-code
  ];

  # The herdr desktop app comes from its upstream installer
  # (scripts/post-install.sh) as a prebuilt GPUI binary in ~/.local. nix-ld
  # provides the libraries it links or dlopens: X11/Wayland, Vulkan, fonts.
  programs.nix-ld = lib.mkIf vars.herdrEnable {
    enable = true;
    libraries = with pkgs; [
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
    ];
  };
  hardware.graphics.enable = lib.mkIf vars.herdrEnable true;
  fonts.enableDefaultPackages = lib.mkIf vars.herdrEnable true;
}
