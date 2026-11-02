{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        {
          pkgs,
          system,
          config,
          ...
        }:
        let
          fenixPkgs = inputs.fenix.packages.${system};
          inherit (fenixPkgs.stable) rustfmt;
          # nightly rustfmt, for unstable options in rustfmt.toml:
          # inherit (fenixPkgs.latest) rustfmt;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain (
            _: # crane passes pkgs, which we don't need
            fenixPkgs.combine [
              fenixPkgs.stable.rustc
              fenixPkgs.stable.cargo
            ]
          );
          commonArgs = {
            src = craneLib.cleanCargoSource ./.;
            strictDeps = true;
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        in
        {
          packages.default = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });
          devShells.default = pkgs.mkShell {
            inherit (config.pre-commit) shellHook;
            packages = [
              (fenixPkgs.stable.withComponents [
                "cargo"
                "clippy"
                "rust-src"
                "rust-analyzer"
                "rustc"
              ])
              rustfmt
              pkgs.cargo-insta
            ];
          };
          pre-commit = {
            check.enable = false; # otherwise we duplicate the treefmt check
            settings.hooks.treefmt.enable = true;
          };
          treefmt = {
            settings.formatter.tombi = {
              command = pkgs.lib.getExe pkgs.tombi;
              options = [
                "format"
                "--offline"
                "--"
              ];
              includes = [ "*.toml" ];
            };
            programs = {
              nixfmt.enable = true;
              rustfmt = {
                enable = true;
                package = rustfmt;
              };
            };
          };
        };
    };
}
