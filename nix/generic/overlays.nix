{ inputs, ... }:
let
  unstablePackages =
    pkgs:
    builtins.listToAttrs (
      map (pkg: {
        name = pkg.pname;
        value = pkg;
      }) pkgs
    );
in
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        unstable = inputs.nixpkgs-unstable.legacyPackages.${final.system};
      in
      {
        mcp-nixos = inputs.mcp-nixos.packages.${prev.system}.default;
        neovim = inputs.neovim-nightly-overlay.packages.${prev.system}.default;
      }
      # // unstablePackages (
      #   with unstable;
      #   [
      #     ollama
      #   ]
      # )
    )
  ];
}
