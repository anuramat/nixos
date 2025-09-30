{ pkgs, ... }:
{
  extraPlugins = [
    # pkgs.vimPlugins.typst-term-preview-nvim
  ];
  plugins = {
    typst-preview = {
      enable = true;
      settings.open_cmd =
        let
          firefoxWrapper = pkgs.writeShellScript "firefox-typst-preview" ''
            nohup ${pkgs.firefox}/bin/firefox --new-window "$1" &>/dev/null
          '';
        in
        "${firefoxWrapper} %s";
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
