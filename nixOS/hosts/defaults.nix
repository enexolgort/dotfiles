# Shared values; each hosts/<name>/vars.nix is merged on top. Service-specific
# values belong in the vars.nix of the host that enables the service.
{
  system = "x86_64-linux";

  timeZone = "Europe/Paris";
  locale = "en_US.UTF-8";
  keyMap = "fr"; # AZERTY. Use "be" for Belgian AZERTY, "us" for QWERTY

  initialPassword = "changeme";

  mediaDir = "/data/media";
  projectsDir = "/data/projects"; # install.sh clones projectRepos here
  gitDataDir = "/var/lib/forgejo";

  sambaWorkgroup = "WORKGROUP";

  extraMounts = [ ];

  secretsEnabled = false;

  notifyWebhook = "";

  ytdlpEnable = false;
  herdrEnable = false; # herdr terminal workspace, from nixpkgs-unstable

  # --- Per-host essentials (every host's own vars.nix MUST set these) ----
  # hostname          = "...";
  # username          = "...";
  # gitEmail          = "...";
  # targetType        = "real" | "wsl";
  # jellyfinEnable    = true | false;
  # obsidianEnable    = true | false;
  # gitServerEnable   = true | false;
  # aiEnable          = true | false;
  # n8nEnable         = true | false;
  # homepageEnable    = true | false;
  # desktopEnable     = true | false;
  # nvidiaEnable      = true | false;  # NVIDIA driver, real hosts only
  # gamingEnable      = true | false;  # Steam + Proton
  #
  # --- Real-machine (targetType = "real") hosts only ----------------------
  # bootloader        = "systemd-boot" | "grub";  # grub for legacy BIOS
  # grubDevice        = "/dev/sda";                # if grub
  # sftpEnable        = true | false;
  # projectRepos      = [ "https://..." ... ];
  #
  # --- Per-host, only needed if the matching *Enable above is true -------
  # sftpDir           = "/data/sftp";                    # if sftpEnable
  # sftpPublicKeys    = [ "ssh-ed25519 ..." ];            # if sftpEnable
  # couchdbAdminUser  = "admin";                          # if obsidianEnable
  # couchdbAdminPass  = "...";                            # if obsidianEnable
  # gitAdminUser      = "gituser"; # "admin" is reserved   # if gitServerEnable
  # gitAdminPass      = "...";                            # if gitServerEnable
  # gitDataDir        = "/data/media/forgejo";            # optional, if gitServerEnable
  # nvidiaPrime       = { intelBusId = "PCI:0:2:0"; nvidiaBusId = "PCI:1:0:0"; };  # optional, hybrid laptops (amdgpuBusId for AMD)
  # backupEnable      = true | false;
  # backupRepo        = "/mnt/backup/restic-repo";        # if backupEnable
  # backupPassword    = "...";                            # if backupEnable
}
