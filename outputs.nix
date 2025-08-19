{
  nixpkgs,
  nixvim,
  flake-parts,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;
  root = ./.;
  hax = import ./hax {
    inherit
      lib
      inputs
      root
      ;
  };
in
flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    inputs.ez-configs.flakeModule
    inputs.files.flakeModules.default
    inputs.nix-topology.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks-nix.flakeModule
  ];
  systems = [
    "x86_64-linux"
  ];
  ezConfigs = {
    root = ./.;
    globalArgs = {
      inherit
        inputs
        hax
        root
        ;
      username = "anuramat"; # shouldn't be used in home-manager, but specifying it in nixos specialargs causes a recursion error BUG
    };
    nixos = {
      hosts = {
        anuramat-ll7.userHomeModules = {
          anuramat = "anuramat-full";
        };
        anuramat-root.userHomeModules = {
          anuramat = "anuramat-minimal";
        };
        anuramat-t480.userHomeModules = {
          anuramat = "anuramat-full";
        };
      };
    };
    home = {
      users.anuramat-standalone = {
        passInOsConfig = false;
        standalone = {
          enable = true;
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
      };
    };
  };
  flake = {
    consts = {
      builderUsername = "builder";
      cacheFilename = "cache.pem.pub";
      cfgRoot = ./. + "/nixos-configurations/";
    };

    overlays = import ./overlays { inherit inputs lib; };

    modules = {
      stylix = import ./modules/stylix.nix;
      age = import ./modules/age.nix;
      nixvim = import ./modules/nixvim;
    };

  };

  perSystem =
    {
      config,
      system,
      pkgs,
      ...
    }@args:
    {
      files = import ./parts/files.nix args;
      nix-unit = import ./parts/nix-unit.nix (args // { inherit inputs; });
      pre-commit = import ./parts/pre-commit.nix args;
      topology = import ./parts/topology.nix args;
      treefmt = import ./parts/treefmt.nix args;

      apps.writer.program = config.files.writer.drv;

      # TODO move? somehow sync extraspecialargs with home-manager import
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit system;
        extraSpecialArgs = {
          inherit inputs hax;
        };
        module = inputs.self.modules.nixvim;
      };
    };
}
