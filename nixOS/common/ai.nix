# Ollama (:11434) + Open WebUI (:8080), aiEnable.
{ config, pkgs, lib, vars, ... }:

let
  backend = vars.aiBackend or "cpu";
in
lib.mkIf vars.aiEnable {
  services.ollama = {
    enable = true;
    package = pkgs."ollama-${backend}";
    loadModels = vars.aiModels;
    host = "0.0.0.0"; # defaults to 127.0.0.1
  };

  services.open-webui = {
    enable = true;
    # Defaults to 127.0.0.1. Not "": that breaks the unit (NixOS/nixpkgs#378188).
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434/api";
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
    };
  };

  # Vulkan/ROCm load the GPU driver from /run/opengl-driver.
  hardware.graphics.enable = lib.mkIf (backend != "cpu") true;

  systemd.services.ollama = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
  systemd.services.open-webui = {
    after = [ "network-online.target" "ollama.service" ];
    wants = [ "network-online.target" ];
  };
}
