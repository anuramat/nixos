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
    inputs.treefmt-nix.flakeModule
    inputs.nix-topology.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.ez-configs.flakeModule
    inputs.files.flakeModules.default
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
    # tests = import ... # system-agnostic tests
    # TODO aren't all my tests agnostic? try moving everything here
    consts = {
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
      files.files =
        let
          basename = builtins.baseNameOf;
        in
        [
          rec {
            path_ = "flake.nix";
            drv =
              let
                template = lib.generators.toPretty { } {
                  outputs = x: x;
                  inputs = import ./inputs.nix;
                };
                text =
                  builtins.replaceStrings [ "<function>" ] [ "args: import ./outputs.nix args" ] template + "\n";
              in
              pkgs.writeText (basename path_) text;
          }
        ];
      apps.generateFlake = {
        program = config.files.writer.drv;
        meta.description = "generate flake.nix from inputs.nix (result imports outputs.nix)";
      };
      # move these
      treefmt = import ./parts/treefmt.nix args;
      topology = import ./parts/topology.nix args;
      nix-unit = {
        inputs = {
          inherit (inputs) nixpkgs flake-parts nix-unit;
        };
        tests = import ./tests {
          inherit pkgs;
          lib = nixpkgs.lib;
        };
      };

      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit system;
        extraSpecialArgs = {
          inherit inputs hax;
        };
        module = inputs.self.modules.nixvim;
      };
    };
}
