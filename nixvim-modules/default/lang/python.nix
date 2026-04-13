{
  plugins = {
    conform-nvim.settings.formatters_by_ft.python = [
      "ruff_fix"
      "ruff_format"
      "ruff_organize_imports"
    ];
    lsp.servers = {
      ruff.enable = true;
      pyright.enable = true;
    };
  };
}
