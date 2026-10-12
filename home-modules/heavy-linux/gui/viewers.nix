{ lib, pkgs, ... }:
{
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
      local function trash(mode)
        return function()
          local img = mode.get_image()
          if not img then return end
          os.execute("${lib.getExe pkgs.trashy} -- '" .. img.path:gsub("'", "'\"'\"'") .. "'")
          swayimg.imagelist.remove(img.path)
          swayimg.text.status = "File removed: " .. img.path
        end
      end
      swayimg.viewer.on_key("Shift+Delete", trash(swayimg.viewer))
      swayimg.gallery.on_key("Shift+Delete", trash(swayimg.gallery))

      -- in total uses about 1.6 GB of RAM
      swayimg.viewer.preload = 10
      swayimg.viewer.history = 10
      swayimg.gallery.preload = true
      swayimg.gallery.cache = 500
      swayimg.gallery.embedded_thumb = true
    '';

  home.packages = [ pkgs.swayimg ];
}
