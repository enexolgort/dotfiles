{
  hostname = "headfull";
  username = "enexolgort";
  gitEmail = "enexolgort@headfull.local";
  targetType = "real";

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
  cdEnable = false;

  backupEnable = false;

  projectRepos = [ ];
}
