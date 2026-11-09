{ config, pkgs, lib, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
  };

  systemd.services.docker = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
