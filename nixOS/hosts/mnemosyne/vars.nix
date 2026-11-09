{
  hostname = "mnemosyne";
  username = "enexolgort";
  gitEmail = "enexolgort@mnemosyne.local";
  targetType = "real";
  bootloader = "systemd-boot";

  jellyfinEnable = true;
  obsidianEnable = false;
  gitServerEnable = true;
  aiEnable = false;
  sftpEnable = true;
  n8nEnable = false;
  homepageEnable = true;
  desktopEnable = false;

  sftpDir = "/data/sftp";
  sftpPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfCPT1zuWITFVKSAOmkLAr4wpXkHLDxzNUVptgI88lf sftp-laptop" # filezila@laptop
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITDNIuGEqX2bs89Tv+BWZcFCI3CLOM9xQCj89G/eumc transmission-api push" # transmission-API@hermes
  ];

  gitAdminUser = "gituser"; # "admin" is reserved in Forgejo
  gitAdminPass = "changeme-git"; # CHANGE THIS
  # On the media drive, so it's covered by the mediaDir backup.
  gitDataDir = "/data/media/forgejo";

  extraMounts = [
   {
      device = "/dev/disk/by-uuid/354d0fc5-b1fd-482d-bc7b-2261324f590d"; # media drive (dwsdb)
      mountPoint = "/data/media";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    }
    {
      device = "/dev/disk/by-uuid/580634fd-4d57-4d9e-9b25-77a7965f1b93"; # backup drive (sdb)
      mountPoint = "/data/backup";
      fsType = "ext4";
      options = [ "defaults" "nofail" ];
    }
  ];

  # The only host with backups (to the backup drive).
  backupEnable = true;
  backupRepo = "/data/backup/restic-repo";
  backupPassword = "changeme-restic-backup-password"; # CHANGE THIS

  projectRepos = [
    "http://mnemosyne:3000/enexolgort/transmission-webUis"
    "http://mnemosyne:3000/enexolgort/yt-dlp-API"
    "http://mnemosyne:3000/enexolgort/git-dashboard"
  ];
}

