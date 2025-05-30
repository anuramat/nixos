{
  inputs,
  helpers,
  ...
}:
with helpers.overlays;
let
  unstablePackages = mkUnstablePackages (
    unstable: with unstable; [
      github-mcp-server
      keymapp
      cheese
      nixd
      xdg-ninja
      yazi
      tgpt
      wallust
      xdg-desktop-portal-termfilechooser
      foot
      yazi
      foot
      ghostty
      wezterm
    ]
  );
  overlays = unwrapOverlays (
    with inputs;
    [
      neovim-nightly-overlay
    ]
  );
  manual = import ./manual.nix { };
in
{
  nixpkgs.overlays = overlays ++ [
    manual
    unstablePackages
    (final: prev: {
      mcp-nixos = inputs.mcp-nixos.packages.${prev.system}.default;
    })
  ];
}
