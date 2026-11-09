# restic (backupEnable), see doc/backups.md.
{ config, pkgs, lib, vars, ... }:

{
  services.restic.backups.mediaserver = lib.mkIf vars.backupEnable {
    initialize = true;
    repository = vars.backupRepo;
    passwordFile =
      if vars.secretsEnabled
      then config.sops.secrets.backupPassword.path
      else "/etc/restic-backup-password";
    paths = [
      vars.mediaDir
      "/home/${vars.username}/dotFiles"
      vars.projectsDir
    ]
    ++ lib.optional vars.obsidianEnable "/var/lib/couchdb"
    ++ lib.optional vars.jellyfinEnable "/var/lib/jellyfin"
    # Skipped when it already lives inside mediaDir.
    ++ lib.optional (vars.gitServerEnable && !lib.hasPrefix "${vars.mediaDir}/" vars.gitDataDir) vars.gitDataDir;
    exclude = lib.optionals vars.jellyfinEnable [
      # Regenerable and large.
      "/var/lib/jellyfin/cache"
      "/var/lib/jellyfin/metadata"
      "/var/lib/jellyfin/transcodes"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
  };

  # Plaintext fallback until sops-nix is set up.
  environment.etc."restic-backup-password" = lib.mkIf (vars.backupEnable && !vars.secretsEnabled) {
    text = vars.backupPassword;
    mode = "0400";
  };
}
