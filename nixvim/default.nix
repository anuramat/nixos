# TODO mdmath figtree
{
  pkgs,
  inputs,
  ...
}:
let
  inherit (builtins) readFile;
in
{
  imports = [
    ./files.nix
    ./fzf.nix
    ./git.nix
    ./ide.nix
    ./markdown.nix
    ./misc.nix
    ./treesitter.nix
    ./ui.nix
    ./vimim.nix
    ./llm.nix
  ];

  extraConfigVim = readFile ./base.vim;

  package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;

  luaLoader.enable = true;
  plugins.lz-n.enable = true;
  filetype = { }; # move rtp stuff
  diagnostic.settings = {
    severity_sort = true;
    update_in_insert = true;
    signs = false;
  };

  viAlias = false;
  vimAlias = false;
}
