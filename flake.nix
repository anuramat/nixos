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
      epsilon =
        path: path |> builtins.readDir |> builtins.attrNames |> builtins.filter (a: a != "default.nix");

      inherit ((import ./nix/machines) { inherit inputs epsilon; })
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
            cluster = mkCluster name;
            inherit inputs;
            dummy = path: path |> epsilon |> map (name: path + /${name});
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
