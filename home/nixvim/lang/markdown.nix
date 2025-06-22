{
  plugins = {
    lsp.servers.marksman.enable = true;
    conform-nvim.settings = {
      formatters_by_ft.markdown = [ "mdformat" ];
      formatters = {
        mdformat = {
          args = [ "--number" ];
        };
      };
    };
  };
}
