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

  # Software OpenGL (Mesa llvmpipe) for the whole session. Under Hyper-V
  # the VMSVGA 3D channel is broken (vmwgfx "Failed to open channel"), so
  # GL apps like kitty crash on wl_surface.attach. Hyprland itself still
  # needs 3D acceleration ENABLED in VirtualBox to start, so: keep 3D on
  # in the VM's Display settings, and render in software here.
  environment.sessionVariables.LIBGL_ALWAYS_SOFTWARE = "1";

  # Lock screen for this VM: hyprlock's GPU path crashes here and wedges
  # VirtualBox's 3D, so hypr/scripts/lock.sh uses swaylock-effects
  # (CPU-drawn, Catppuccin Mocha via dotfiles/swaylock/config) instead.
  # The PAM service is what lets it check your password to unlock.
  environment.systemPackages = [ pkgs.swaylock-effects ];
  security.pam.services.swaylock = { };
}
