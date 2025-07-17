{ hax, config, ... }:
let
  ftp = hax.vim.files.ftp {
    sh = {
      ts = 4;
      et = false;
      fo = config.opts.formatoptions;
    };
  };
  snippets = hax.vim.files.snippets {
    sh = {
      loop = {
        body = [
          "while IFS= read -r -d '' $1; do"
          "$0"
          "done"
        ];
        prefix = "loop";
      };
    };
  };
in
{
  files = ftp;
  extraFiles = snippets;
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
