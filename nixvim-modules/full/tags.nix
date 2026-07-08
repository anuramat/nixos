{ pkgs, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.vim-gutentags ];
  extraPackages = [ pkgs.universal-ctags ];

  # only manage tags where a `tags` file already exists; never create one
  # automatically. bootstrap a project once with `ctags -R .`, then gutentags
  # maintains it incrementally on save.
  globals.gutentags_init_user_func = "GutentagsHasTags";
  extraConfigVim = ''
    function! GutentagsHasTags(file) abort
      return !empty(findfile('tags', fnamemodify(a:file, ':p:h') . ';'))
    endfunction
  '';
}
