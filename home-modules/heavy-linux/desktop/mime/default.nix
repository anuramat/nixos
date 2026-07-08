{
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    readFile
    readDir
    attrNames
    concatLists
    listToAttrs
    concatMap
    ;
  inherit (lib)
    splitString
    filter
    filterAttrs
    strings
    unique
    ;

  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");

  mimeFromDesktop =
    package:
    let
      dir = package.outPath + "/share/applications";
      desktopFiles =
        dir
        |> readDir
        |> filterAttrs (n: _: strings.hasSuffix ".desktop" n)
        |> attrNames
        |> map (v: dir + "/" + v);
      lineToMimes =
        line: line |> strings.removePrefix "MimeType=" |> splitString ";" |> filter (v: v != "");
    in
    desktopFiles
    |> map readLines
    |> concatLists
    |> filter (strings.hasPrefix "MimeType")
    |> map lineToMimes
    |> concatLists
    |> unique;

  # one app, many types
  setMany =
    app: types:
    types
    |> map (v: {
      name = v;
      value = app;
    })
    |> listToAttrs;

  # one thing (path/list/string/{prefix,suffixes}) to a mime type list
  toMimes =
    v:
    if builtins.isPath v then
      readLines v
    else if builtins.isList v then
      v
    else if builtins.isString v then
      [ v ]
    else
      map (suffix: "${v.prefix}/${suffix}") v.suffixes;
  generateMimeTypes = concatMap toMimes;

  applications = {
    browser = "firefox.desktop";
    fileManager = "yazi.desktop";
    documentViewer = "org.pwmt.zathura.desktop";
    textEditor = "nvim.desktop";
    imageViewer = "swayimg.desktop";
    torrentClient = "transmission-gtk.desktop";
    videoPlayer = "mpv.desktop";
    emailClient = "neomutt.desktop";
  };

  # MIME type definitions organized by category
  mimeTypes = {
    text = generateMimeTypes [
      (mimeFromDesktop pkgs.neovim)
      ./data/text.csv
    ];

    browser = generateMimeTypes [
      (mimeFromDesktop pkgs.firefox)
    ];

    images = generateMimeTypes [
      ./data/image.csv
      (mimeFromDesktop pkgs.swayimg)
      {
        prefix = "image";
        suffixes = [
          "x-nikon-ref"
        ];
      }
    ];

    video = generateMimeTypes [
      ./data/video.csv
      (mimeFromDesktop pkgs.mpv)
    ];

    documents = generateMimeTypes [
      (mimeFromDesktop pkgs.zathura)
    ];
  };

  special = {
    "x-scheme-handler/magnet" = applications.torrentClient;
    "inode/directory" = applications.fileManager;
    "x-scheme-handler/mailto" = applications.emailClient;
  };

  bulk =
    setMany applications.textEditor mimeTypes.text
    // setMany applications.imageViewer mimeTypes.images
    // setMany applications.videoPlayer mimeTypes.video
    // setMany applications.browser mimeTypes.browser
    // setMany applications.documentViewer mimeTypes.documents;
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = bulk // special;
  };
}
