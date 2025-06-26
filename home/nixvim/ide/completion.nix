{
  plugins = {
    friendly-snippets.enable = true;
    blink-cmp = {
      enable = true;
      # TODO jesus christ that's ugly
      # luaConfig.post = ''
      #   require('blink.cmp').setup({
      #     sources = {
      #       providers = {
      #         snippets = {
      #           opts = {
      #             search_paths = { vim.fn.stdpath('data') .. '/lazy/friendly-snippets' },
      #           },
      #         },
      #       },
      #     },
      #   })
      # '';
    };
  };
}
