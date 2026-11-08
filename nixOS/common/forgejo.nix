# common/forgejo.nix — self-hosted, tailnet-only git server. No firewall
# changes needed at all: trustedInterfaces in networking.nix already
# covers this port automatically, same as Jellyfin/CouchDB.
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
