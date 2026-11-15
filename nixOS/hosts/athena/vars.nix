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
  kernelParams = [ "ttm.pages_limit=4194304" ];
  # amdgpu_top: GPU load (btop can't read the BC-250 without ROCm).
  extraPackages = [ "amdgpu_top" "pciutils" "lm_sensors" ];

  jellyfinEnable = false;
  obsidianEnable = false;
  gitServerEnable = false;
  aiEnable = true;
  sftpEnable = false;
  n8nEnable = true;
  n8nNpmPackages = [ "papaparse" "fast-xml-parser" "cheerio" "turndown" "rss-parser" ];
  n8nCatppuccin = true;
  homepageEnable = false;
  dockhandEnable = false;
  desktopEnable = false;
  nvidiaEnable = false;
  gamingEnable = false;
  bc250Enable = true;

  # AMD BC-250 (gfx1013): ROCm doesn't support it, Mesa's RADV Vulkan does.
  aiBackend = "vulkan";
  # Pulled on rebuild. ~8 GiB at 4K context, ~23 tok/s on a stock BC-250.
  aiModels = [ "qwen3.5:9b" ];
  # One model at a time: RAM is shared with n8n and Open WebUI.
  aiEnvironment = {
    # Ollama treats the BC-250 as an iGPU and skips it without this.
    OLLAMA_IGPU_ENABLE = "1";
    OLLAMA_MAX_LOADED_MODELS = "1";
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    OLLAMA_CONTEXT_LENGTH = "32768";
  };

  backupEnable = false;

  projectRepos = [ ];
}
