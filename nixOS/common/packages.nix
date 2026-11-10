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
  ];

  # herdr comes from its upstream installer (scripts/post-install.sh) as a
  # prebuilt binary in ~/.local/bin; nix-ld lets it run on NixOS.
  programs.nix-ld.enable = lib.mkIf vars.herdrEnable true;
}
