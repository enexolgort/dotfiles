{
  hostname = "athena";
  username = "enexolgort";
  gitEmail = "enexolgort@athena.local";
  targetType = "real";
  bootloader = "systemd-boot"; # bare-metal, UEFI

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true; # Ollama + Open WebUI — see common/ai.nix
  sftpEnable = false;
  n8nEnable = false;
  monitoringHubEnable = false;
  desktopEnable = false;

  # Models Ollama pulls automatically on rebuild. Starting with the
  # smallest usable one — CPU-only inference (the default in
  # common/ai.nix) is slow beyond small models. Add bigger ones here
  # (e.g. "llama3.2:3b") once you know what this machine can handle,
  # and switch `acceleration` in common/ai.nix if it has a GPU.
  aiModels = [ "qwen2.5:0.5b" ];

  backupEnable = false;

  projectRepos = [ ];
}
