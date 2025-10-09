{ hax, ... }:
{
  files = hax.vim.files {
    markdown.ftp = {
      cc = "+1";
      shiftwidth = 0;
      tabstop = 2;
      # TODO unmap gO
    };
  };
  plugins = {
    lsp.servers.marksman.enable = true;
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
