# Forgejo git server on :3000 (gitServerEnable).
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.gitServerEnable {
  services.forgejo = {
    enable = true;
    stateDir = vars.gitDataDir;
    settings.server = {
      HTTP_ADDR = "0.0.0.0";
      HTTP_PORT = 3000;
      ROOT_URL = "http://${vars.hostname}:3000/";
    };
    settings.service.DISABLE_REGISTRATION = true;
    settings.webhook.ALLOWED_HOST_LIST = "loopback";
  };

  # Local containers (git-dashboard) reach Forgejo over Docker bridges, not
  # tailscale0. br-+ covers docker compose networks.
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 3000 ];
  networking.firewall.interfaces."br-+".allowedTCPPorts = [ 3000 ];

  # Creates the admin account; `|| true` once it exists. "admin" is reserved.
  systemd.services.forgejo.preStart = ''
    ${lib.getExe config.services.forgejo.package} admin user create \
      --admin --username ${vars.gitAdminUser} --password "${vars.gitAdminPass}" \
      --email "${vars.gitAdminUser}@${vars.hostname}.local" || true
  '';

  systemd.services.forgejo.after = [ "network-online.target" ];
  # The data drive is "nofail"; don't write repos to the root disk if it's missing.
  systemd.services.forgejo.unitConfig.RequiresMountsFor = [ vars.gitDataDir ];
  systemd.services.forgejo.wants = [ "network-online.target" ];
}
