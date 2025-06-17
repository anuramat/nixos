{
  plugins.blink-cmp = {
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
}
