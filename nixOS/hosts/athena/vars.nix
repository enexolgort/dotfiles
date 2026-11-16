{
  hostname = "athena";
  username = "enexolgort";
  gitEmail = "enexolgort@athena.local";
  targetType = "real";
  bootloader = "systemd-boot";
  # open-webui is unfree, so never in the binary cache; its frontend build
  # gets OOM-killed without swap (RAM is shared with the GPU).
  swapfileGB = 16;
  # BC-250: GPU memory comes from system RAM via TTM, capped at ~7.4 GiB by
  # default. Raise it to the full 16 GiB.
  kernelParams = ["ttm.pages_limit=4194304"];
  # amdgpu_top: GPU load (btop can't read the BC-250 without ROCm).
  extraPackages = ["amdgpu_top" "pciutils" "lm_sensors"];

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true;
  sftpEnable = false;
  n8nEnable = true;
  n8nNpmPackages = ["papaparse" "fast-xml-parser" "cheerio" "turndown" "rss-parser"];
  n8nCatppuccin = true;
  n8nCommunityNodes = ["n8n-nodes-forgejo@0.2.0"];
  homepageEnable = false;
  dockhandEnable = false;
  desktopEnable = false;
  nvidiaEnable = false;
  gamingEnable = false;
  bc250Enable = true;
  hermesAgentEnable = true;

  # AMD BC-250 (gfx1013): ROCm doesn't support it, Mesa's RADV Vulkan does.
  aiBackend = "vulkan";
  # Pulled on rebuild. ~6 GiB on the GPU, ~38 tok/s on the BC-250.
  aiModels = ["qwen3.5:9b"];
  openWebuiCatppuccin = true;
  # One model at a time: RAM is shared with n8n and Open WebUI.
  aiEnvironment = {
    # Ollama treats the BC-250 as an iGPU and skips it without this.
    OLLAMA_IGPU_ENABLE = "1";
    OLLAMA_MAX_LOADED_MODELS = "1";
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    # Hermes Agent rejects models with under 64K context.
    OLLAMA_CONTEXT_LENGTH = "65536";
  };

  backupEnable = false;

  projectRepos = [
    "http://mnemosyne:3000/enexolgort/openwebui-usage"
  ];
}
