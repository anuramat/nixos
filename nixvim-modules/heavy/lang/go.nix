{ config, ... }:
{
  inherit
    (config.lib.mkVimFiles {
      go.ftp.ts = 4;
    })
    files
    extraFiles
    ;
  plugins.lsp.servers.gopls = {
    enable = true;
    settings = {
      gopls = {
        analyses.shadow = true;
        gofumpt = true;
        semanticTokens = true;
        staticcheck = true;
        usePlaceholders = true;
      };
    };
  };
}
