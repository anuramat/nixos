{ pkgs, lib, ... }:
{
  plugins = {
    typst-preview = {
      enable = true;
      settings = {
        open_cmd = "${lib.getExe pkgs.chromium} --app=%s";
        invert_colors = "auto";
      };
    };
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
