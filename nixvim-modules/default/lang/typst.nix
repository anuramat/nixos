{ pkgs, ... }:
{
  extraPlugins = [
    pkgs.vimPlugins.typst-term-preview-nvim
  ];
  plugins = {
    lsp.servers.tinymist = {
      enable = true;
    };
  };
}
