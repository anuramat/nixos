{ inputs, pkgs, ... }:
{
  programs.spicetify = {
    enable = true;
    enabledExtensions =
      let
        spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
      in
      with spicePkgs.extensions;
      [
        shuffle
        hidePodcasts
      ];
  };
}
