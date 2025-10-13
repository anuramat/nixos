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
    rustaceanvim = {
      enable = true;
    };
    # lsp.servers = {
    #   rust_analyzer = {
    #     enable = true;
    #     installCargo = false;
    #     installRustc = false;
    #   };
    # };
  };
}
