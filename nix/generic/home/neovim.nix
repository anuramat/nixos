{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    package = pkgs.neovim;
    extraLuaPackages = ps: [
      # molten:
      ps.magick
    ];
    extraPackages = with pkgs; [
      # molten:
      imagemagick
      python3Packages.jupytext
      # mdmath.nvim
      librsvg
      # mcp
      github-mcp-server
      mcp-nixos
    ];
    extraPython3Packages =
      ps: with ps; [
        # molten {{{1
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
        # for remote molten:
        requests
        websocket-client
        # misc:
        pyperclip # clipboard support
        nbformat # jupyter import/export
        # }}}
      ];
  };
}
