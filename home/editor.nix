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
    programs.nvf = {
      enable = true;
      settings = {
        vim = {
          # why two?
          # treesitter.autotagHtml = true;
          # languages.html.treesitter.autotagHtml = true;

          git = {
            gitlinker-nvim.enable = true;
            gitsigns.enable = true;
            vim-fugitive.enable = true;
          };

          filetree.neo-tree.enable = true;
          formatter.conform-nvim.enable = true;
          fzf-lua.enable = true;
          lazy.enable = true;
          notes.todo-comments.enable = true;
          ui.colorizer.enable = true;

          mini = {
            ai.enable = true;
            align.enable = true;
            bracketed.enable = true;
          };
          treesitter = {
            context.enable = true;
            textobjects.enable = true;
          };
          utility = {
            images.image-nvim.enable = true;
            outline.aerial-nvim.enable = true;
            diffview-nvim.enable = true;
            oil-nvim.enable = true;
            surround.enable = true;
          };
          visuals = {
            fidget-nvim.enable = true;
            rainbow-delimiters.enable = true;
          };

          languages = {
            haskell.enable = true;
            nix.enable = true;
            python.enable = true;
            lua.enable = true;
            markdown.enable = true;

            go.enable = true;
            bash.enable = true;
            json.enable = true;
            yalm.enable = true;
            html.enable = true;
            clang.enable = true;

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
      enable = false;
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
