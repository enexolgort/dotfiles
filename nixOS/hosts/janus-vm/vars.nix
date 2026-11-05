{
  hostname = "janus-vm";
  username = "enexolgort";
  gitEmail = "enexolgort@janus-vm.local";
  targetType = "real";

  # VirtualBox VM: legacy BIOS boot, so GRUB on the whole disk —
  # systemd-boot is UEFI-only.
  bootloader = "grub";
  grubDevice = "/dev/sda";

  # janus-vm is a VirtualBox test copy of janus (the Hyprland desktop
  # client) — keep the toggles below in sync with hosts/janus/vars.nix.
  # Needs 3D acceleration enabled in the VM Display settings (apps then
  # render in software, see hardware-configuration.nix).
  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  homepageEnable = false;
  monitoringHubEnable = false;
  desktopEnable = true;

  backupEnable = false;

  projectRepos = [ ];
}
