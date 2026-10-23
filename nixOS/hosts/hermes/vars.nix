{
  hostname = "hermes";
  username = "enexolgort";
  gitEmail = "enexolgort@hermes.local";
  targetType = "wsl";

  jellyfinEnable = false;
  obsidianEnable = true;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = false;

  # obsidianEnable = true, so these need to actually be here.
  couchdbAdminUser = "admin";
  couchdbAdminPass = "changeme-couchdb"; # CHANGE THIS

  backupEnable = false;

  projectRepos = [
    "https://github.com/enexolgort/transmission-API"
  ];
}
