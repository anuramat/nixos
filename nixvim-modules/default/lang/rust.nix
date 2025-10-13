{
  pkgs,
  ...
}:
{
  extraPackages = with pkgs; [
    clippy
  ];
  plugins = {
    lint.lintersByFt.rust = [ "clippy" ];
    lsp.servers = {
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
    };
  };
}
