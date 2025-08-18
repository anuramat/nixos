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
  ezConfigs =
    let
      user = inputs.self.user; # TODO remove and use the output
      globalArgs = {
        inherit
          inputs
          hax
          user
          root
          ;
      };
    in
    {
      root = ./.;
      inherit globalArgs;
      nixos = {
        hosts = {
          anuramat-ll7.userHomeModules = [ "anuramat" ];
          anuramat-root.userHomeModules = [ "anuramat" ];
          anuramat-t480.userHomeModules = [ "anuramat" ];
        };
      };
    };
  flake = {
    # tests = import ... # system-agnostic tests TODO aren't all my tests agnostic? try moving everything here
    consts = {
      # move to a file?
      builderUsername = "builder";
      cacheFilename = "cache.pem.pub";
      cfgRoot = ./. + "/nixos-configurations/";
    };

    # TODO refactor these: try to mimic ez-configs (auto-import shallowly)
    overlays = import ./overlays { inherit inputs lib; };
    modules = {
      stylix = import ./modules/stylix.nix;
      age = import ./modules/age.nix;
      nixvim = import ./modules/nixvim;
    };

    user = {
      # TODO move to a file
      username = "anuramat";
      fullname = "Arsen Nuramatov";
      email = "x@ctrl.sn";
      tz = "Europe/Berlin";
      locale = "en_US.UTF-8";
    };
  };

  perSystem =
    {
      config,
      system,
      lib,
      pkgs,
      ...
    }@args:
    {
      files = import ./parts/files.nix args;
      treefmt = import ./parts/treefmt.nix args;
      topology = import ./parts/topology.nix args;
      pre-commit = import ./parts/pre-commit.nix args;

      apps.writer.program = config.files.writer.drv;

      # TODO move agnostic tests to tests
      nix-unit = import ./parts/nix-unit.nix (args // { inherit inputs; });

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
