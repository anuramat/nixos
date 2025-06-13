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
      startupPlugins = with pkgs.vimPlugins; {
        general = [
          base16-nvim
          lsp-format-nvim # todo replace conform
          lze
          mini-bracketed
          nvim-surround
          oil-nvim
        ];

        treesitter = [
          mini-ai
          nvim-treesitter-context
          nvim-treesitter-textobjects
          nvim-treesitter.withAllGrammars
          nvim-ts-autotag
          rainbow-delimiters-nvim
          treesj
          ts-comments-nvim
        ];

        git = [
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

      # Plugins that can be lazy-loaded
      optionalPlugins = {
        lazy = with pkgs.vimPlugins; [
          # UI and Navigation
          dressing-nvim
          undotree

          # Completion and LSP
          SchemaStore-nvim

          # Language specific
          clangd_extensions-nvim

          # AI

          # Jupyter
          molten-nvim
          jupytext-nvim
          quarto-nvim

          # Debugging
          nvim-dap-virtual-text

          # Utilities
          overseer-nvim
          grug-far-nvim
          vim-table-mode

          # # Not there yet
          # figtree-nvim
          # mcphub-nvim
          # mdmath-nvim
          # namu-nvim
          # wastebin-nvim
        ];
      };

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

# vim: fdl=3
