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
  usbipAutoAttach = ["2-1"]; # T-Beam Supreme (303a:1001)

  backupEnable = false;

  projectRepos = [];
}
