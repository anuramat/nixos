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
        ./system

        ./common/overlays.nix

        inputs.agenix.nixosModules.default
        ./secrets/age.nix
        inputs.stylix.nixosModules.stylix
        ./common/stylix.nix

        ./hosts/external_keys.nix

        inputs.musnix.nixosModules.musnix

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
    # TODO check if this even builds
    specialArgs = args;
    modules = [
      ./home

      ./common/overlays.nix
      inputs.stylix.nixosModules.stylix # TODO should be a different module -- hm specific
      inputs.agenix.homeManagerModules.default
      ./common/stylix.nix
      ./secrets/age.nix
    ];
  };
}
// (flake-utils.lib.eachDefaultSystem (system: {
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
}))
