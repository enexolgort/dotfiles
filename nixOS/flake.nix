{
  description = "Multi-machine NixOS config — real machine + WSL targets, one profile per host under hosts/";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # vps only — pinned separately so it can track 26.05 without bumping
    # every other host. See mkHost's nixpkgsFor below.
    nixpkgs-2605.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-2605, home-manager, nixos-wsl, sops-nix, treefmt-nix, ... }:
    let
      lib = nixpkgs.lib;
      defaults = import ./hosts/defaults.nix;

      # Every subdirectory of ./hosts is a machine profile. defaults.nix
      # itself is a file (not a directory), so it's naturally excluded
      # from this list — no special-casing needed.
      hostsDir = ./hosts;
      hostNames = builtins.attrNames (
        lib.filterAttrs (name: type: type == "directory") (builtins.readDir hostsDir)
      );

      # vps tracks 26.05 (see nixpkgs-2605 input above); every other host
      # stays on the fleet-wide 25.11 default.
      nixpkgsFor = name: if name == "vps" then nixpkgs-2605 else nixpkgs;

      mkHomeManagerModule = vars: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit vars; };
        home-manager.users.${vars.username} = {
          imports = [ ./home.nix ] ++ lib.optional vars.desktopEnable ./home-desktop.nix;
        };
      };

      mkHost = name:
        let
          hostVars = import (hostsDir + "/${name}/vars.nix");
          vars = defaults // hostVars;
          hardwareFile = hostsDir + "/${name}/hardware-configuration.nix";
        in
        (nixpkgsFor name).lib.nixosSystem {
          system = vars.system;
          specialArgs =
            { inherit vars; }
            // lib.optionalAttrs (vars.targetType == "wsl") { inherit nixos-wsl; };
          modules =
            [
              (if vars.targetType == "wsl" then ./wsl-configuration.nix else ./configuration.nix)
              home-manager.nixosModules.home-manager
              sops-nix.nixosModules.sops
              (mkHomeManagerModule vars)
            ]
            ++ lib.optional (vars.targetType == "real") hardwareFile;
        };

      system = defaults.system;
      pkgs = nixpkgs.legacyPackages.${system};
      treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      formatter.${system} = treefmtEval.config.build.wrapper;
      checks.${system}.formatting = treefmtEval.config.build.check self;

      nixosConfigurations = builtins.listToAttrs (
        map (name: { inherit name; value = mkHost name; }) hostNames
      );
    };
}
