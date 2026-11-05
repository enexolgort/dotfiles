# hardware-configuration.nix for janus-vm (VirtualBox guest).
#
# Unlike the other hosts, this one is committed for real rather than as
# a placeholder: the VM is installed with a fixed layout, and filesystems
# are referenced by label instead of UUID, so it works on any fresh VM
# partitioned the same way:
#
#   /dev/sda1  ext4  label "nixos"  -> /
#   /dev/sda2  swap  label "swap"
#   (MBR partition table, BIOS boot — see bootloader in vars.nix)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # VirtualBox Guest Additions: clipboard, display resizing, shared
  # folders, time sync.
  virtualisation.virtualbox.guest.enable = true;
}
