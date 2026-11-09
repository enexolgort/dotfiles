{ config, pkgs, lib, vars, ... }:

{
  services.jellyfin = {
    enable = vars.jellyfinEnable;
    openFirewall = false;
  };

  systemd.services.jellyfin = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
