{
  nixpkgs,
  home-manager,
  nixvim,
  flake-utils,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;
  hax = import ./hax { inherit lib inputs; };
  hostnames = hax.hosts.getHostnames ./hosts;
  user = {
    username = "anuramat";
    fullname = "Arsen Nuramatov";
    email = "x@ctrl.sn";
    tz = "Europe/Berlin";
    locale = "en_US.UTF-8";
  };
  args = {
    inherit user hax;
    inputs =
      let
        rawInput = import ./inputs.nix;
      in
      lib.mapAttrs (
        n: v:
        v
        // {
          ref = builtins.baseNameOf rawInput.${n}.url;
        }
      ) inputs;
  };
  mkSystem =
    name:
    let
      args2 = args // {
        cluster = hax.hosts.mkCluster ./hosts hostnames name;
      };
    in
    lib.nixosSystem {
      specialArgs = args2;
      modules = [
        inputs.agenix.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.musnix.nixosModules.musnix

        (
          { config, ... }:
          {
            networking.hostName = name;
            home-manager = {
              extraSpecialArgs = args2;
              users.${user.username} = ./home;
            };

          }
        )
        ./common/overlays.nix
        ./common/stylix.nix
        ./hosts/external_keys.nix
        ./secrets/age.nix
        ./system
      ]
      ++ [
        ./hosts/${name}
      ];
    };
in
{
  nixosConfigurations =
    hostnames
    |> map (hostname: {
      name = hostname;
      value = mkSystem hostname;
    })
    |> builtins.listToAttrs;
  homeConfigurations.${user.username} = home-manager.lib.homeManagerConfiguration {
    pkgs = import nixpkgs {
      # TODO remove hardcode
      # TODO hardcode system for hosts
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = args;
    modules = [
      {
        # this should be per host as well
        home = {
          stateVersion = "24.05";
          username = user.username;
          homeDirectory = "/home/${user.username}";
        };
      }
      inputs.stylix.homeModules.stylix
      inputs.agenix.homeManagerModules.default

      ./common/overlays.nix
      ./common/stylix.nix
      ./home
      ./secrets/age.nix
    ];
  };
}
// (flake-utils.lib.eachDefaultSystem (
  system:
  let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    packages.neovim = nixvim.legacyPackages.${system}.makeNixvimWithModule {
      inherit system;
      extraSpecialArgs = { inherit inputs hax; };
      module = {
        imports = [
          ./common/overlays.nix
          ./home/nixvim
        ];
      };
    };

    tests = import ./tests {
      inherit pkgs;
      lib = nixpkgs.lib;
    };
  }
))
