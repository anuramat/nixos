# TODO tidy up deps
{
  nixCats,
  nixpkgs-unstable,
  ...
}:
let
  categoryDefinitions =
    {
      pkgs,
      ...
    }:
    {
      # LSP servers, formatters, linters, and other runtime dependencies
      # todo triple check
      general = with pkgs; [
        # LSP servers
        lua-language-server
        nil
        nixd
        gopls
        clang-tools
        haskell-language-server
        bash-language-server
        marksman
        nodePackages_latest.vscode-json-languageserver
        pyright
        texlab
        yaml-language-server
        superhtml
        typescript-language-server
        stylelint-lsp

        # Tools
        ripgrep
        fd
        fzf

        # Write down where this is coming from
        imagemagick
        librsvg

        # Python for Jupyter
        python3Packages.pynvim
        python3Packages.jupyter
        python3Packages.jupytext
      ];

      # Extra python packages for molten/jupyter
      python3.libraries = {
        general =
          ps: with ps; [
            # TODO mention where this is from
            cairosvg
            jupyter
            jupyter-client
            jupytext
            kaleido
            matplotlib
            nbformat
            numpy
            pandas
            pillow
            plotly
            pnglatex
            pynvim
            pyperclip
            requests
            websocket-client
          ];
      };
    };

  packageDefinitions = {
    nvim = _: {
      categories = {
        general = true;
        treesitter = true;
        git = true;
        lazy = true;
      };
    };
    nvim-minimal = _: {
      settings = {
        wrapRc = true;
      };
      categories = {
        general = true;
        treesitter = false;
        git = true;
        lazy = false;
      };
    };
  };
  buildNeovim =
    system:
    let
      nixCatsBuilder = nixCats.utils.baseBuilder "${./.}" {
        inherit system;
        nixpkgs = nixpkgs-unstable;
      } categoryDefinitions packageDefinitions;
    in
    {
      packages = builtins.mapAttrs (n: v: nixCatsBuilder n) packageDefinitions;
    };
in
(nixCats.utils.eachSystem nixpkgs-unstable.lib.platforms.all) buildNeovim

# let
#   # TODO nixcats or nvf
#   moltenLua = ps: [
#     # molten:
#     ps.magick
#   ];
#   moltenPython =
#     ps: with ps; [
#       # required:
#       pynvim
#       jupyter-client
#       # images:
#       cairosvg # to display svg with transparency
#       pillow # open images with :MoltenImagePopup
#       pnglatex # latex formulas
#       # plotly figures:
#       plotly
#       kaleido
#       # remote molten:
#       requests
#       websocket-client
#       # misc:
#       pyperclip # clipboard support
#       nbformat # jupyter import/export
#       # }}}
#     ];
#   lsp = with pkgs; [
#     rust-analyzer
#     superhtml
#     typescript-language-server
#     stylelint-lsp # css
#     haskell-language-server
#     bash-language-server
#     ccls
#     clang-tools
#     gopls
#     lua-language-server
#     marksman
#     nil
#     nodePackages_latest.vscode-json-languageserver
#     pyright
#     texlab
#     nixd
#     yaml-language-server
#   ];
# in
# # # missing:
# # treesj
# # ts-comments-nvim
# # dressing-nvim
# # undotree
# # SchemaStore-nvim
# # clangd_extensions-nvim
# # molten-nvim
# # jupytext-nvim
# # quarto-nvim
# # nvim-dap-virtual-text
# # overseer-nvim
# # grug-far-nvim
# # vim-table-mode
# # figtree-nvim
# # mcphub-nvim
# # mdmath-nvim
# # namu-nvim
# # wastebin-nvim

# vim: fdl=3
