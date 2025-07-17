{ pkgs, hax, ... }:
let
  injections = hax.vim.files.injections {
    markdown = # query
      ''
        ;; extends

        (fenced_code_block (code_fence_content) @code_block.inner) @code_block.outer
      '';
  };
  ftp = hax.vim.files.ftp {
    markdown = {
      cc = "+1";
      shiftwidth = 0;
      tabstop = 2;
      # TODO unmap gO
    };
  };
  snippets = hax.vim.files.snippets {
    markdown = {
      aligned = {
        body = [
          "\\$\\$"
          "\\begin{aligned}"
          "$0"
          "\\end{aligned}"
          "\\$\\$"
        ];
        prefix = "aligned";
      };
      fraction = {
        body = "\\frac{$1}{$2}";
        prefix = "@/";
      };
      gathered = {
        body = [
          "\\$\\$"
          "\\begin{gathered}"
          "$0"
          "\\end{gathered}"
          "\\$\\$"
        ];
        prefix = "gathered";
      };
      partial = {
        body = "\\partial";
        prefix = "@6";
      };
    };
  };
in
{
  files = ftp;
  extraFiles = snippets // injections;
  extraPackages = with pkgs; [
    vale
  ];
  plugins = {
    lsp.servers.marksman.enable = true;
    lint.lintersByFt.markdown = [
      # "vale"
      # TODO more?
    ];
    conform-nvim.settings = {
      formatters_by_ft.markdown = [
        "mdformat"
        "injected"
      ];
      formatters = {
        mdformat = {
          "inherit" = true;
          prepend_args = [ "--number" ];
        };
      };
    };
  };
}
