{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./agents
    ./desktop
    ./gui
    ./packages.nix
    ./ssh-mic.nix
    ./terminals.nix
    inputs.spicetify-nix.homeManagerModules.spicetify
  ];

  stylix.icons =
    let
      dark = "Dracula";
    in
    {
      enable = true;
      inherit dark;
      light = dark; # TODO find a light theme
      package = pkgs.dracula-icon-theme;
      # package = pkgs.xfce.xfce4-icon-theme;
    };

  gui = "wayland";

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

  home.packages = with pkgs; [
    swayimg
  ];
}
