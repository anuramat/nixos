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
    initLua = # lua
      ''
        require("toggle-pane"):entry("min-preview")
        require("exif-date"):setup()
      '';
    plugins = {
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      mime-ext = pkgs.yaziPlugins.mime-ext;
      # sorting needs every date in the directory, not just the visible ones, so a fetcher won't do
      exif-date =
        pkgs.writeTextDir "main.lua" # lua
          ''
            local M = {}

            -- maps paths to timestamps, or to false if a file has none
            local dates, sent = {}, {}

            local function pending(_)
              local paths = {}
              for i = 1, #cx.active.current.files do
                local file = cx.active.current.files[i]
                local path = tostring(file.url)
                if dates[path] == nil and not file.cha.is_dir then paths[#paths + 1] = path end
              end
              return paths
            end

            local function publish(_, paths, found)
              for _, path in ipairs(paths) do dates[path] = found[path] or false end

              local cwd, sizes, count = cx.active.current.cwd, {}, 0
              for i = 1, #cx.active.current.files do
                local file = cx.active.current.files[i]
                local date = dates[tostring(file.url)]
                if date then sizes[file.url.urn], count = date, count + 1 end
              end

              -- a size update that changes the order fires another `load`
              local key = tostring(cx.active.id) .. tostring(cwd)
              if sent[key] ~= count then
                sent[key] = count
                ya.emit("update_files", { op = fs.op("size", { url = cwd, sizes = sizes }) })
              end
              ui.render()
            end

            local pending, publish = ya.sync(pending), ya.sync(publish)

            function M:setup()
              function Linemode:exif()
                local date = dates[tostring(self._file.url)]
                return date and os.date("%Y-%m-%d %H:%M", date) or ""
              end

              local function refresh()
                local pref = cx.active.pref
                if pref.sort_by == "exif" or pref.linemode == "exif" then ya.emit("plugin", { "exif-date" }) end
              end

              ps.sub("cd", refresh)
              ps.sub("load", function(body)
                if body.stage() then refresh() end
              end)
            end

            function M:entry()
              local paths, found = pending(), {}
              if #paths > 0 then
                local out = Command("${lib.getExe pkgs.exiftool}")
                  :arg({ "-fast2", "-m", "-q", "-d", "%s", "-p", "$Directory/$FileName\t$DateTimeOriginal", "--" })
                  :arg(paths)
                  :stdout(Command.PIPED)
                  :output()
                for path, date in (out and out.stdout or ""):gmatch("([^\n]+)\t(%d+)\n") do
                  found[path] = tonumber(date)
                end
              end
              publish(paths, found)
            end

            return M
          '';
      # SLOP: show embedded jpeg in preview
      nef =
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
    };
    settings = {
      plugin = {
        preloaders = [ ];
        # file(1) reads every file, which is slow on removable media
        prepend_fetchers = [
          {
            url = "/media/**";
            run = "mime-ext.local";
            prio = "high";
            group = "mime";
          }
        ];
        prepend_previewers = [
          {
            url = "/media/**";
            run = "noop";
          }
          {
            url = "*.nef";
            run = "nef";
          }
        ];
      };
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
        {
          on = "T";
          run = "plugin toggle-pane min-preview";
          desc = "Show or hide the preview pane";
        }
        {
          on = [
            "m"
            "x"
          ];
          run = [
            "linemode exif"
            "plugin exif-date"
          ];
          desc = "Linemode: EXIF date";
        }
        {
          on = [
            ","
            "x"
          ];
          run = [
            "sort exif --reverse=no"
            "linemode exif"
            "plugin exif-date"
          ];
          desc = "Sort by EXIF date";
        }
        {
          on = [
            ","
            "X"
          ];
          run = [
            "sort exif --reverse=yes"
            "linemode exif"
            "plugin exif-date"
          ];
          desc = "Sort by EXIF date (reverse)";
        }
      ]
      ++ lib.optionals (config.gui == "wayland") [
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
