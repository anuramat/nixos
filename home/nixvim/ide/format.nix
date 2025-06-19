{
  plugins.conform-nvim = {
    enable = true;
    settings = {
      format_on_save = {
        # lsp_format = "fallback";
      };
      formatters_by_ft = {
        yaml = "yamlfmt";
        markdown = "mdformat";
      };
    };
  };
}
