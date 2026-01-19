{
  # alternative -- felix-fm -- image previews, otherwise minimal -- :help<cr> for help; waiting for picker in <https://github.com/kyoheiu/felix/issues/261>
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      plugin.preloaders = [ ];
      plugin.prepend_previewers = [
        {
          name = "/media/**";
          run = "noop";
        }
      ];
      mgr.sort_by = "natural";
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          on = "y";
          run = [
            ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
            "yank"
          ];
        }
        # TODO use dragon-drop package instead of command
        {
          on = "<C-n>";
          run = ''shell -- dragon-drop -x -T "$@"'';
        }
        {
          on = "<C-m>";
          run = ''shell -- dragon-drop -A -x -T "$@"'';
        }
      ];
    };
  };
}
