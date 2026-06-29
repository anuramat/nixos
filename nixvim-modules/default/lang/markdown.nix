{ config, ... }:
{
  inherit
    (config.lib.mkVimFiles {
      markdown.ftp = {
        localOpts = {
          cc = "+1";
          shiftwidth = 0;
          tabstop = 2;
        };
        # runtime ftplugin maps gO to a TOC picker
        extraConfigLua = ''vim.keymap.del("n", "gO", { buffer = 0 })'';
      };
    })
    files
    extraFiles
    ;
  plugins.lsp.servers.marksman.enable = true;
}
