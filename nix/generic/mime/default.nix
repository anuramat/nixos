{ lib, helpers, ... }:
with lib;
with builtins;
let
  mimeFromDesktop =
    package:
    let
      desktopFiles =
        package:
        let
          dir = (package.outPath + "/share/applications");
        in
        dir
        |> readDir
        |> filterAttrs (n: v: strings.hasSuffix ".desktop" n)
        |> attrNames
        |> map (v: dir + "/" + v);
      lineToMimes =
        line: line |> strings.removePrefix "MimeType=" |> splitString ";" |> filter (v: v != "");
    in
    package
    |> desktopFiles
    |> map helpers.readLines
    |> concatLists
    |> filter (v: strings.hasPrefix "MimeType" v)
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

  # schema for mime types thingie
  patterns = {
    parts = {
      prefix = "string";
      suffixes = "list";
    };
    exact = "string";
    file = "path";
  };

  # thingie to actual mime type list
  generateMimeTypes =
    thingies:
    thingies
    |> map (
      v:
      let
        matches = helpers.getMatches patterns v;
      in
      if matches.parts then
        map (suffix: "${v.prefix}/${suffix}") v.suffixes
      else if matches.exact then
        [ v ]
      else if matches.file then
        v |> helpers.readLines
      else
        throw "illegal pattern: ${toJSON v}"
    )
    |> concatLists;

  # TODO everything down there and also flake.nix imports?

  # application desktop files
  applications = {
    browser = "librewolf.desktop";
    fileManager = "yazi.desktop";
    documentViewer = "org.pwmt.zathura.desktop";
    textEditor = "nvim.desktop";
    imageViewer = "swayimg.desktop";
    torrentClient = "transmission-gtk.desktop";
    videoPlayer = "mpv.desktop";
  };

  # MIME type definitions organized by category
  mimeTypes = {
    # Text/code files
    text = generateMimeTypes [
      "application/x-shellscript"
      "text/english"
      "text/plain"
      "text/markdown"
      {
        prefix = "text";
        suffixes = [
          "hahameme"
          "x-c"
          "x-c++"
          "x-c++hdr"
          "x-c++src"
          "x-chdr"
          "x-csrc"
          "x-java"
          "x-makefile"
          "x-moc"
          "x-pascal"
          "x-tcl"
          "x-tex"
        ];
      }
    ];

    # Web/browser content
    browser = generateMimeTypes [
      {
        prefix = "application";
        suffixes = [
          "pdf"
          "rdf+xml"
          "xhtml+xml"
          "xml"
        ];
      }
      {
        prefix = "text";
        suffixes = [
          "html"
          "xml"
        ];
      }
      {
        prefix = "x-scheme-handler";
        suffixes = [
          "http"
          "https"
        ];
      }
    ];

    images = generateMimeTypes [
      ./data/image.csv
      {
        prefix = "image";
        suffixes = [
          "x-nikon-ref"
        ];
      }
    ];

    # Audio files
    audio = generateMimeTypes [
      ./data/audio.csv
    ];

    # Video files
    video = generateMimeTypes [
      ./data/video.csv
    ];

    # Application-specific multimedia types
    multimedia = generateMimeTypes [
      {
        prefix = "application";
        suffixes = [
          "mxf"
          "ogg"
          "sdp"
          "smil"
          "vnd.apple.mpegurl"
          "vnd.ms-asf"
        ];
      }
    ];

    # Document files (high priority for PDF to override browser)
    documents = generateMimeTypes [
      "application/pdf"
      {
        prefix = "image";
        suffixes = [
          "vnd.djvu"
          "vnd.djvu+multipage"
        ];
      }
    ];
  };

  # Build associations with proper precedence
  # Later associations override earlier ones
  associations =
    # Base associations
    setMany applications.textEditor mimeTypes.text
    // setMany applications.imageViewer mimeTypes.images
    // setMany applications.videoPlayer (mimeTypes.video ++ mimeTypes.audio ++ mimeTypes.multimedia)
    // setMany applications.browser mimeTypes.browser
    # Document viewer overrides browser for PDF
    // setMany applications.documentViewer mimeTypes.documents;
in
{
  # TODO parse .desktop files: package/share/applications:
  # MimeType=application/postscript;application/eps;application/x-eps;image/eps;image/x-eps;
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Special scheme handlers
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      "x-scheme-handler/vscode" = "code-url-handler.desktop";
      "x-scheme-handler/magnet" = applications.torrentClient;
      "inode/directory" = applications.fileManager;
    } // associations;
  };
}
