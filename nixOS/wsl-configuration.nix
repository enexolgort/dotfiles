# Base for targetType = "wsl". Needs a NixOS-WSL distro, not Nix on
# Ubuntu-WSL (see doc/deploy-wsl.md).
{
  config,
  pkgs,
  lib,
  vars,
  nixos-wsl,
  ...
}: {
  imports = [
    nixos-wsl.nixosModules.wsl
    ./common
  ];

  wsl = {
    enable = true;
    defaultUser = vars.username;
    startMenuLaunchers = true;
    # GPU-accelerated Vulkan through WSLg, for the herdr desktop app.
    useWindowsDriver = vars.herdrEnable;
    # USB devices from Windows, by usbipd bus ID; needs usbipd-win on Windows.
    usbip = lib.mkIf (vars.usbipAutoAttach != []) {
      enable = true;
      autoAttach = vars.usbipAutoAttach;
    };
  };

  # Serial devices (/dev/ttyUSB*, /dev/ttyACM*) are group dialout.
  users.users.${vars.username}.extraGroups = lib.mkIf (vars.usbipAutoAttach != []) ["dialout"];
}
