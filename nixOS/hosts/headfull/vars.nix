{
  hostname = "headfull";
  username = "enexolgort";
  gitEmail = "enexolgort@headfull.local";
  targetType = "real";
  # This VM runs legacy BIOS, not UEFI (confirmed via `parted /dev/sda --
  # print` showing "msdos" partition table) — systemd-boot can't work
  # here at all, GRUB is the one that actually does.
  bootloader = "grub";
  grubDevice = "/dev/sda";

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;

  # New toggle — headfull is a desktop workstation, not a headless
  # server like the other three hosts. See common/desktop.nix and
  # home-desktop.nix.
  desktopEnable = true;

  backupEnable = false;

  projectRepos = [ ];
}
