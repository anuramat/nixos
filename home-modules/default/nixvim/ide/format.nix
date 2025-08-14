{
  # the only formatter I know that can do injection formatting
  plugins.conform-nvim = {
    enable = true;
    settings = {
      format_on_save = {
        lsp_format = "fallback";
      };
    };
  };
}
