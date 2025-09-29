{ hax, ... }:
{
  files =
    let
      ftp = hax.vim.files.ftp {
        markdown = {
          cc = "+1";
          shiftwidth = 0;
          tabstop = 2;
          # TODO unmap gO
        };
      };
    in
    ftp;
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
