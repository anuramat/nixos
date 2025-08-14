{
  nixpkgs,
  nixvim,
  flake-parts,
  ...
}@inputs:
flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.nix-topology.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.ez-configs.flakeModule
  ];
  systems = [
    "x86_64-linux"
  ];
  ezConfigs =
    let
      inherit (nixpkgs) lib;
      root = ./.;
      hax = import ./hax {
        inherit
          lib
          inputs
          root
          consts
          ;
      };
      user = {
        username = "anuramat";
        fullname = "Arsen Nuramatov";
        email = "x@ctrl.sn";
        tz = "Europe/Berlin";
        locale = "en_US.UTF-8";
      };
      consts = {
        builderUsername = "builder";
        cacheFilename = "cache.pem.pub";
        cfgRoot = ./. + "/nixos-configurations/";
      };
      shared = {
        overlays = ./overlays;
        secrets = ./secrets;
        stylix = ./stylix;
      };
      globalArgs = {
        inherit
          shared
          inputs
          hax
          user
          root
          consts
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
  };

  perSystem =
    { system, lib, ... }:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      treefmt = {
        settings.formatter = {
          shfmt.options = [
            "--write"
            "--simplify"
            "--case-indent"
            "--binary-next-line"
          ];
          shellharden = {
            includes = [ "*.sh*" ];
            command = lib.getExe pkgs.shellharden;
            options = [ "--replace" ];
          };
        };
        programs = {
          nixfmt.enable = true;
          stylua.enable = true;
          shfmt = {
            enable = true;
            indent_size = 0;
          };
          yamlfmt.enable = true;
          black.enable = true;
          just.enable = true;
        };
      };
      topology = {
        modules = [
          {
            nodes = {
            };
          }
        ];
      };
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
          inherit inputs;
          hax = import ./hax {
            lib = nixpkgs.lib;
            inherit inputs;
          };
        };
        module = {
          imports = [
            ./common/overlays.nix
            ./home/nixvim
          ];
        };
      };
    };
}
