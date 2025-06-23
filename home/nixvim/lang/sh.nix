{ hax, config, ... }:
{
  files = hax.vim.files.ftp {
    sh = {
      ts = 4;
      et = false;
      fo = config.opts.formatoptions;
    };
  };
  plugins.lsp.servers.bashls = {
    enable = true;
    settings = {
      bashIde = {
        shfmt = {
          binaryNextLine = true;
          caseIndent = true;
          simplifyCode = true;
          spaceRedirects = true;
        };
      };
    };
  };
}
