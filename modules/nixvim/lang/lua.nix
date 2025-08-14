{ hax, config, ... }:
{
  files = hax.vim.files.ftp {
    lua = {
      fo = config.opts.formatoptions;
    };
  };

  plugins = {
    conform-nvim.settings.formatters_by_ft.lua = [ "stylua" ];

    lsp.servers.lua_ls = {
      enable = true;
      settings = {
        Lua = {
          format = {
            enable = false;
          };
          runtime = {
            version = "LuaJIT";
          };
          telemetry = {
            enable = false;
          };
        };
      };
    };
  };
}
