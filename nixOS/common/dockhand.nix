# Dockhand Docker management UI on :3006 (dockhandEnable), via its official
# image. Its default port 3000 is taken by Forgejo, hence PORT.
#
# --network=host, not a port mapping: Docker's published ports bypass the
# NixOS firewall, so a mapping would expose Dockhand beyond the tailnet.
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.dockhandEnable {
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.dockhand = {
    image = "fnsys/dockhand:latest";
    autoStart = true;
    extraOptions = [ "--network=host" ];
    volumes = [
      # Root-equivalent access to the host; acceptable only because it's tailnet-only.
      "/var/run/docker.sock:/var/run/docker.sock"
      # Database, stacks and the auto-generated ENCRYPTION_KEY.
      "/var/lib/dockhand:/app/data"
    ];
    environment = {
      PORT = "3006";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dockhand 0750 root root -"
  ];

  systemd.services.docker-dockhand = {
    after = [ "network-online.target" "docker.service" ];
    wants = [ "network-online.target" ];
  };
}
