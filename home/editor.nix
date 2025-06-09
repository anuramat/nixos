{ pkgs, ... }:
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
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      extraLuaPackages = moltenLua;
      extraPackages =
        with pkgs;
        [
          # molten:
          imagemagick
          python3Packages.jupytext
          # mdmath.nvim
          librsvg
        ]
        ++ lsp;
      extraPython3Packages = moltenPython;
    };
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
    vscode = {
      enable = true;
    };
  };
  home.packages = with pkgs; [
    vis
    windsurf
    code-cursor
    zed-editor
  ];
}
