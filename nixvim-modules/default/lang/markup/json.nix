{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    nodePackages.jsonlint
  ];
  plugins = {
    lsp.servers.jsonls.enable = true;
    lint.lintersByFt.json = [
      "jsonlint"
    ];
  };
}
