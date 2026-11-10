# Every service is reachable only through tailscale0 (trusted). Nothing
# else opens TCP ports.
{ config, pkgs, lib, vars, ... }:

{
  # First boot: sudo tailscale up --ssh
  services.tailscale.enable = true;

  systemd.services.tailscaled = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ 41641 ]; # direct (non-relayed) Tailscale connections
  };

  services.openssh = {
    enable = true;
    # Defaults to true, which would open :22 on every interface.
    openFirewall = false;
    settings.PasswordAuthentication = true; # tailnet-only
  };
}
