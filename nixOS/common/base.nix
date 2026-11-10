{ config, pkgs, lib, vars, ... }:

{
  networking.hostName = vars.hostname;

  time.timeZone = vars.timeZone;
  i18n.defaultLocale = vars.locale;
  console.keyMap = vars.keyMap;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true; # jellyfin's ffmpeg wants some unfree codecs
  # Exact version strings; update if a rebuild reports a different insecure Emacs.
  nixpkgs.config.permittedInsecurePackages = [
    "emacs-pgtk-with-packages-29.4"
    "emacs-pgtk-29.4"
  ];

  # sops-nix, see doc/secrets.md. Doesn't cover couchdbAdminPass (the
  # module only takes a literal string).
  sops = lib.mkIf vars.secretsEnabled {
    defaultSopsFile = ../secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets = {
      userPasswordHash = {};
      backupPassword = lib.mkIf vars.backupEnable {};
    };
  };

  # Shared group for mediaDir. NixOS doesn't create a per-user group; normal
  # users are in "users".
  users.groups.media = {};

  users.users.${vars.username} = {
    isNormalUser = true;
    description = "Media server admin";
    extraGroups = [ "wheel" "jellyfin" "docker" "media" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
  } // (if vars.secretsEnabled
    then { hashedPasswordFile = config.sops.secrets.userPasswordHash.path; }
    else { initialPassword = vars.initialPassword; });

  system.stateVersion = "24.11"; # do not change after initial install
}
