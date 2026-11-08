# common/forgejo.nix — self-hosted, tailnet-only git server. Tailnet
# access needs no firewall rule (trustedInterfaces in networking.nix
# covers it, same as Jellyfin); the one rule below is for local Docker
# containers.
# Lightweight (single Go binary, SQLite by default) — fine for modest
# hardware. Reachable at http://<tailscale-ip>:3000. Off unless a host
# sets gitServerEnable = true (currently mnemosyne).
#
# Data (repos, LFS, SQLite DB) lives in vars.gitDataDir — on mnemosyne
# that's /data/media/forgejo on the media HDD, which restic backs up
# daily to the backup drive (common/backups.nix).
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.gitServerEnable {
  services.forgejo = {
    enable = true;
    stateDir = vars.gitDataDir;
    settings.server = {
      HTTP_ADDR = "0.0.0.0"; # firewall (trustedInterfaces) restricts real exposure
      HTTP_PORT = 3000;
      ROOT_URL = "http://${vars.hostname}:3000/";
    };
    settings.service.DISABLE_REGISTRATION = true; # single-user server — no public signup
    settings.webhook.ALLOWED_HOST_LIST = "loopback";   # webhooks may call 127.0.0.1 / localhost
  };

  # Docker containers on this host (e.g. git-dashboard, which reads the
  # Forgejo API at host.docker.internal:3000) reach the host through a
  # Docker bridge, not tailscale0, so trustedInterfaces doesn't cover them
  # and the firewall silently drops the traffic. Open just Forgejo's port,
  # just on Docker bridges: docker0 for the default network, br-+ (iptables
  # wildcard) for the per-project networks docker compose creates. LAN and
  # internet stay blocked.
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 3000 ];
  networking.firewall.interfaces."br-+".allowedTCPPorts = [ 3000 ];

  # Declaratively ensures your admin account exists — idempotent (`|| true`
  # means it doesn't fail on every subsequent rebuild once already
  # created). This is the officially documented pattern from the NixOS
  # wiki's own Forgejo page. NOTE: "admin" itself is a reserved username
  # in Forgejo — that's why vars.gitAdminUser isn't literally "admin".
  systemd.services.forgejo.preStart = ''
    ${lib.getExe config.services.forgejo.package} admin user create \
      --admin --username ${vars.gitAdminUser} --password "${vars.gitAdminPass}" \
      --email "${vars.gitAdminUser}@${vars.hostname}.local" || true
  '';

  systemd.services.forgejo.after = [ "network-online.target" ];
  # The media drive is mounted with "nofail": never start Forgejo (and
  # silently write repos to the root disk) if it isn't mounted.
  systemd.services.forgejo.unitConfig.RequiresMountsFor = [ vars.gitDataDir ];
  systemd.services.forgejo.wants = [ "network-online.target" ];
}
