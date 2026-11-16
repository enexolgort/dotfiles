# Shared values; each hosts/<name>/vars.nix is merged on top. Service-specific
# values belong in the vars.nix of the host that enables the service.
{
  system = "x86_64-linux";

  timeZone = "Europe/Paris";
  locale = "en_US.UTF-8";
  keyMap = "fr"; # AZERTY. Use "be" for Belgian AZERTY, "us" for QWERTY

  initialPassword = "changeme";

  # Public keys allowed to SSH in as the main user on every host
  # (key-only logins are what herdr's `hc machine add` needs).
  sshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfCPT1zuWITFVKSAOmkLAr4wpXkHLDxzNUVptgI88lf sftp-laptop" # Windows desktop-nd37gjk
  ];

  mediaDir = "/data/media";
  projectsDir = "/data/projects"; # install.sh clones projectRepos here
  gitDataDir = "/var/lib/forgejo";

  sambaWorkgroup = "WORKGROUP";

  extraMounts = [ ];

  secretsEnabled = false;

  notifyWebhook = "";

  ytdlpEnable = false;
  herdrEnable = false; # herdr desktop app via its upstream installer (post-install.sh)
  claudeEnable = true; # Claude Code via its native installer (post-install.sh)
  hermesAgentEnable = false; # Nous Research Hermes Agent via its installer (post-install.sh)
  bc250Enable = false; # AMD BC-250 board support (common/bc250.nix), real hosts only

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
  # dockhandEnable    = true | false;  # Docker UI on :3006
  # desktopEnable     = true | false;
  # nvidiaEnable      = true | false;  # NVIDIA driver, real hosts only
  # gamingEnable      = true | false;  # Steam + Proton
  #
  # --- Real-machine (targetType = "real") hosts only ----------------------
  # bootloader        = "systemd-boot" | "grub";  # grub for legacy BIOS
  # grubDevice        = "/dev/sda";                # if grub
  # sftpEnable        = true | false;
  # projectRepos      = [ "https://..." ... ];
  # swapfileGB        = 16;                        # optional, /var/lib/swapfile
  # kernelParams      = [ "..." ];                 # optional, extra boot.kernelParams
  # extraPackages     = [ "amdgpu_top" ];          # optional, nixpkgs attribute names
  #
  # --- Per-host, only needed if the matching *Enable above is true -------
  # sftpDir           = "/data/sftp";                    # if sftpEnable
  # sftpPublicKeys    = [ "ssh-ed25519 ..." ];            # if sftpEnable
  # couchdbAdminUser  = "admin";                          # if obsidianEnable
  # couchdbAdminPass  = "...";                            # if obsidianEnable
  # gitAdminUser      = "gituser"; # "admin" is reserved   # if gitServerEnable
  # gitAdminPass      = "...";                            # if gitServerEnable
  # gitDataDir        = "/data/media/forgejo";            # optional, if gitServerEnable
  # aiModels          = [ "qwen2.5:0.5b" ];               # if aiEnable
  # aiBackend         = "cpu" | "vulkan" | "rocm" | "cuda";  # optional, if aiEnable (default "cpu")
  # aiEnvironment     = { OLLAMA_... = "..."; };    # optional, if aiEnable
  # openWebuiCatppuccin = true;                     # optional, if aiEnable: Catppuccin Mocha dark theme
  # n8nNpmPackages    = [ "lodash" "axios" ];         # optional, if n8nEnable: npm packages for the Code node
  # n8nCatppuccin     = true;                         # optional, if n8nEnable: Catppuccin Mocha dark theme
  # n8nCommunityNodes = [ "n8n-nodes-forgejo@0.2.0" ];  # optional, if n8nEnable: pinned community node packages
  # nvidiaPrime       = { intelBusId = "PCI:0:2:0"; nvidiaBusId = "PCI:1:0:0"; };  # optional, hybrid laptops (amdgpuBusId for AMD)
  # backupEnable      = true | false;
  # backupRepo        = "/mnt/backup/restic-repo";        # if backupEnable
  # backupPassword    = "...";                            # if backupEnable
}
