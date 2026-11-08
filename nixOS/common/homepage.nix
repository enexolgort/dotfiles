# common/homepage.nix — one dashboard linking every service in the
# fleet, with a live up/down dot per service. Reachable only via your
# tailnet at http://<host>:8082, same as everything else here
# (openFirewall stays false, tailscale0 is trusted — see networking.nix).
#
# Status dots (siteMonitor) are checked server-side, from the host
# running Homepage, so they rely on that host resolving the other hosts'
# MagicDNS names. A service on a host that isn't deployed yet just
# shows as down.
{ config, pkgs, lib, vars, ... }:

let
  port = 8082;
  # One tile: href is what your browser opens, siteMonitor what Homepage
  # pings for the status dot (defaults to the same URL). The port is
  # appended to the description so each tile shows what it listens on.
  tile = { name, host, port, description, icon, path ? "/", monitorPath ? path }: {
    ${name} = {
      inherit icon;
      description = "${description} · :${toString port}";
      href = "http://${host}:${toString port}${path}";
      siteMonitor = "http://${host}:${toString port}${monitorPath}";
    };
  };
in
lib.mkIf vars.homepageEnable {
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
    openFirewall = false;
    # Homepage rejects requests whose Host header isn't listed here, so
    # this has to include the name you actually type in the browser.
    allowedHosts = lib.concatStringsSep "," [
      "${vars.hostname}:${toString port}"
      "localhost:${toString port}"
      "127.0.0.1:${toString port}"
    ];

    settings = {
      title = "Homelab";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      layout = {
        mnemosyne = { style = "row"; columns = 3; };
        hermes = { style = "row"; columns = 3; };
        athena = { style = "row"; columns = 3; };
      };
    };

    widgets = [
      {
        resources = {
          label = vars.hostname;
          cpu = true;
          memory = true;
          disk = [ "/" vars.mediaDir ];
        };
      }
      { datetime = { format = { dateStyle = "long"; timeStyle = "short"; hour12 = false; }; }; }
    ];

    services = [
      {
        mnemosyne = [
          (tile { name = "Jellyfin"; host = "mnemosyne"; port = 8096; description = "Media server"; icon = "jellyfin.png"; })
          (tile { name = "Torrent UI"; host = "mnemosyne"; port = 4173; description = "transmission-webUi"; icon = "transmission.png"; })
          (tile { name = "Video UI"; host = "mnemosyne"; port = 4174; description = "yt-dlp-webUi"; icon = "si-youtube"; })
          (tile { name = "Forgejo"; host = "mnemosyne"; port = 3000; description = "Git server"; icon = "forgejo.png"; })
        ];
      }
      {
        hermes = [
          (tile { name = "transmission-API"; host = "hermes"; port = 3002; description = "API + SFTP push"; icon = "transmission.png"; path = "/"; monitorPath = "/health"; })
          (tile { name = "Transmission"; host = "hermes"; port = 9091; description = "Daemon web UI / RPC"; icon = "transmission.png"; path = "/transmission/web/"; })
          (tile { name = "yt-dlp-API"; host = "hermes"; port = 3003; description = "Video downloads + SFTP push"; icon = "si-youtube"; path = "/"; monitorPath = "/health"; })
        ];
      }
      {
        athena = [
          (tile { name = "Open WebUI"; host = "athena"; port = 8080; description = "Chat with local models"; icon = "open-webui.png"; })
          (tile { name = "Ollama"; host = "athena"; port = 11434; description = "Model runner API"; icon = "ollama.png"; })
          (tile { name = "n8n"; host = "athena"; port = 5678; description = "Workflow automation"; icon = "n8n.png"; })
        ];
      }
    ];
  };

  systemd.services.homepage-dashboard = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };
}
