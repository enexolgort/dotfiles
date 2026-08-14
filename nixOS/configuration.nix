# configuration.nix
# The REAL MACHINE / VM target — bare-metal or VirtualBox-style install
# with an actual disk and bootloader. Everything shared with the WSL
# target lives in ./common/ instead.
{ config, pkgs, lib, vars, ... }:

{
  # Bootloader choice is per-host (vars.bootloader = "systemd-boot" or
  # "grub") — systemd-boot is UEFI-only, full stop, no legacy BIOS
  # fallback exists. A VM running in legacy BIOS mode (confirmed via
  # `sudo parted /dev/sda -- print` showing "Partition Table: msdos"
  # instead of "gpt") categorically cannot use it, regardless of how
  # correctly the disk is otherwise partitioned — this is what caused a
  # long recurring saga on headfull before the actual root cause (VM
  # firmware mode, not partitioning) was identified. GRUB supports both
  # BIOS and UEFI, so it's the one that actually works here.
  boot.loader.systemd-boot.enable = lib.mkIf (vars.bootloader == "systemd-boot") true;
  boot.loader.systemd-boot.configurationLimit = lib.mkIf (vars.bootloader == "systemd-boot") 10; # cap boot entries — the ESP has limited space
  boot.loader.efi.canTouchEfiVariables = lib.mkIf (vars.bootloader == "systemd-boot") true;

  boot.loader.grub.enable = lib.mkIf (vars.bootloader == "grub") true;
  boot.loader.grub.device = lib.mkIf (vars.bootloader == "grub") vars.grubDevice; # e.g. "/dev/sda" — the whole disk, not a partition

  networking.networkmanager.enable = true;

  # --- Samba share for LAN devices (unrelated to Tailscale) -----------
  # Real-machine only — nmbd needs UDP broadcast networking that WSL2's
  # virtualized NAT adapter doesn't support (it crashes outright there,
  # not just fails to be reachable), so this lives here rather than in
  # common/.
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = vars.sambaWorkgroup;
        "server string" = vars.hostname;
        security = "user";
      };
      media = {
        path = vars.mediaDir;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = vars.username;
        "force group" = "media"; # was vars.username — same wrong-group-name bug as storage.nix/sftp.nix, see base.nix's note
        "create mask" = "0664";
        "directory mask" = "0775";
      };
    };
  };
  # Set the samba password once, after first boot: sudo smbpasswd -a <username>

  # --- Extra storage drives (SATA drives on the ZimaBoard, etc.) ------
  # Declared in vars.nix as a list — generated into real fileSystems
  # entries here. "nofail" is set per-entry in vars.nix by default so a
  # missing/disconnected drive doesn't block boot.
  fileSystems = builtins.listToAttrs (map
    (m: {
      name = m.mountPoint;
      value = {
        device = m.device;
        fsType = m.fsType or "ext4";
        options = m.options or [ "defaults" "nofail" ];
      };
    })
    vars.extraMounts);

  imports = [ ./common ];
}
