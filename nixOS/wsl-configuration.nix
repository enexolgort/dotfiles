# Base for targetType = "wsl". Needs a NixOS-WSL distro, not Nix on
# Ubuntu-WSL (see doc/deploy-wsl.md).
{ config, pkgs, lib, vars, nixos-wsl, ... }:

{
  imports = [
    nixos-wsl.nixosModules.wsl
    ./common
  ];

  wsl = {
    enable = true;
    defaultUser = vars.username;
    startMenuLaunchers = true;
  };
}
