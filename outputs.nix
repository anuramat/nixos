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
    inputs.home-manager.flakeModules.home-manager
  ];
  systems = [
    "x86_64-linux"
  ];
  flake =
    let
      specialArgs = {
        inherit
          inputs
          hax
          root
          ;
        username = "anuramat"; # shouldn't be used in home-manager TODO
      };
      nixosModules = mkImportSet ./nixos-modules;
      homeModules = mkImportSet ./home-modules;
      mkDirSet =
        func: dir:
        with builtins;
        readDir dir
        |> attrNames
        |> map (n: lib.nameValuePair (lib.removeSuffix ".nix" n) (func "${dir}/${n}")) # assert .nix equiv regular; assert no collisions
        |> lib.listToAttrs;
      mkImportSet = mkDirSet (x: import x);
      mkNixosConfigurations = mkDirSet (
        x:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [ x ];
          inherit specialArgs;
        }
      );
      mkHomeConfigurations = mkDirSet (
        x:
        inputs.home-manager.lib.homeManagerConfiguration {
          modules = [ x ];
          extraSpecialArgs = specialArgs;
        }
      );
    in
    {
      inherit nixosModules homeModules;
      nixosConfigurations = mkNixosConfigurations ./nixos-configurations;
      homeConfigurations = mkHomeConfigurations ./home-configurations;

      consts = {
        builderUsername = "builder";
        cacheFilename = "cache.pem.pub";
        cfgRoot = ./. + "/nixos-configurations/";
      };

      overlays = import ./overlays { inherit inputs lib; }; # use mkImportSet as well
      modules = {
        home = mkImportSet ./home-modules; # TODO move
        nixvim = mkImportSet ./nixvim-modules; # TODO split into default and heavy
        generic = mkImportSet ./shared-modules; # TODO rename
      };
    };

  perSystem =
    {
      config,
      system,
      pkgs,
      # TODO check if inputs are provided?
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
        module = inputs.self.nixvimModules.default;
      };
    };
}
