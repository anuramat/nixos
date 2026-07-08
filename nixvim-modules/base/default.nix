{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.self.sharedModules.nixpkgs
    ./basic.nix
    ./editing.nix
    ./treesitter.nix
    ./ui.nix
    ./lib.nix
  ];

  extraPlugins = [
    pkgs.vimPlugins.tinted-nvim
  ];
  luaLoader.enable = true;
}
