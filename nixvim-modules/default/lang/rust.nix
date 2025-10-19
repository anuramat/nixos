{
  pkgs,
  ...
}:
{
  extraPackages = with pkgs; [
    clippy
    rustfmt
  ];
  plugins = {
    lint.lintersByFt.rust = [ "clippy" ];
    conform-nvim.settings.formatters_by_ft.rust = [
      "rustfmt"
    ];
    lsp.servers = {
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
        # packageFallback = true;
        # TODO on 25.11, uncomment, remove lines install.*false, enable cargo in packages
      };
    };
  };
}
