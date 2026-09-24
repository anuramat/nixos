{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    # SLOP: show embedded jpeg in preview
    plugins.nef =
      pkgs.writeTextDir "main.lua" # lua
        ''
          local M = {}

          function M:peek(job)
            local start, cache = os.clock(), ya.file_cache(job)
            if not cache then return end

            local ok, err = self:preload(job)
            if not ok or err then return ya.preview_widget(job, err) end

            ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))

            local _, err = ya.image_show(cache, job.area)
            ya.preview_widget(job, err)
          end

          function M:seek() end

          function M:preload(job)
            local cache = ya.file_cache(job)
            if not cache or fs.cha(cache) then return true end

            local out, err = Command("${lib.getExe pkgs.exiftool}")
              :arg({ "-b", "-JpgFromRaw", tostring(job.file.path) })
              :stdout(Command.PIPED)
              :output()
            if not out then return true, Err("Failed to start `exiftool`, error: %s", err) end

            local jpg = Url(cache .. ".jpg")
            fs.write(jpg, out.stdout)
            local ok, err = ya.image_precache(jpg, cache)
            fs.remove("file", jpg)
            return ok, err
          end

          function M:spot(job) require("file"):spot(job) end

          return M
        '';
    settings = {
      plugin.preloaders = [ ];
      plugin.prepend_previewers = [
        {
          url = "/media/**";
          run = "noop";
        }
        {
          url = "*.nef";
          run = "nef";
        }
      ];
      mgr = {
        title_format = "";
        sort_by = "natural";
      };
      preview = {
        max_width = 1920;
        max_height = 1440;
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
      ]
      ++ lib.optionals (config.gui == "wayland") [
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
