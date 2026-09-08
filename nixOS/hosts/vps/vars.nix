{
  hostname = "vps";
  username = "enexolgort";
  gitEmail = "enexolgort@vps.local";
  targetType = "real";
  bootloader = "systemd-boot"; # most VPS providers are UEFI now — switch to
    # "grub" + set grubDevice below if `sudo parted /dev/sda -- print` on
    # the actual VPS shows an msdos (BIOS) partition table instead of gpt

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true; # Ollama + Open WebUI — see common/ai.nix, cloned from scrapy
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = false;

  # Smallest usable model — bump this once you know the VPS's actual CPU/RAM
  # (or GPU) budget. Cloned from scrapy's conservative default.
  aiModels = [ "qwen2.5:0.5b" ];

  backupEnable = false;

  projectRepos = [ ];
}
