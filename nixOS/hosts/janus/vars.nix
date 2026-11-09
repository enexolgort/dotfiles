{
  hostname = "janus";
  username = "enexolgort";
  gitEmail = "enexolgort@janus.local";
  targetType = "real";
  bootloader = "systemd-boot";

  # Desktop client: no services of its own.
  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  homepageEnable = false;
  desktopEnable = true;

  backupEnable = false;

  projectRepos = [ ];
}
