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
  imports = [ inputs.nvf.nixosModules.default ];
  programs = {
    programs.nvf = {
      enable = true;
      settings = {
        vim = {

          filetree.neo-tree.enable = true;

          mini.ai.enable = true;
          treesitter.context.enable = true;
          treesitter.textobjects.enable = true;

          # why two?
          # treesitter.autotagHtml = true;
          # languages.html.treesitter.autotagHtml = true;
          visuals.rainbow-delimiters.enable = true;
          utility.diffview-nvim.enable = true;
          git.gitlinker-nvim.enable = true;
          git.gitsigns.enable = true;
          git.vim-fugitive.enable = true;

          utility.oil-nvim.enable = true;
          utility.surround.enable = true;
          mini.bracketed.enable = true;
          lazy.enable = true;
          fzf-lua.enable = true;
          formatter.conform-nvim.enable = true;
          mini.align.enable = true;
          notes.todo-comments.enable = true;
          ui.colorizer.enable = true;
          visuals.fidget-nvim.enable = true;

          languages = {
            haskell.enable = true;
          };

          autocomplete.blink-cmp = {
            enable = true;
            friendly-snippets.enable = true;
          };

          lsp = {
            enable = true;
            lspconfig.enable = true;
            lightbulb.enable = true;
            otter-nvim.enable = true;
          };

          utility = {
            images.image-nvim.enable = true;
            outline.aerial-nvim.enable = true;
          };

          debugger.nvim-dap = {
            enable = true;
            ui.enable = true;
          };

          assistant = {
            avante-nvim.enable = true;
            copilot.enable = true;
          };

          viAlias = false;
          vimAlias = false;
        };
      };
    };
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
