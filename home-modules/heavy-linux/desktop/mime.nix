{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) splitString filter strings;

  # mime types listed in a package's desktop files
  fromDesktop =
    package:
    let
      dir = package.outPath + "/share/applications";
    in
    dir
    |> builtins.readDir
    |> lib.filterAttrs (n: _: strings.hasSuffix ".desktop" n)
    |> builtins.attrNames
    |> builtins.concatMap (
      n: dir + "/" + n |> builtins.readFile |> builtins.unsafeDiscardStringContext |> splitString "\n"
    )
    |> filter (strings.hasPrefix "MimeType=")
    |> builtins.concatMap (l: l |> strings.removePrefix "MimeType=" |> splitString ";")
    |> filter (v: v != "")
    |> lib.unique;

  assign = app: types: lib.genAttrs types (_: app);
in
{
  xdg.mimeApps = {
    enable = true;
    # never fall back to darktable
    associations.removed = assign "org.darktable.darktable.desktop" (fromDesktop pkgs.darktable);
    defaultApplications =
      assign "nvim.desktop" (
        fromDesktop pkgs.neovim
        ++ map (v: "text/${v}") [
          "css"
          "csv"
          "javascript"
          "markdown"
          "tab-separated-values"
          "vnd.graphviz"
          "vtt"
          "troff"
        ]
      )
      // assign "swayimg.desktop" (
        fromDesktop pkgs.swayimg
        ++ [
          "image/apng"
          "image/x-nikon-nef"
        ]
      )
      // assign "mpv.desktop" (fromDesktop pkgs.mpv)
      // assign "firefox.desktop" (fromDesktop pkgs.firefox)
      // assign "org.pwmt.zathura.desktop" (fromDesktop pkgs.zathura)
      // {
        "x-scheme-handler/magnet" = "transmission-gtk.desktop";
        "inode/directory" = "yazi.desktop";
      };
  };
}
