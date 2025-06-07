{ pkgs, inputs, ... }:
let
  nixCats-nvim = inputs.nixCats-nvim;
  # TODO nixcats or nvf
  # moltenLua, moltenPython, and lsp vars will be removed/commented out.
in
{
  programs = {
    # neovim = {
    #   enable = true;
    #   defaultEditor = true;
    #   extraLuaPackages = moltenLua;
    #   extraPackages =
    #     with pkgs;
    #     [
    #       # molten:
    #       imagemagick
    #       python3Packages.jupytext
    #       # mdmath.nvim
    #       librsvg
    #     ]
    #     ++ lsp;
    #   extraPython3Packages = moltenPython;
    # };
    helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
        };
      };
    };
    # vscode = {
    #   enable = true;
    # };
  };
  nixCats-nvim.packages.${pkgs.system}.default = {
    # Enable the NixCats module for home-manager
    hm = {
      enable = true; # This is where you'd enable it for home-manager
      # Other home-manager specific options if needed
    };
    # Define plugin categories
    categoryDefinitions = { pkgs, ... }: {
      # Example categories, these will be populated in the next step
      startupPlugins = with pkgs.vimPlugins; {
        adapters = [
          nvim-treesitter # lazy = false
        ];
        lang = [
          jupytext-nvim # lazy = false
        ];
        core = [
          lsp-format-nvim
          mini-bracketed
          vim-fetch
          oil-nvim
          plenary-nvim
          nvim-web-devicons
          figtree-nvim
        ]; # For core plugins that should always load
      };
      optionalPlugins = with pkgs.vimPlugins; {
        core = [
          aerial-nvim
          vim-sleuth
          nvim-surround
          ts-comments-nvim
          vim-eunuch
          undotree
          fzf-lua
          neo-tree-nvim
          treesj
          mini-align
          flash-nvim
          wastebin-nvim
          neogit
          vim-fugitive
          gitsigns-nvim
          diffview-nvim
          gitlinker-nvim
          image-nvim
          grug-far-nvim
          overseer-nvim
          sniprun
          harpoon
          namu-nvim
          rainbow-delimiters-nvim
          dressing-nvim
          nvim-colorizer-lua
          todo-comments-nvim
          nvim-lightbulb
          fidget-nvim
        ];
        ui = []; # For UI related plugins
        lsp = []; # For LSP and related plugins
        treesitter = []; # For Treesitter and related plugins
        # lang = []; -- old lang category, replaced by optionalPlugins.lang and startupPlugins.lang
        adapters = [
          blink-cmp
          nvim-dap
          nvim-dap-virtual-text
          nvim-dap-ui
          nvim-nio
          copilot-lua
          avante-nvim
          blink-cmp-avante
          nui-nvim
          mcphub-nvim
          nvim-lspconfig
          schemastore-nvim
          none-ls-nvim
          # nvim-treesitter moved to startupPlugins.adapters
          nvim-treesitter-textobjects
          nvim-treesitter-context
          mini-ai
        ];
        lang = [
          clangd_extensions-nvim
          haskell-tools-nvim
          nvim-ts-autotag
          # jupytext-nvim moved to startupPlugins.lang
          (molten-nvim.override { lua = with pkgs.luaPackages; [ magick ]; })
          quarto-nvim
          otter-nvim
          lazydev-nvim
          vim-table-mode
          nvim-femaco-lua
          mdmath-nvim
        ];
      };
      # Add other categories as needed, e.g., for completion, dap, etc.
    };
    # Define the Neovim package itself
    packageDefinitions = {
      nvim = { pkgs, ... }: {
        # Settings for this specific neovim package
        settings = {
          # Lua settings can be passed here if needed
          # For example: mySetting = "hello from Nix";
        };
        # Enable categories for this package
        categories = {
          core = true;
          ui = true;
          lsp = true;
          treesitter = true;
          # lang = true; -- old lang category
          adapters = true;
          lang = true; # new lang category for optional lang plugins
          # "startup_adapters" = true; -- Removed, startup plugins are not enabled this way
          # "startup_lang" = true; -- Removed, startup plugins are not enabled this way
          # Enable other categories here
        };
        # Wrapper settings if you need to add environment variables or wrap scripts
        wrapper = {
          # Example: makeWrapperArgs = ["--set FOO BAR"];
        };
        # Runtime dependencies (LSPs, formatters, etc.)
        lspsAndRuntimeDeps = { pkgs, ... }: {
          lspServers = with pkgs; [
            superhtml
            typescript-language-server
            stylelint-lsp
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
          pythonDeps = with pkgs.python3Packages; [
            pynvim
            jupyter-client
            cairosvg
            pillow
            pnglatex
            plotly
            kaleido
            requests
            websocket-client
            pyperclip
            nbformat
            jupytext # from old extraPackages
          ];
          miscDeps = with pkgs; [
            imagemagick # from old extraPackages
            librsvg # from old extraPackages
          ];
        };
      };
    };
    # Path to your existing Neovim configuration directory
    luaConfigDir = ../config/nvim; # This tells NixCats where your Lua config is
    # Set wrapRc to true if you want NixCats to manage the init.lua
    # Set to false if your init.lua is managed elsewhere or you want to call nixCats#addLuaConfigDirToRuntimePath() manually
    wrapRc = true; # Let NixCats manage the runtime path additions
  };
  # home.packages = with pkgs; [
    # code-cursor
    # windsurf
  # ];
}
