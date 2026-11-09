# Base for targetType = "real" (bare metal or VM).
{ config, pkgs, lib, vars, ... }:

{
  # systemd-boot is UEFI-only; legacy-BIOS machines/VMs need grub.
  boot.loader.systemd-boot.enable = lib.mkIf (vars.bootloader == "systemd-boot") true;
  boot.loader.systemd-boot.configurationLimit = lib.mkIf (vars.bootloader == "systemd-boot") 10; # small ESP
  boot.loader.efi.canTouchEfiVariables = lib.mkIf (vars.bootloader == "systemd-boot") true;

  boot.loader.grub.enable = lib.mkIf (vars.bootloader == "grub") true;
  boot.loader.grub.device = lib.mkIf (vars.bootloader == "grub") vars.grubDevice; # whole disk, not a partition

  networking.networkmanager.enable = true;

  # LAN Samba share. Not in common/: nmbd crashes under WSL2's NAT.
  # Set the password once: sudo smbpasswd -a <username>
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = vars.sambaWorkgroup;
        "server string" = vars.hostname;
        security = "user";
      };
      media = {
        path = vars.mediaDir;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = vars.username;
        "force group" = "media";
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };

  # vars.extraMounts; "nofail" by default so a missing drive doesn't block boot.
  fileSystems = builtins.listToAttrs (map
    (m: {
      name = m.mountPoint;
      value = {
        device = m.device;
        fsType = m.fsType or "ext4";
        options = m.options or [ "defaults" "nofail" ];
      };
    })
    vars.extraMounts);

  imports = [ ./common ];
}
