{ pkgs, lib, ... }:
let
  exiftool = lib.getExe pkgs.exiftool;
in
{
  home.packages = [ pkgs.darktable ];
  xdg.configFile."darktable/luarc".source = pkgs.concatText "luarc" [
    (pkgs.replaceVars ./camera-info.lua {
      inherit exiftool;
      # interpolated to copy it alone: a bare path would become a dangling
      # reference into the flake's source
      exiftoolConfig = "${./exiftool.config}";
    })
    (pkgs.replaceVars ./strip-metadata.lua { inherit exiftool; })
  ];
}
