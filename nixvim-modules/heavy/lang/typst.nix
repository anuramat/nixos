{ pkgs, lib, ... }:
{
  extraPackages = [ pkgs.typstyle ];
  autoCmd = [
    {
      # NOTE autocmd because after/ftplugin is too early
      event = "FileType";
      pattern = "typst";
      command = "setlocal indentexpr= formatoptions+=n";
    }
  ];
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
