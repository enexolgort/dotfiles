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

  # 8 cores / 32GB RAM, CPU-only inference — 7B is about the practical
  # ceiling for tolerable response speed on this hardware; going bigger
  # (e.g. 14B) would fit in RAM but get noticeably slower per response.
  aiModels = [ "qwen2.5:7b" ];

  backupEnable = false;

  projectRepos = [ ];
}
