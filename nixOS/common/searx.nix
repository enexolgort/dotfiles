# SearXNG metasearch on :8888 for hosts with aiEnable: web search for Open
# WebUI and n8n agents. :8080 (the module default) is Open WebUI's.
{ config, lib, pkgs, vars, ... }:

let
  port = 8888;
  secretFile = "/var/lib/searx/secret.env";
in
lib.mkIf vars.aiEnable {
  services.searx = {
    enable = true;
    package = pkgs.searxng;
    # Generated on first boot by searx-secret below, never in the Nix store.
    environmentFile = secretFile;
    settings = {
      server = {
        inherit port;
        bind_address = "0.0.0.0";
        secret_key = "$SEARX_SECRET_KEY";
        # The rate limiter needs Valkey and only matters for public instances.
        limiter = false;
      };
      # Open WebUI and n8n query the JSON API.
      search.formats = [ "html" "json" ];
    };
  };

  systemd.services.searx-secret = {
    description = "Generate the SearXNG secret key";
    before = [ "searx-init.service" ];
    requiredBy = [ "searx-init.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ ! -s ${secretFile} ]; then
        install -d -m 0700 ${dirOf secretFile}
        (umask 077; echo "SEARX_SECRET_KEY=$(${pkgs.openssl}/bin/openssl rand -hex 32)" > ${secretFile})
      fi
    '';
  };

  services.open-webui.environment = {
    # Only seed Open WebUI's stored config; once saved, Admin > Settings >
    # Web Search wins.
    ENABLE_WEB_SEARCH = "True";
    WEB_SEARCH_ENGINE = "searxng";
    SEARXNG_QUERY_URL = "http://127.0.0.1:${toString port}/search?q=<query>";
  };
}
