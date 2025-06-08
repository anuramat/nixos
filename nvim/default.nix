{
  nixCats,
  ...
}@inputs:
let
  inherit (inputs.nixCats) utils;
  nixpkgs = inputs.nixpkgs-unstable;
  luaPath = "${./.}";
  forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;

  # Define categories of plugins and dependencies
  categoryDefinitions =
    {
      pkgs,
      settings,
      categories,
      name,
      ...
    }:
    {
      # Plugins that are always loaded at startup
      startupPlugins = {
        general = with pkgs.vimPlugins; [
          lsp-format-nvim
          lze
          mini-bracketed
          nui-nvim
          nvim-surround
          nvim-web-devicons
          oil-nvim
          plenary-nvim
          ts-comments-nvim
          vim-eunuch
          vim-fetch
        ];

        treesitter = with pkgs.vimPlugins; [
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter.withAllGrammars
          nvim-ts-autotag
          rainbow-delimiters-nvim
        ];

        git = with pkgs.vimPlugins; [
          diffview-nvim
          gitlinker-nvim
          gitsigns-nvim
          neogit
          vim-fugitive
        ];
      };

      extraLuaPackages = {
        general =
          ps: with ps; [
            magick
          ];
      };
      extraPython3Packages = {
        general =
          ps: with ps; [
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
          nvim-FeMaco-lua
          vim-table-mode
          # figtree-nvim
          # mcphub-nvim
          # mdmath-nvim
          # namu-nvim
          # wastebin-nvim
        ];
      };

      # LSP servers, formatters, linters, and other runtime dependencies
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

        # Tools
        ripgrep
        fd
        fzf
        imagemagick
        librsvg

        # Python for Jupyter
        python3Packages.pynvim
        python3Packages.jupyter
        python3Packages.jupytext
      ];

      # Environment variables and settings
      environmentVariables = {
        general = {
          NVIM_CONFIG_TYPE = "nixcats";
        };
      };

      # Extra python packages for molten/jupyter
      python3.libraries = {
        general =
          ps: with ps; [
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
    nvim =
      { pkgs, ... }:
      {
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
    nvim-minimal =
      { pkgs, ... }:
      {
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

  buildNeovim =
    system:
    let
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
    in
    {
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
    };
in
forEachSystem buildNeovim
