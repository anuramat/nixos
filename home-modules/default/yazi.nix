{ pkgs, lib, ... }:
{
  # alternative -- felix-fm -- image previews, otherwise minimal -- :help<cr> for help; waiting for picker in <https://github.com/kyoheiu/felix/issues/261>
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      plugin.preloaders = [ ];
      plugin.prepend_previewers = [
        {
          url = "/media/**";
          run = "noop";
        }
      ];
      mgr = {
        title_format = "";
        sort_by = "natural";
      };
    };
    keymap = {
      mgr.prepend_keymap = [
        # default arrow prev/next wraps around
        {
          on = "k";
          run = "arrow -1";
        }
        {
          on = "j";
          run = "arrow 1";
        }
        {
          on = "<Up>";
          run = "arrow -1";
        }
        {
          on = "<Down>";
          run = "arrow 1";
        }
        {
          on = "y";
          run = [
            ''shell -- for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list''
            "yank"
          ];
        }
        {
          on = "<C-n>";
          run = ''shell -- ${lib.getExe pkgs.dragon-drop} -x -T "$@"'';
        }
        {
          on = "<C-m>";
          run = ''shell -- ${lib.getExe pkgs.dragon-drop} -A -x -T "$@"'';
        }
      ];
    };
  };
}
