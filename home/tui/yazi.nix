{
  programs.yazi = {
    enable = true;
    settings = {
      plugin.preloaders = [ ];
      plugin.prepend_previewers = [
        {
          name = "/media/**";
          run = "noop";
        }
      ];
      manager.sort_by = "natural";
    };
    keymap = {
      manager.prepend_keymap = [
        {
          on = "y";
          run = [
            ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
            "yank"
          ];
        }
        {
          on = "<C-n>";
          run = ''shell -- dragon -x -i -T "$1"'';
        }
      ];
    };
  };
}
