{ pkgs, inputs, ... }:
let
  # TODO nixcats or nvf
  moltenLua = ps: [
    # molten:
    ps.magick
  ];
  moltenPython =
    ps: with ps; [
      # required:
      pynvim
      jupyter-client
      # images:
      cairosvg # to display svg with transparency
      pillow # open images with :MoltenImagePopup
      pnglatex # latex formulas
      # plotly figures:
      plotly
      kaleido
      # remote molten:
      requests
      websocket-client
      # misc:
      pyperclip # clipboard support
      nbformat # jupyter import/export
      # }}}
    ];
  lsp = with pkgs; [
    rust-analyzer
    superhtml
    typescript-language-server
    stylelint-lsp # css
    haskell-language-server
    bash-language-server
    ccls
    clang-tools
    gopls
    lua-language-server
    marksman
    nil
    nodePackages_latest.vscode-json-languageserver
    pyright
    texlab
    nixd
    yaml-language-server
  ];
in
{
  imports = [ inputs.nvf.homeManagerModules.default ];
  programs = {
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
  };
  home.packages = with pkgs; [
    vscode
    vis
    zed-editor
  ];
}
# # missing:
# treesj
# ts-comments-nvim
# dressing-nvim
# undotree
# SchemaStore-nvim
# clangd_extensions-nvim
# molten-nvim
# jupytext-nvim
# quarto-nvim
# nvim-dap-virtual-text
# overseer-nvim
# grug-far-nvim
# vim-table-mode
# figtree-nvim
# mcphub-nvim
# mdmath-nvim
# namu-nvim
# wastebin-nvim
