{
  inputs = {
    nixpkgs-old.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    subcat.url = "github:anuramat/subcat";
    ctrlsn.url = "git+ssh://git@github.com/anuramat/ctrl.sn?ref=main";
    mcp-nixos.url = "github:utensils/mcp-nixos";
    nil.url = "github:oxalica/nil/main";
  };
  outputs =
    inputs:
    let

      inherit (inputs.nixpkgs) lib;
      epsilon = with builtins; path: path |> readDir |> attrNames |> filter (a: a != "default.nix");
      inherit
        ((import ./os/machines) {
          inherit inputs epsilon;
        })
        hostnames
        mkCluster
        mkModules
        ;

      user = {
        username = "anuramat";
        fullname = "Arsen Nuramatov";
        email = "x@ctrl.sn";
      };
      commonArgs = {
        inherit inputs user;
        helpers = import ./helpers { inherit lib; };
      };
      mkSystem =
        name:
        let
          cluster = mkCluster name;
        in
        lib.nixosSystem {
          specialArgs = commonArgs // {
            inherit cluster;
            # {{{1
            old =
              let
                pkgscfg = inputs.self.nixosConfigurations.${name}.config.nixpkgs;
              in
              import inputs.nixpkgs-old {
                inherit (pkgscfg) config;
                inherit (pkgscfg.hostPlatform) system;
              };
            # }}}
          };
          modules =
            [
              { home-manager.users.${user.username} = import ./home; }
              ./common
              ./os/generic
            ]
            ++ mkModules name
            ++ (
              if cluster.this.server then
                [
                  ./os/remote.nix
                ]
              else
                [
                  ./os/local
                ]
            );
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
      homeConfigurations.${user.username} = inputs.home-manager.lib.homeManagerConfiguration {
        specialArgs = commonArgs;
        modules = [
          ./home
          ./common
        ];
      };
    };
}
# vim: fdl=0 fdm=marker
