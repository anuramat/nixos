{ pkgs, ... }:
{
  extraPlugins = [
    # pkgs.vimPlugins.typst-term-preview-nvim
  ];
  plugins = {
    typst-preview.enable = true;
    lsp.servers.tinymist = {
      enable = true;
    };
    conform-nvim.settings = {
      formatters_by_ft.typst = [
        "typstyle"
        "injected"
      ];
    };
  };
}
