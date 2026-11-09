# n8n workflow automation (n8nEnable), via the official Docker image: the
# nixpkgs services.n8n builds from source and hits Node's heap limit.
#
# --network=host, not a port mapping: Docker's published ports bypass the
# NixOS firewall, so a mapping would expose n8n beyond the tailnet.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.n8nEnable {
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.n8n = {
    image = "docker.n8n.io/n8nio/n8n:latest";
    autoStart = true;
    extraOptions = [ "--network=host" ];
    volumes = [ "/var/lib/n8n:/home/node/.n8n" ];
    environment = {
      N8N_PORT = "5678";
      # Secure-only cookies break plain HTTP; Tailscale encrypts the transport.
      N8N_SECURE_COOKIE = "false";
      # Re-enables the Execute Command node (off since n8n 2.0).
      # N8N_NODES_INCLUDE is unreliable (n8n-io/n8n#23439).
      NODES_EXCLUDE = "[]";
      # Built-ins the Code node may require(). child_process and vm are
      # left out on purpose: they'd allow arbitrary shell execution.
      NODE_FUNCTION_ALLOW_BUILTIN = "net,crypto,fs,path,util,querystring,url,os,stream,zlib,dns,http,https,buffer,assert";
    };
  };

  systemd.tmpfiles.rules = [
    # 1000 = the container's "node" user; root:root crash-loops with EACCES.
    "d /var/lib/n8n 0755 1000 1000 -"
  ];

  systemd.services.docker-n8n = {
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" ];
  };
}
