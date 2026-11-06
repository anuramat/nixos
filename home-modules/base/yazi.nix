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

            local function current(_) return cx.active.current.cwd end

            -- sync blocks get sets of paths: unlike tables with string keys, lists are converted in
            -- one go, which runs out of Lua references in huge directories
            local function unknown(_, paths)
              local todo = {}
              for path in pairs(paths) do
                if not tags[path] then todo[path] = true end
              end
              return todo
            end

            -- returns the sort keys of paths, if the folder has to be told about them
            local function publish(_, cwd, paths, todo, found)
              for path in pairs(todo) do tags[path] = found[path] or {} end
              ui.render()

              local by = cx.active.pref.sort_by
              if not is_exif(by) or tostring(cx.active.current.cwd) ~= cwd then return end

              local keys, count = {}, 0
              for path in pairs(paths) do
                -- files without the tag still have to overwrite the previous mode's value
                keys[path], count = tags[path][by] or 0, count + 1
              end

              -- a size update that changes the order fires another `load`
              local key, state = cx.active.id.value .. cwd, by .. count
              if next(todo) == nil and sent[key] == state then return end
              sent[key] = state
              return keys
            end

            local current, unknown, publish = ya.sync(current), ya.sync(unknown), ya.sync(publish)

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

            local function scan(paths, found)
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

            -- lists the directory itself: cx and fs.read_dir files each pin several Lua references
            -- per file while in use, which panics in huge directories
            function M:entry()
              local cwd = current()
              local out = Command("${lib.getExe' pkgs.findutils "find"}")
                :arg({ "-L", tostring(cwd), "-mindepth", "1", "-maxdepth", "1", "-not", "-type", "d", "-printf", "%f\n" })
                :stdout(Command.PIPED)
                :output()

              local urns, paths = {}, {}
              for name in (out and out.stdout or ""):gmatch("[^\n]+") do
                local path = tostring(cwd:join(name))
                urns[path], paths[path] = Path.os(name), true
              end

              local todo, found, queue, workers = unknown(paths), {}, {}, {}
              for path in pairs(todo) do queue[#queue + 1] = path end

              -- exiftool gets slower per file the more files it's given, so use small batches
              local size = math.min(256, math.ceil(#queue / 8))
              local function work()
                while #queue > 0 do
                  local batch = {}
                  for _ = 1, math.min(size, #queue) do batch[#batch + 1] = table.remove(queue) end
                  scan(batch, found)
                end
              end
              for n = 1, 8 do workers[n] = work end
              ya.join(table.unpack(workers))

              local keys = publish(tostring(cwd), paths, todo, found)
              if not keys then return end

              local sizes = {}
              for path, urn in pairs(urns) do sizes[urn] = keys[path] end
              ya.emit("update_files", { op = fs.op("size", { url = cwd, sizes = sizes }) })
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
