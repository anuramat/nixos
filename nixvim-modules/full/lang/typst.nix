{ pkgs, lib, ... }:
{
  extraPackages = [ pkgs.typstyle ];
  plugins = {
    typst-preview = {
      enable = true;
      settings = {
        invert_colors = "auto";
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        open_cmd = "${lib.getExe pkgs.chromium} --app=%s";
      };
    };
    lsp.servers.tinymist.enable = true;
    conform-nvim.settings = {
      formatters_by_ft.typst = [
        "typstyle"
        "injected"
      ];
    };
  };
}
