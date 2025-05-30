{ inputs, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      mcp-nixos = inputs.mcp-nixos.packages.${prev.system}.default;
      neovim = inputs.neovim-nightly-overlay.packages.${prev.system}.default;
    })
  ];
}
