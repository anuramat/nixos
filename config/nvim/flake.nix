{
  description = "anuramat's nixcats neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
  };

  outputs = { self, nixpkgs, nixCats, ... }@inputs: let
    inherit (nixCats) utils;
    luaPath = "${./.}";
    forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    
    # Define categories of plugins and dependencies
    categoryDefinitions = { pkgs, settings, categories, name, ... }: {
      # Plugins that are always loaded at startup
      startupPlugins = {
        general = with pkgs.vimPlugins; [
          plenary-nvim
          nvim-web-devicons
          nui-nvim
          oil-nvim
          vim-eunuch
          vim-fetch
          nvim-surround
          ts-comments-nvim
          lsp-format-nvim
          mini-bracketed
          # neopywal-nvim  # Not in nixpkgs
        ];
        
        treesitter = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-ts-autotag
          rainbow-delimiters-nvim
        ];
        
        git = with pkgs.vimPlugins; [
          vim-fugitive
          gitsigns-nvim
          neogit
          diffview-nvim
          gitlinker-nvim
        ];
      };

      # Plugins that can be lazy-loaded
      optionalPlugins = {
        lazy = with pkgs.vimPlugins; [
          # Core lazy loading
          lze
          
          # UI and Navigation
          aerial-nvim
          fzf-lua
          neo-tree-nvim
          harpoon2
          flash-nvim
          undotree
          
          # Completion and LSP
          blink-cmp
          nvim-lspconfig
          nvim-lightbulb
          fidget-nvim
          lazydev-nvim
          SchemaStore-nvim
          
          # Language specific
          clangd_extensions-nvim
          haskell-tools-nvim
          
          # AI/LLM
          copilot-lua
          avante-nvim
          # blink-cmp-avante  # May not be in nixpkgs yet
          
          # Jupyter/Data Science
          molten-nvim
          # jupytext-nvim  # May not be in nixpkgs yet
          otter-nvim
          quarto-nvim
          image-nvim
          
          # Debugging
          nvim-dap
          nvim-dap-ui
          nvim-dap-virtual-text
          
          # Utilities
          todo-comments-nvim
          nvim-colorizer-lua
          treesj
          mini-ai
          mini-align
          dressing-nvim
          overseer-nvim
          grug-far-nvim
          sniprun
          vim-table-mode
          nvim-FeMaco-lua
          # Custom plugins may need to be added manually
          # wastebin-nvim
          # namu-nvim
          # mcphub-nvim
          # mdmath-nvim
          # figtree-nvim
        ];
      };

      # LSP servers, formatters, linters, and other runtime dependencies
      lspsAndRuntimeDeps = {
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
          
          # Formatters
          stylua
          nixfmt-rfc-style
          
          # Other tools
          ripgrep
          fd
          fzf
          imagemagick
          librsvg
          
          # Python for Jupyter
          python3Packages.pynvim
          python3Packages.jupyter
        ];
      };

      # Environment variables and settings
      environmentVariables = {
        general = {
          NVIM_CONFIG_TYPE = "nixcats";
        };
      };

      # Extra lua packages
      extraLuaPackages = {
        general = ps: with ps; [
          magick
        ];
      };

      # Extra python packages for molten/jupyter
      python3.libraries = {
        general = ps: with ps; [
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
          matplotlib
          numpy
          pandas
        ];
      };
    };

    # Define different package configurations
    packageDefinitions = {
      # Full configuration with all features
      nvim = { pkgs, ... }: {
        settings = {
          wrapRc = true;
          configDirName = "nvim";
        };
        categories = {
          general = true;
          treesitter = true;
          git = true;
          lazy = true;
        };
      };

      # Minimal configuration for servers
      nvim-minimal = { pkgs, ... }: {
        settings = {
          wrapRc = true;
          configDirName = "nvim";
        };
        categories = {
          general = true;
          treesitter = false;
          git = true;
          lazy = false;
        };
      };
    };

  in
  forEachSystem (system: let
    dependencyOverlays = [ ];
    pkgs = import nixpkgs { 
      inherit system; 
      config.allowUnfree = true;
      overlays = dependencyOverlays;
    };
    nixCatsBuilder = utils.baseBuilder luaPath {
      inherit nixpkgs system dependencyOverlays;
      extra_pkg_config = {
        allowUnfree = true;
      };
    } categoryDefinitions packageDefinitions;
    
    defaultCats = nixCatsBuilder "nvim";
    
  in {
    packages = {
      default = defaultCats;
      nvim = defaultCats;
      nvim-minimal = nixCatsBuilder "nvim-minimal";
    };
    
    # Development shell for working on the config
    devShells.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        lua-language-server
        stylua
        luajitPackages.luacheck
      ];
    };
  });
}