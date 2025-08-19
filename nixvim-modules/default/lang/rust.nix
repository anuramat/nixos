{
  hax,
  config,
  pkgs,
  ...
}:
{
  extraPackages = with pkgs; [
  ];
  plugins = {
    lint.lintersByFt = {
    };

    lsp.servers = {
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
    };
  };
}
