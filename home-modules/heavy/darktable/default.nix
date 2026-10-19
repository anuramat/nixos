{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.darktable ];
  xdg.configFile."darktable/luarc".source = pkgs.replaceVars ./camera-info.lua {
    exiftool = lib.getExe pkgs.exiftool;
    exiftoolConfig = ./exiftool.config;
  };
}
