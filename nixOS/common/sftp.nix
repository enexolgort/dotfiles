# Chrooted upload-only account writing into mediaDir (sftpEnable).
{ config, pkgs, lib, vars, ... }:

lib.mkIf vars.sftpEnable {
  fileSystems."${vars.sftpDir}/upload" = {
    device = vars.mediaDir;
    fsType = "none"; # required since nixos-26.05
    options = [ "bind" ];
  };

  users.groups.sftponly = {};
  users.users.sftpuser = {
    isSystemUser = true;
    group = "sftponly";
    # "media" grants write access to mediaDir.
    extraGroups = [ "sftponly" "media" ];
    shell = "${pkgs.shadow}/bin/nologin";
    openssh.authorizedKeys.keys = vars.sftpPublicKeys;
  };

  services.openssh.extraConfig = ''
    Match Group sftponly
      ChrootDirectory ${vars.sftpDir}
      ForceCommand internal-sftp
      AllowTcpForwarding no
      X11Forwarding no
      PasswordAuthentication no
  '';
}
