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
    ./llm.nix
  ];

  package = myInputs.neovim-nightly-overlay.packages.${pkgs.system}.neovim;
  
  viAlias = false;
  vimAlias = false;
  
  extraConfigLuaPre = ''
    vim.cmd('source ${../nvf/base.vim}')
    vim.diagnostic.config({
      severity_sort = true,
      update_in_insert = true,
      signs = false,
    })
    vim.deprecate = function() end
  '';

  plugins.lsp = {
    enable = true;
    inlayHints = true;
    servers = {
      clangd.enable = true;
      gopls.enable = true;
      html.enable = true;
      lua_ls.enable = true;
      nixd.enable = true;
      pyright.enable = true;
      rust_analyzer.enable = true;
      ts_ls.enable = true;
      zls.enable = true;
    };
  };
}