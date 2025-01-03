{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
  };
  outputs =
    inputs:
    let
      machineDir = ./nix/machines;
      hostnames =
        machineDir |> builtins.readDir |> builtins.attrNames |> builtins.filter (x: x != "user.nix");

      system =
        name:
        let
          user = (import ./nix/machines/user.nix) {
            inherit hostnames;
            hostname = name;
            lib = inputs.nixpkgs.lib;
          };
        in
        {
          inherit name;
          value = inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit inputs user;
              dummy = import ./nix/dummy.nix;
              unstable = import inputs.nixpkgs-unstable {
                config = {
                  allowUnfree = true; # try recursive
                };
                system = user.this.platform;
              };
            };

            modules = [
              (machineDir + /${name})
              ./nix/common
            ];
          };
        };
    in
    {
      nixosConfigurations = builtins.listToAttrs (map system hostnames);
    };
}
