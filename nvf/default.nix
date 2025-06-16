{
  lib,
  pkgs,
  myInputs,
  ...
}:
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
  ];
  vim = {
    package = myInputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
    enableLuaLoader = true;
    lazy.enable = false;
    viAlias = false;
    vimAlias = false;
    options = lib.mkForce { }; # XXX kinda works, kills some of the attributes
    luaConfigPre = # lua
      ''
        vim.cmd('source ${./base.vim}')
        vim.diagnostic.config({
          severity_sort = true,
          update_in_insert = true,
          signs = false,
        })
        vim.deprecate = function() end
      '';

    # why two?
    # treesitter.autotagHtml = true;
    # languages.html.treesitter.autotagHtml = true;

    languages = {
      clang.enable = true;
      go.enable = true;
      html.enable = true;
      lua.enable = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
      ts.enable = true;
      zig.enable = true;
    };
  };
}
