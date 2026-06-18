# vim: fdl=0 fdm=marker
{
  nixpkgs,
  nixvim,
  flake-parts,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;
  # helper {{{1
  mapModuleDir =
    func: dir:
    builtins.readDir dir
    |> builtins.attrNames
    |> map (
      relativePath:
      let
        name = lib.removeSuffix ".nix" relativePath;
        module = /${dir}/${relativePath};
      in
      lib.nameValuePair name (func name module)
    )
    |> lib.listToAttrs;
  mkImportSet = mapModuleDir (_: import);
  # }}}1

  pkgsWithOverlay =
    system:
    import inputs.nixpkgs (
      {
        inherit system;
      }
      // (inputs.self.sharedModules.nixpkgs { inherit inputs; }).nixpkgs
    );
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
      nixosModules = mkImportSet ./nixos-modules;
      homeModules = mkImportSet ./home-modules;
      mkNixosConfigurations = mapModuleDir (
        name: module:
        inputs.nixpkgs.lib.nixosSystem {
          # hostname = directory name, by construction
          modules = [
            module
            { networking.hostName = name; }
          ];
          specialArgs = {
            inherit inputs;
          };
        }
      );
      mkHomeConfigurations =
        configSystem:
        (mapModuleDir (
          name: module:
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = pkgsWithOverlay configSystem.${name};
            modules = [ module ];
            extraSpecialArgs = {
              inherit inputs;
            };
          }
        ) ./home-configurations);
    in
    {
      inherit nixosModules homeModules;
      nixosConfigurations = mkNixosConfigurations ./nixos-configurations;
      homeConfigurations = mkHomeConfigurations {
        "example-config-linux" = "x86_64-linux";
        "example-config-darwin" = "aarch64-darwin";
      };

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

      # per-host key material discovered from nixos-configurations/*/keys/ {{{1
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
      # }}}1

      overlays = mapModuleDir (_name: module: import module { inherit inputs lib; }) ./overlays; # TODO use mkImportSet as well?
      # TODO split into default and heavy, then add light version to anuramat-root
      nixvimModules = mkImportSet ./nixvim-modules;
      sharedModules = mkImportSet ./shared-modules;
    };

  perSystem =
    {
      config,
      system,
      ...
    }@args:
    let
      argsWithInputs = args // {
        inherit inputs pkgs;
      };
      pkgs = pkgsWithOverlay system;
    in
    (mapModuleDir (_name: module: import module argsWithInputs) ./parts)
    // {
      # evaluate every host's toplevel (firing all assertions) without building it
      checks = # {{{1
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
              } "echo $drv >$out"
            )
          )
        )
        # hand-pinned vendorHash drift only surfaces at build time, so build these
        // lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) protonmail-bridge waybar-niri-windows;
        }
        // {
          # builds packages.neovim and runs it headless to catch startup errors
          neovim = nixvim.lib.${system}.check.mkTestDerivationFromNvim {
            name = "neovim";
            nvim = config.packages.neovim;
          };
        };
      # }}}1
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
