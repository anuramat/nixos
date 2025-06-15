{
  vim = {
    formatter.conform-nvim.enable = true;

    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
    };

    lsp = {
      enable = true;
      inlayHints.enable = true;
      lspconfig.enable = true;
      formatOnSave = true;
      lightbulb.enable = true;
    };

    debugger.nvim-dap = {
      # XXX report broken key descriptions
      enable = true;
      ui.enable = true;
    };
  };
}
