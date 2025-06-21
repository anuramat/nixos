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
    lua.fo = null;
    markdown = {
      cc = "+1";
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
