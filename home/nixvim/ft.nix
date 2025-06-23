{ hax, config, ... }:
let
  fo = config.opts.formatoptions;
in
{
  filetype = {
    filename = {
      "todo.txt" = "todotxt";
    };
  };
  files = hax.vim.files.ftp {
    go = {
      et = false;
      ts = 4;
    };
    lua = {
      inherit fo;
    };
    markdown = {
      cc = "+1";
      shiftwidth = 0;
      tabstop = 2;
      # TODO unmap gO
    };
    sh = {
      ts = 4;
      et = false;
      inherit fo;
    };
    vim = {
      inherit fo;
    };
  };
}
