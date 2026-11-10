# NVIDIA driver (nvidiaEnable). With vars.nvidiaPrime set (hybrid laptop),
# the iGPU drives the screen and the dGPU renders on demand via nvidia-offload.
{
  config,
  lib,
  vars,
  ...
}:
lib.mkIf vars.nvidiaEnable {
  # Loads the kernel modules; it does not enable an X server.
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # Blackwell (RTX 50xx) only works with the open kernel modules.
    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
    powerManagement.finegrained = vars ? nvidiaPrime;

    prime = lib.mkIf (vars ? nvidiaPrime) ({
        offload.enable = true;
        offload.enableOffloadCmd = true;
      }
      // (vars.nvidiaPrime or {}));
  };
}
