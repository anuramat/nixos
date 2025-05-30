{
  inputs,
  pkgs,
  ...
}:
let

  # TODO move to helpers
  # HACK here we pepegapray that the pname and attrname in nixpkgs are equal (I think it's not true for neovim for example, pname is neovim-unwrapped or something)
  mkUnstablePackages =
    pkgfunc: final: prev:
    let
      unstable = import inputs.nixpkgs-unstable { inherit (prev) config system; };
    in
    prev.lib.listToAttrs (
      map (pkg: {
        name = pkg.pname; # BUG this fucking line ruined my entire day
        value = pkg;
      }) (pkgfunc unstable)
    );
  # # Intended usage:
  # unstablePackages = mkUnstablePackages (
  #   unstable: with unstable; [
  #   ]
  # );
  unwrapOverlays = map (input: input.overlays.default);
  unwrapPackages = (
    inputs: final: prev:
    map (
      input:
      let
        pkg = input.packages.${prev.system}.default;
      in
      {
        name = pkg.pname;
        value = pkg;
      }
    ) inputs
    |> builtins.listToAttrs
  );
  # ------------------- end of helpers

  unstablePackages = final: prev: {
    inherit (import inputs.nixpkgs-unstable { inherit (pkgs) config system; })
      cheese
      foot
      ghostty
      github-mcp-server
      keymapp
      nixd
      tgpt
      wallust
      wezterm
      xdg-desktop-portal-termfilechooser # not in stable yet
      xdg-ninja
      yazi
      ;
  };
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
