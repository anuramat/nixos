{ hax, ... }:
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
      cole = 0;
      cc = "+1";
      formatoptions = "-=w";
      shiftwidth = 0;
      tabstop = 3;
      # todo unmap gO
    };
    sh = {
      fo = null;
      ts = 4;
      et = false;
    };
    vim.fo = null;
  };
}
