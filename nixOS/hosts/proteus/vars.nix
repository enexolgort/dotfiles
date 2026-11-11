{
  hostname = "proteus";
  username = "enexolgort";
  gitEmail = "enexolgort@proteus.local";
  targetType = "wsl";

  # Second main laptop (NixOS-WSL): a dev client, no services of its own.
  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  homepageEnable = false;
  dockhandEnable = false;
  desktopEnable = false;
  nvidiaEnable = false;
  gamingEnable = false;
  herdrEnable = true;
  claudeEnable = true;

  backupEnable = false;

  projectRepos = [];
}
