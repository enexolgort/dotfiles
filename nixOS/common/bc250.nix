# AMD BC-250 board support from github:TesseractCat/bc250-nixos, bc250Enable.
# Its defaults also turn on the nct6687 sensors, the GPU governor and zswap.
{
  lib,
  vars,
  ...
}:
lib.mkIf vars.bc250Enable {
  hardware.bc250 = {
    enable = true;
    # 6c/12t -> 8c/16t. Runs in the initrd and reboots once on cold boot;
    # refuses if the core mask isn't the expected 0x77. Skip for one boot
    # with the bc250.nocoreunlock kernel parameter.
    features.coreUnlock.enable = true;
  };

  # GPU frequency reporting breaks with core unlock unless this is set.
  services.cyan-skillfish-governor-smu.settings.gpu-usage.fix-freq = true;
}
