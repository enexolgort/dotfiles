{
  hostname = "hermes";
  username = "enexolgort";
  gitEmail = "enexolgort@hermes.local";
  targetType = "wsl";

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
  ytdlpEnable = true; # used by yt-dlp-API

  backupEnable = false;

  projectRepos = [
    "http://mnemosyne:3000/enexolgort/transmission-API"
    "http://mnemosyne:3000/enexolgort/yt-dlp-API"
  ];
}
