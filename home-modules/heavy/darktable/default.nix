{
  pkgs,
  lib,
  config,
  ...
}:
let
  exiftool = lib.getExe pkgs.exiftool;
  home = config.home.homeDirectory;
  # darktable rewrites darktablerc on exit, so these are pinned on
  # activation instead, leaving the rest of the file to darktable
  settings = pkgs.writeText "darktablerc" (
    lib.generators.toKeyValue { } {
      compress_xmp_tags = "never";
      "darkroom/ui/sidebar_scroll_default" = "TRUE";
      "plugins/ai/enabled" = "TRUE";
      "plugins/collect/filmroll_sort" = "folder name";
      "plugins/imageio/storage/disk/file_directory" =
        "${home}/darktable_export_$(YEAR)-$(MONTH)-$(DAY)/$(FILE.NAME)";
      "plugins/lighttable/act_on" = "FALSE";
      "plugins/lighttable/extended_pattern" =
        "$(FILE_NAME).$(FILE_EXTENSION) $(SIDECAR_TXT) $(NL) $(EXIF.DATE.REGIONAL) $(EXIF.TIME.REGIONAL)";
      "plugins/lighttable/thumbnail_raw_min_level" = "always";
      preview_downsampling = "original";
      run_crawler_on_start = "TRUE";
      "session/base_directory_pattern" = "${home}/img/darktable";
    }
  );
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
    ./group-leader.lua
  ];
  home.activation.darktablerc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target=${lib.escapeShellArg "${config.xdg.configHome}/darktable/darktablerc"}
    merged=$(mktemp)
    mkdir -p "$(dirname "$target")"
    touch "$target"
    ${lib.getExe pkgs.gawk} -F= '
      NR == FNR { set[$1] = $0; next }
      $1 in set { print set[$1]; delete set[$1]; next }
      1
      END { for (k in set) print set[k] }
    ' ${settings} "$target" >"$merged"
    run mv "$merged" "$target"
  '';
}
