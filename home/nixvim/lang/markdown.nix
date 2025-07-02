{ pkgs, hax, ... }:
{
  files = hax.vim.files.ftp {
    markdown = {
      cc = "+1";
      shiftwidth = 0;
      tabstop = 2;
      # TODO unmap gO
    };
  };
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
  extraFiles = hax.vim.files.injections {
    markdown = # query
      ''
        ;; extends

        (fenced_code_block (code_fence_content) @code_block.inner) @code_block.outer
      '';
  };
}
