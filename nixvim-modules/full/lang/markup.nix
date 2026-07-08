{
  plugins = {
    lsp.servers = {
      jsonls.enable = true;
      yamlls.enable = true;
    };
    conform-nvim.settings.formatters_by_ft.yaml = [ "yamlfmt" ];
  };
}
