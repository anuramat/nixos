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
    mapAttrs
    typeOf
    toJSON
    ;
  inherit (lib)
    splitString
    filter
    filterAttrs
    strings
    attrsets
    unique
    ;

  readLines = v: v |> readFile |> splitString "\n" |> filter (x: x != "");
  getSchema = attrsets.mapAttrsRecursive (_path: typeOf);
  getMatches =
    patterns: x:
    mapAttrs (
      _name: schema: if typeOf x == "set" then schema == getSchema x else schema == typeOf x
    ) patterns;

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

  mimePatterns = {
    parts = {
      prefix = "string";
      suffixes = "list";
    };
    exact = "string";
    exactList = "list";
    file = "path";
  };
  # thingie to actual mime type list
  generateMimeTypes =
    things:
    things
    |> map (
      v:
      let
        matches = getMatches mimePatterns v;
      in
      if matches.parts then
        map (suffix: "${v.prefix}/${suffix}") v.suffixes
      else if matches.exact then
        [ v ]
      else if matches.exactList then
        v
      else if matches.file then
        v |> readLines
      else
        throw "illegal pattern: ${toJSON v}"
    )
    |> concatLists;

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
