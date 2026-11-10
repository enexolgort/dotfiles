# Steam with Proton (gamingEnable). Steam ships Valve's Proton; GE-Proton is
# added as an extra compatibility tool.
{
  pkgs,
  lib,
  vars,
  ...
}:
lib.mkIf vars.gamingEnable {
  programs.steam = {
    enable = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    # On a hybrid laptop, games inherit this and render on the NVIDIA GPU.
    package = lib.mkIf (vars.nvidiaEnable && vars ? nvidiaPrime) (pkgs.steam.override {
      extraEnv = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
    });
  };

  programs.gamemode.enable = true;
}
