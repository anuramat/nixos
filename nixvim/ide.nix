{
  plugins = {
    conform-nvim.enable = true;
    
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
      inlayHints = true;
      onAttach = ''
        vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
          vim.lsp.diagnostic.on_publish_diagnostics, {
            update_in_insert = true,
          }
        )
      '';
    };

    dap = {
      enable = true;
      extensions.dap-ui.enable = true;
    };
  };
}