# common/docker.nix
{ config, pkgs, lib, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29; # pinned explicitly — already the default since nixos-26.05 (docker_28 removed)
  };

  systemd.services.docker = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
