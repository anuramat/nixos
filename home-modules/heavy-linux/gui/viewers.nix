{
  config,
  lib,
  pkgs,
  ...
}:
let
  dirPickerId = "sn.ctrl.swayimg-dir-picker";
  # prints the directory opened in yazi with Enter; nothing if quit or given anything else
  pickDir = pkgs.writeShellScript "swayimg-pick-dir" ''
    out=$(mktemp)
    trap 'rm -f "$out"' EXIT
    # no single instance: blocks until the terminal exits
    ${lib.getExe config.programs.ghostty.package} --class=${dirPickerId} \
      --gtk-single-instance=false --title='move marked images' \
      -e ${lib.getExe config.programs.yazi.package} --chooser-file="$out" "$1"
    dest=$(cat "$out")
    if [ -d "$dest" ]; then printf %s "$dest"; fi
  '';
in
{
  programs.niri.settings.window-rules = [
    {
      matches = [ { app-id = "^${lib.escapeRegex dirPickerId}$"; } ];
      open-floating = true;
    }
  ];

  programs = {
    zathura = {
      enable = true;
      options = {
        font = "monospace 14";
        adjust-open = "width";
        window-title-home-tilde = true;
        statusbar-basename = true;
        selection-clipboard = "clipboard";
        synctex = true;
        synctex-editor-command = "texlab inverse-search -i %{input} -l %{line}";
      };
    };

    mpv = {
      enable = true;
      config = {
        profile = "high-quality";
        gpu-context = "wayland";
        hwdec = "auto-safe";
        vo = "gpu";
        force-window = true;
        ytdl-format = "bestvideo+bestaudio";
      };
    };
  };

  # https://github.com/artemsen/swayimg/blob/master/CONFIG.md
  xdg.configFile."swayimg/init.lua".text = # lua
    ''
      local function shquote(s)
        return "'" .. s:gsub("'", "'\"'\"'") .. "'"
      end

      local function marked_paths()
        local paths = {}
        for _, entry in ipairs(swayimg.imagelist.get()) do
          if entry.mark then table.insert(paths, entry.path) end
        end
        return paths
      end

      local function trash(mode)
        return function()
          local paths = marked_paths()
          if #paths == 0 then
            local img = mode.get_image()
            if not img then return end
            paths = { img.path }
          end
          local trashed = 0
          for _, path in ipairs(paths) do
            if os.execute("${lib.getExe pkgs.trashy} -- " .. shquote(path)) == 0 then
              swayimg.imagelist.remove(path)
              trashed = trashed + 1
            end
          end
          swayimg.text.status = "Trashed " .. trashed .. "/" .. #paths
        end
      end
      swayimg.viewer.on_key("Shift+Delete", trash(swayimg.viewer))
      swayimg.gallery.on_key("Shift+Delete", trash(swayimg.gallery))

      local function move_marked()
        local marked = marked_paths()
        if #marked == 0 then return end
        local picker = io.popen("${pickDir} " .. shquote(marked[1]:match("(.*)/")))
        local dest = picker:read("l")
        picker:close()
        if not dest then return end
        local moved = 0
        for _, path in ipairs(marked) do
          -- never overwrites; a failed image stays marked in the list
          if os.execute("${pkgs.coreutils}/bin/mv --update=none-fail -- " .. shquote(path) .. " " .. shquote(dest .. "/")) == 0 then
            swayimg.imagelist.remove(path)
            moved = moved + 1
          end
        end
        swayimg.text.status = "Moved " .. moved .. "/" .. #marked .. " to " .. dest
      end
      swayimg.viewer.on_key("Ctrl+m", move_marked)
      swayimg.gallery.on_key("Ctrl+m", move_marked)

      -- in total uses about 1.6 GB of RAM
      swayimg.viewer.preload = 10
      swayimg.viewer.history = 10
      swayimg.gallery.preload = true
      swayimg.gallery.cache = 500
      swayimg.gallery.embedded_thumb = true
    '';

  home.packages = [ pkgs.swayimg ];
}
