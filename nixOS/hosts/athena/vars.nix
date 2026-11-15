{
  hostname = "athena";
  username = "enexolgort";
  gitEmail = "enexolgort@athena.local";
  targetType = "real";
  bootloader = "systemd-boot";

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true;
  sftpEnable = false;
  n8nEnable = true;
  homepageEnable = false;
  dockhandEnable = false;
  desktopEnable = false;
  nvidiaEnable = false;
  gamingEnable = false;

  # AMD BC-250 (gfx1013): ROCm doesn't support it, Mesa's RADV Vulkan does.
  aiBackend = "vulkan";
  # Pulled on rebuild.
  aiModels = [ "qwen2.5:0.5b" ];

  backupEnable = false;

  projectRepos = [ ];
}
