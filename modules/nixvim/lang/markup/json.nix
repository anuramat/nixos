{ pkgs, ... }:
{
  extraPackages = with pkgs; [
    nodePackages.jsonlint
  ];
  plugins = {
    conform-nvim.settings.formatters_by_ft.json = [ ];
    lsp.servers.jsonls = {
      enable = true;
      # TODO check if this is required
      # cmd = [
      #   "vscode-json-languageserver"
      #   "--stdio"
      # ];
    };
    lint.lintersByFt.json = [
      "jsonlint"
    ];
  };
}
