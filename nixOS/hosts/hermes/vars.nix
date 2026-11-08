{
  hostname = "hermes";
  username = "enexolgort";
  gitEmail = "enexolgort@hermes.local";
  targetType = "wsl";

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false; # Forgejo moved to mnemosyne
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  homepageEnable = false;
  desktopEnable = false;
  ytdlpEnable = true; # yt-dlp CLI — used by the yt-dlp-API project

  backupEnable = false;

  projectRepos = [
    "https://github.com/enexolgort/transmission-API"
    "https://github.com/enexolgort/yt-dlp-API"
  ];
}
