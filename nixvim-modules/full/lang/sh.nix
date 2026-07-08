{ config, ... }:
{
  inherit
    (config.lib.mkVimFiles {
      sh = {
        ftp = {
          ts = 4;
          et = false;
        };
        snippets.loop = {
          body = [
            "while IFS= read -r -d '' $1; do"
            "$0"
            "done"
          ];
          prefix = "loop";
        };
      };
    })
    files
    extraFiles
    ;
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
