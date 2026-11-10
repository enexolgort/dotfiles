{ config, pkgs, pkgsUnstable, lib, vars, ... }:

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
  ] ++ lib.optionals vars.herdrEnable [
    pkgsUnstable.herdr # not in nixos-26.05
  ];
}
