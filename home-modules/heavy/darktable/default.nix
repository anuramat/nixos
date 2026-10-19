{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.darktable ];
  xdg.configFile."darktable/luarc".source = pkgs.replaceVars ./camera-info.lua {
    exiftool = lib.getExe pkgs.exiftool;
    # interpolated to copy it alone: a bare path would become a dangling
    # reference into the flake's source
    exiftoolConfig = "${./exiftool.config}";
  };
}
