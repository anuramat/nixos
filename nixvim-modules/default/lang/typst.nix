{ pkgs, lib, ... }:
{
  plugins = {
    typst-preview = {
      enable = true;
      # TODO requires manual setup on first launch; can be solved with the next home-manager release
      settings.open_cmd = "${lib.getExe pkgs.firefox} -P typst-preview %s";
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
