{ hax, config, ... }:
{
  files = hax.vim.files {
    lua.ftp.fo = config.opts.formatoptions; # TODO why do we do this again? see sh.nix and misc.nix
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
