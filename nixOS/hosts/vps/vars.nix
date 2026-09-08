{
  hostname = "vps";
  username = "enexolgort";
  gitEmail = "enexolgort@vps.local";
  targetType = "real";
  # systemd-boot failed on this VPS ("efiSysMountPoint = '/boot' is not a
  # mounted partition") because it boots BIOS/legacy, not UEFI — confirmed
  # via `sudo parted /dev/sda -- print` showing an msdos partition table.
  bootloader = "grub";
  grubDevice = "/dev/sda"; # whole disk device, not a partition

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true; # Ollama + Open WebUI — see common/ai.nix, cloned from scrapy
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = false;

  # 8 cores / 32GB RAM, CPU-only inference — 7B is about the practical
  # ceiling for tolerable response speed on this hardware; going bigger
  # (e.g. 14B) would fit in RAM but get noticeably slower per response.
  aiModels = [ "qwen2.5:7b" ];

  backupEnable = false;

  projectRepos = [ ];
}
