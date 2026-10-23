{
  hostname = "hermes";
  username = "enexolgort";
  gitEmail = "enexolgort@hermes.local";
  targetType = "wsl";

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = true; # Forgejo — see common/forgejo.nix
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = false;

  # gitServerEnable = true, so these need to actually be here.
  # NOTE: "admin" itself is a reserved username in Forgejo.
  gitAdminUser = "gituser";
  gitAdminPass = "changeme-git"; # CHANGE THIS

  backupEnable = false;

  projectRepos = [
    "https://github.com/enexolgort/transmission-API"
  ];
}
