{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    wallust.url = "git+https://codeberg.org/explosion-mental/wallust?ref=master";
  };
  outputs =
    inputs:

    let
      u = import ./nix/utils.nix;
      inherit ((import ./nix/machines) { inherit u inputs; })
        hostnames
        mkCluster
        mkModules
        ;

      mkSystem =
        name:
        let
          pkgscfg = inputs.self.nixosConfigurations.${name}.config.nixpkgs;
        in
        inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            user = (import ./nix/user.nix);
            machines = mkCluster name;
            inherit
              inputs
              u
              ;
            unstable = import inputs.nixpkgs-unstable {
              inherit (pkgscfg) config;
              inherit (pkgscfg.hostPlatform) system;
            };
          };

          modules = mkModules name ++ [
            ./nix/common
          ];
        };
    in
    {
      nixosConfigurations =
        hostnames
        |> map (name: {
          inherit name;
          value = mkSystem name;
        })
        |> builtins.listToAttrs;
    };
}
