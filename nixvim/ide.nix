{
  plugins = {
  nvim-lightbulb.enable = true;
    conform-nvim = {enable = true;
    settings.format_on_save = {lsp_format = "fallback";};};
    blink-cmp = {
      enable = true;
      luaConfig.post = ''
        require('blink.cmp').setup({
          sources = {
            providers = {
              snippets = {
                opts = {
                  search_paths = { vim.fn.stdpath("data") .. "/lazy/friendly-snippets" }
                }
              }
            }
          }
        })
      '';
    };

    lsp = {
      enable = true;
      onAttach = ''
        vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
          vim.lsp.diagnostic.on_publish_diagnostics, {
            update_in_insert = true,
          }
        )
      '';
    };

    dap.enable = true;
    dap-ui.enable = true;
  };
}
