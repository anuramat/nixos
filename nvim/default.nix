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

# vim: fdl=3
