{
  nixpkgs,
  nixvim,
  flake-parts,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;
  mkDirSet =
    func: dir:
    builtins.readDir dir
    |> builtins.attrNames
    |> map (n: lib.nameValuePair (lib.removeSuffix ".nix" n) (func /${dir}/${n}))
    |> lib.listToAttrs;
  mkImportSet = mkDirSet import;
in
flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    inputs.git-hooks-nix.flakeModule
    inputs.home-manager.flakeModules.home-manager
    inputs.nix-topology.flakeModule
    inputs.treefmt-nix.flakeModule
  ];
  systems = [
    "x86_64-linux"
    "aarch64-darwin"
  ];
  flake =
    let
      specialArgs = {
        inherit inputs;
      };
      nixosModules = mkImportSet ./nixos-modules;
      homeModules = mkImportSet ./home-modules;
      mkNixosConfigurations = mkDirSet (
        x:
        inputs.nixpkgs.lib.nixosSystem {
          # hostname = directory name, by construction
          modules = [
            x
            { networking.hostName = builtins.baseNameOf x; }
          ];
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

      # static host registry; each host asserts its own entry against its
      # actual config in nixos-modules/default/hosts.nix
      hosts = {
        anuramat-bgm5 = {
          system = "x86_64-linux";
          builder = true;
        };
        anuramat-f12 = {
          system = "x86_64-linux";
          builder = false;
        };
        anuramat-root = {
          system = "x86_64-linux";
          builder = false;
        };
        anuramat-t480 = {
          system = "x86_64-linux";
          builder = false;
        };
      };

      # designated LLM inference endpoint
      llama = {
        host = "anuramat-bgm5";
        port = 11343;
      };

      # per-host key material discovered from nixos-configurations/*/keys/
      keys =
        let
          cacheFilename = "cache.pem.pub";
        in
        builtins.readDir ./nixos-configurations
        |> builtins.attrNames
        |> map (
          host:
          let
            keyDir = ./nixos-configurations + "/${host}/keys";
            clientKeyFiles =
              builtins.readDir keyDir
              |> builtins.attrNames
              |> builtins.filter (f: lib.hasSuffix ".pub" f && f != cacheFilename)
              |> map (f: keyDir + /${f});
          in
          assert lib.assertMsg (builtins.pathExists keyDir)
            "nixos-configurations/${host}/keys/ is missing (expected *.pub, known_hosts, ${cacheFilename})";
          lib.nameValuePair host {
            inherit clientKeyFiles;
            clientKeys = clientKeyFiles |> map builtins.readFile |> map lib.trim;
            knownHostsFile = keyDir + /known_hosts;
            cacheKey = builtins.readFile (keyDir + /${cacheFilename});
            knownHostsKeys =
              builtins.readFile (keyDir + /known_hosts)
              |> lib.splitString "\n"
              |> lib.filter (v: v != "")
              |> map (v: v |> lib.splitString " " |> lib.drop 1 |> lib.concatStringsSep " ");
          }
        )
        |> lib.listToAttrs;

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
      # evaluate every host's toplevel (firing all assertions) without building it
      checks =
        (
          inputs.self.hosts
          |> lib.filterAttrs (_: host: host.system == system)
          |> lib.mapAttrs' (
            name: _:
            lib.nameValuePair "host-${name}" (
              pkgs.runCommand "host-${name}" {
                drv =
                  builtins.unsafeDiscardOutputDependency
                    inputs.self.nixosConfigurations.${name}.config.system.build.toplevel.drvPath;
              } "echo $drv > $out"
            )
          )
        )
        # hand-pinned vendorHash drift only surfaces at build time, so build these
        // lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs.extend inputs.self.overlays.default) protonmail-bridge waybar-niri-windows;
        }
        // {
          # builds packages.neovim and runs it headless to catch startup errors
          neovim = nixvim.lib.${system}.check.mkTestDerivationFromNvim {
            name = "neovim";
            nvim = config.packages.neovim;
          };
        };
      # TODO move? somehow sync extraspecialargs with home-manager import
      packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
        extraSpecialArgs = {
          inherit inputs;
        };
        module = inputs.self.nixvimModules.default;
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          neovim
          zellij
          git
          nh
          just
          fd

          nixfmt
          shellcheck
          yamllint
          luaPackages.luacheck
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
    };
}
