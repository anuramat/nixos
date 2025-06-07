{ pkgs, inputs, ... }:
let
  inherit (inputs.nixCats) utils;
  luaPath = "${../config/nvim}";
  
  # Define categories of plugins and dependencies  
  categoryDefinitions = { pkgs, settings, categories, name, ... }: {
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
        neopywal-nvim
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
        schemastore-nvim
        
        # Language specific
        clangd_extensions-nvim
        haskell-tools-nvim
        
        # AI/LLM
        copilot-lua
        avante-nvim
        # blink-cmp-avante  # May need to be added to nixpkgs
        
        # Jupyter/Data Science
        molten-nvim
        # jupytext-nvim  # May need to be added to nixpkgs
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
        # wastebin-nvim  # Your custom plugin
        # namu-nvim  # Your custom plugin
        # mcphub-nvim  # Your custom plugin
        # mdmath-nvim  # May need to be added
        nvim-FeMaco-lua
        # figtree-nvim  # Your custom plugin
        vim-table-mode
      ];
    };

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
    };

    extraPython3Packages = {
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

    extraLuaPackages = {
      general = ps: with ps; [
        magick
      ];
    };
  };

  packageDefinitions = {
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
  };

  nixCatsBuilder = utils.baseBuilder luaPath {
    inherit (pkgs) system;
    inherit pkgs;
    nixpkgs = pkgs;
  } categoryDefinitions;

  myNeovim = nixCatsBuilder packageDefinitions.nvim;

in
{
  # Use nixcats neovim
  home.packages = [ myNeovim ];
  
  # Set as default editor
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Disable home-manager's neovim to avoid conflicts
  programs.neovim.enable = false;
  
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
}