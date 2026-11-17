{ pkgs, lib, ... }:
{
  autoCmd = [
    {
      # NOTE autocmd because after/ftplugin is too early
      event = "FileType";
      pattern = "typst";
      command = "setlocal indentexpr= formatoptions+=n";
    }
  ];
  # equations as inline images; replaces the math rendering of snacks (image.nix)
  extraPlugins = [ pkgs.vimPlugins.typst-eq-nvim ];
  extraConfigLua = ''require("typst-eq").setup({ match_colors = true })'';
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
