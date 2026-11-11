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
  dockhandEnable = false;
  desktopEnable = true;
  nvidiaEnable = true;
  gamingEnable = true;
  herdrEnable = true;
  claudeEnable = true;

  # Placeholders: replace with `lspci | grep -E "VGA|3D"` on janus, in
  # PCI:bus:device:function form (decimal). Use amdgpuBusId for an AMD CPU.
  nvidiaPrime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  backupEnable = false;

  projectRepos = [];
}
