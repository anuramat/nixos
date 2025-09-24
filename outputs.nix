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
  inherit (hax.common) mkImportSet mkDirSet;
in
flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    inputs.ez-configs.flakeModule
    inputs.files.flakeModules.default
    inputs.git-hooks-nix.flakeModule
    inputs.home-manager.flakeModules.home-manager
    inputs.nix-topology.flakeModule
    inputs.nix-unit.modules.flake.default
    inputs.treefmt-nix.flakeModule
  ];
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
  flake =
    let
      # TODO hide root in inputs? rename hax?
      specialArgs = {
        inherit
          inputs
          hax
          root
          ;
      };
      nixosModules = mkImportSet ./nixos-modules;
      homeModules = mkImportSet ./home-modules;
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
          pkgs = import inputs.nixpkgs {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
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

      overlays = mkDirSet (x: import x { inherit inputs lib; }) ./overlays; # use mkImportSet as well
      nixvimModules = mkImportSet ./nixvim-modules; # TODO split into default and heavy, then add light version to anuramat-root
      sharedModules = mkImportSet ./shared-modules;
    };

  perSystem =
    {
      config,
      system,
      pkgs,
      ...
    }@args:
    let
      argsWithInputs = args // {
        inherit inputs;
      };
    in
    (mkDirSet (x: import x argsWithInputs) ./parts)
    // {
      apps.writer.program = config.files.writer.drv;

      # TODO move? somehow sync extraspecialargs with home-manager import
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit system;
        extraSpecialArgs = {
          inherit inputs hax;
        };
        module = inputs.self.nixvimModules.default;
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          just
          nixfmt-rfc-style
          nix-unit
          fd
          shellcheck
          yamllint
          luaPackages.luacheck
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
          echo 1>&2 "Welcome to the development shell!"
        '';
      };
    };
}
