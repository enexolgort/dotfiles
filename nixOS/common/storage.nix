{ config, pkgs, lib, vars, ... }:

{
  systemd.tmpfiles.rules =
    [
      # "media" lets the admin user and sftpuser write here too (base.nix).
      "d ${vars.mediaDir} 0775 jellyfin media -"
      "d ${vars.mediaDir}/Movies 0775 jellyfin media -"
      "d ${vars.mediaDir}/Music 0775 jellyfin media -"
      "d ${vars.mediaDir}/Photo 0775 jellyfin media -"

      "d ${vars.projectsDir} 0755 ${vars.username} users -"
    ]
    ++ lib.optionals vars.sftpEnable [
      # sshd requires the chroot to be root-owned; upload/ is a bind mount (sftp.nix).
      "d ${vars.sftpDir} 0755 root root -"
      "d ${vars.sftpDir}/upload 0755 root root -"
    ];
}
