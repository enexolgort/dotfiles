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
    environmentVariables = vars.aiEnvironment or {};
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

  # Open WebUI links /static/custom.css on every page but wipes STATIC_DIR
  # on each start, so the theme is written once the server is up.
  systemd.services.open-webui-theme = lib.mkIf (vars.openWebuiCatppuccin or false) {
    description = "Install the Catppuccin Mocha custom.css for Open WebUI";
    after = [ "open-webui.service" ];
    partOf = [ "open-webui.service" ];
    wantedBy = [ "open-webui.service" "multi-user.target" ];
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      # Stays active so PartOf re-runs it whenever open-webui restarts.
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 1 150); do
        curl -sf http://127.0.0.1:${toString config.services.open-webui.port}/health >/dev/null && break
        sleep 2
      done
      install -m 0644 ${./open-webui-catppuccin-mocha.css} \
        ${config.services.open-webui.environment.STATIC_DIR or "/var/lib/open-webui/static"}/custom.css
    '';
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
