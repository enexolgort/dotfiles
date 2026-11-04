{
  hostname = "janus";
  username = "enexolgort";
  gitEmail = "enexolgort@janus.local";
  targetType = "real";
  bootloader = "systemd-boot"; # bare-metal, UEFI

  # janus is the client machine — browser + SSH into the rest of the
  # fleet over Tailscale — so it runs no services of its own. It's the
  # one host with the Hyprland desktop on (see common/desktop.nix +
  # home-desktop.nix).
  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = false;
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = true;

  backupEnable = false;

  projectRepos = [ ];
}
