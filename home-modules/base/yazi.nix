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
        require("exif"):setup()
      '';
    plugins = {
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      mime-ext = pkgs.yaziPlugins.mime-ext;
      # sorting needs the tags of every file in the directory, not just the visible ones, so a
      # fetcher won't do
      exif =
        pkgs.writeTextDir "main.lua" # lua
          ''
            local M = {}

            -- maps paths to tables of tags, keyed by sort mode and linemode; tags may be missing
            local tags, sent = {}, {}

            local function is_exif(mode) return mode == "exif-date" or mode == "exif-shutter" end

            local function tag(file, name) return (tags[tostring(file.url)] or {})[name] end

            local function pending(_)
              local paths = {}
              for i = 1, #cx.active.current.files do
                local file = cx.active.current.files[i]
                local path = tostring(file.url)
                if not tags[path] and not file.cha.is_dir then paths[#paths + 1] = path end
              end
              return paths
            end

            local function publish(_, paths, found)
              for _, path in ipairs(paths) do tags[path] = found[path] or {} end
              ui.render()

              local by = cx.active.pref.sort_by
              if not is_exif(by) then return end

              local cwd, sizes, count = cx.active.current.cwd, {}, 0
              for i = 1, #cx.active.current.files do
                local file = cx.active.current.files[i]
                if not file.cha.is_dir then
                  -- files without the tag still have to overwrite the previous mode's value
                  sizes[file.url.urn], count = tag(file, by) or 0, count + (tags[tostring(file.url)] and 1 or 0)
                end
              end

              -- a size update that changes the order fires another `load`
              local key, state = tostring(cx.active.id) .. tostring(cwd), by .. count
              if sent[key] ~= state then
                sent[key] = state
                ya.emit("update_files", { op = fs.op("size", { url = cwd, sizes = sizes }) })
              end
            end

            local pending, publish = ya.sync(pending), ya.sync(publish)

            function M:setup()
              Linemode["exif-date"] = function(self)
                local date = tag(self._file, "exif-date")
                return date and os.date("%Y-%m-%d %H:%M", date) or ""
              end
              Linemode["exif-shutter"] = function(self) return tostring(tag(self._file, "exif-shutter") or "") end

              local function refresh()
                local pref = cx.active.pref
                if is_exif(pref.sort_by) or is_exif(pref.linemode) then ya.emit("plugin", { "exif" }) end
              end

              ps.sub("cd", refresh)
              ps.sub("load", function(body)
                if body.stage() then refresh() end
              end)
            end

            function M:entry()
              local paths, found = pending(), {}
              if #paths > 0 then
                -- not -fast2, which skips the maker notes that hold the shutter count
                local out = Command("${lib.getExe pkgs.exiftool}")
                  :arg({ "-fast", "-m", "-q", "-d", "%s", "-p", "$Directory/$FileName\t$DateTimeOriginal\t$ShutterCount#", "--" })
                  :arg(paths)
                  :stdout(Command.PIPED)
                  :output()
                for path, date, shutter in (out and out.stdout or ""):gmatch("([^\n]+)\t(%d*)\t(%d*)\n") do
                  found[path] = { ["exif-date"] = tonumber(date), ["exif-shutter"] = tonumber(shutter) }
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
            "linemode exif-date"
            "plugin exif"
          ];
          desc = "Linemode: EXIF date";
        }
        {
          on = [
            ","
            "x"
          ];
          run = [
            "sort exif-date --reverse=no"
            "linemode exif-date"
            "plugin exif"
          ];
          desc = "Sort by EXIF date";
        }
        {
          on = [
            ","
            "X"
          ];
          run = [
            "sort exif-date --reverse=yes"
            "linemode exif-date"
            "plugin exif"
          ];
          desc = "Sort by EXIF date (reverse)";
        }
        {
          on = [
            "m"
            "c"
          ];
          run = [
            "linemode exif-shutter"
            "plugin exif"
          ];
          desc = "Linemode: shutter count";
        }
        {
          on = [
            ","
            "c"
          ];
          run = [
            "sort exif-shutter --reverse=no"
            "linemode exif-shutter"
            "plugin exif"
          ];
          desc = "Sort by shutter count";
        }
        {
          on = [
            ","
            "C"
          ];
          run = [
            "sort exif-shutter --reverse=yes"
            "linemode exif-shutter"
            "plugin exif"
          ];
          desc = "Sort by shutter count (reverse)";
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
