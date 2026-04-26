{
  plugins = {
    # NOTE clippy and cargofmt already in somehow
    crates = {
      enable = true;
    };
    rustaceanvim = {
      enable = true;
      settings.server = {
        default_settings = {
          rust_analyzer = {
            references = {
              excludeTests = true;
              excludeImports = true;
            };
          };
        };
        on_attach.__raw = ''
          function(client, bufnr)
            local opts = { noremap = true, silent = true, buffer = bufnr }
            vim.keymap.set('n', '<c-space>', function() require('tree_climber_rust').init_selection() end, opts)
            vim.keymap.set('x', '<c-space>', function() require('tree_climber_rust').select_incremental() end, opts)
            vim.keymap.set('x', '<c-bs>', function() require('tree_climber_rust').select_previous() end, opts)
          end
        '';
      };
    };
  };
}
