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
  claudeEnable = true;

  # Pulled on rebuild. Kept small: inference is CPU-only.
  aiModels = [ "qwen2.5:0.5b" ];

  backupEnable = false;

  projectRepos = [ ];
}
