{
  hostname = "janus-vm";
  username = "enexolgort";
  gitEmail = "enexolgort@janus-vm.local";
  targetType = "real";

  # Legacy BIOS VM.
  bootloader = "grub";
  grubDevice = "/dev/sda";

  # Test copy of janus: keep toggles in sync with hosts/janus/vars.nix.
  # Needs 3D acceleration on in VirtualBox's Display settings.
  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  homepageEnable = false;
  desktopEnable = true;
  nvidiaEnable = false;
  gamingEnable = false;
  herdrEnable = true;
  claudeEnable = true;

  backupEnable = false;

  projectRepos = [ ];
}
