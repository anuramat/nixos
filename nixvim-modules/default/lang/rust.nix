{
  plugins = {
    crates.enable = true;
    rustaceanvim = {
      enable = true;
      settings.server = {
        default_settings = {
          "rust-analyzer" = {
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

  extraFiles."after/ftplugin/rust.lua".text =
    let
      fold_tests_by_default = # lua
        ''
          vim.schedule(function()
            local ok, parser = pcall(vim.treesitter.get_parser, 0, "rust")
            if not ok or not parser then return end
            local query = vim.treesitter.query.parse(
              "rust",
              [[
                (
                  (attribute_item (attribute
                      (identifier) @_cfg
                      arguments: (token_tree (identifier) @_test)
                  ))
                  .
                  (_) @target

                  (#eq? @_cfg "cfg")
                  (#eq? @_test "test")
                )
              ]]
            )
            local root = parser:parse()[1]:root()
            for id, node in query:iter_captures(root, 0) do
              if query.captures[id] == "target" then
                local row = node:range() + 2
                pcall(vim.cmd, row .. "foldclose")
              end
            end
          end)
        '';
    in
    fold_tests_by_default;

}
