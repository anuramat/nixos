{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    hadolint
  ];
  plugins = {
    lint.lintersByFt = {
      dockerfile = [
        "hadolint"
      ];
    };

    plugins.lsp.servers = {
      clangd.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      zls.enable = true;
    };
  };
}
