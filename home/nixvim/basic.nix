{
  diagnostic.settings = {
    severity_sort = true;
    update_in_insert = true;
    signs = false;
  };
  extraConfigVim = builtins.readFile ./base.vim;
}
