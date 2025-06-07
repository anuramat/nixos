{
  description = "anuramat's nixcats neovim configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    # Optional: pin specific plugin versions
    # lze = {
    #   url = "github:BirdeeHub/lze";
    #   flake = false;
    # };
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
          # Core dependencies that need to be loaded early
          plenary-nvim
          nvim-web-devicons
          nui-nvim
          
          # Essential plugins that should always be available
          oil-nvim
          vim-eunuch
          vim-fetch
          nvim-surround
          ts-comments-nvim
          lsp-format-nvim
          mini-bracketed
          
          # Theming
          neopywal-nvim
        ];
        
        treesitter = with pkgs.vimPlugins; [
          nvim-treesitter
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
          schemastore-nvim
          
          # Language specific
          clangd_extensions-nvim
          haskell-tools-nvim
          
          # AI/LLM
          copilot-lua
          avante-nvim
          blink-cmp-avante
          
          # Jupyter/Data Science
          molten-nvim
          jupytext-nvim
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
          wastebin-nvim
          namu-nvim
          mcphub-nvim
          mdmath-nvim
          nvim-FeMaco-lua
          figtree-nvim
          vim-table-mode
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
          
          # Formatters
          stylua
          nixfmt-rfc-style
          
          # Other tools
          ripgrep
          fd
          fzf
          
          # Python stuff for Jupyter
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

      # Extra lua packages that might be needed
      extraLuaPackages = {
        general = [ ];
      };

      # Extra python packages for molten/jupyter
      extraPython3Packages = {
        general = ps: with ps; [
          pynvim
          jupyter
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
          # Add extra runtime paths if needed
          # extraRcLua = ''
          #   -- Extra Lua configuration
          # '';
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
    inherit (utils) baseBuilder;
    pkgs = import nixpkgs { 
      inherit system; 
      config.allowUnfree = true;
    };
    nixCatsBuilder = baseBuilder luaPath {
      inherit nixpkgs system;
      extra_pkg_config = {
        allowUnfree = true;
      };
    } categoryDefinitions;
    
  in {
    packages = utils.mkPackages nixpkgs inputs categoryDefinitions packageDefinitions "nvim" system;
    
    # Default package
    defaultPackage = nixCatsBuilder packageDefinitions.nvim;
    
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