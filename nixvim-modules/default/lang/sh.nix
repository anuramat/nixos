{ hax, config, ... }:
let
  ftp = hax.vim.files {
    sh = {
      ftp = {
        ts = 4;
        et = false;
        fo = config.opts.formatoptions; # TODO why do we do this again? see lua.nix
      };
    };
  };
  snippets = hax.vim.files {
    sh = {
      snippets = {
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
  };
in
{
  files = ftp;
  extraFiles = snippets;
  plugins = {
    conform-nvim.settings = {
      formatters = {
        shfmt = {
          "inherit" = true;
          prepend_args = [
            "--binary-next-line"
            "--case-indent"
            "--simplify"
          ];
        };
      };
      formatters_by_ft.sh = [
        "shfmt"
      ];
    };
    lsp.servers.bashls = {
      enable = true;
      settings.bashIde.shfmt = {
        binaryNextLine = true;
        caseIndent = true;
        simplifyCode = true;
      };
    };
  };
}
