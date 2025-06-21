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
  files = hax.vim.mkFTP {
    go = {
      et = false;
      ts = 4;
    };
    lua = {
      inherit fo;
    };
    markdown = {
      cc = "+1";
      # fo-=w
      shiftwidth = 0;
      tabstop = 3;
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
