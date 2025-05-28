let
  splitString = with builtins; x: (split "\n" x |> filter (y: typeOf y == "string"));
  # or just use lib.splitString
  # reimpl so that we don't depend on lib, so that we can eval from bash scripts
  fileLines = path: (builtins.readFile path |> splitString);

  equalKeys =
    let
      getSortedKeys =
        with builtins;
        keySource:
        let
          keyList =
            if typeOf keySource == "list" then
              keySource
            else if typeOf keySource == "string" then
              [ keySource ]
            else
              attrNames keySource;
        in
        sort (l: r: l > r) keyList;
    in
    x: y: (getSortedKeys x) == (getSortedKeys y);

  # Helper function to set many mime types to the same application
  setMany =
    app: types:
    (builtins.listToAttrs (
      map (x: {
        name = x;
        value = app;
      }) types
    ));

  patternSignatures = {
    parts = [
      "prefix"
      "suffixes"
    ];
    exact = "exact";
    file = "filepath";
  };

  mkmatches = pat: builtins.mapAttrs (n: v: equalKeys pat v) patternSignatures;

  generateMimeTypes =
    patterns:
    builtins.concatLists (
      map (
        pattern:
        let
          matches = mkmatches pattern;
          x = builtins.trace matches matches;
        in
        if matches.parts then
          map (suffix: "${pattern.prefix}/${suffix}") pattern.suffixes
        else if matches.exact then
          [ pattern.exact ]
        else if matches.file then
          fileLines pattern.filepath
        else
          throw "illegal pattern"
      ) patterns
    );

  # Application desktop files
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
      { exact = "application/x-shellscript"; }
      { exact = "text/english"; }
      { exact = "text/plain"; }
      { exact = "text/markdown"; }
      {
        prefix = "text";
        suffixes = [
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
      { exact = "application/pdf"; }
      { exact = "application/rdf+xml"; }
      { exact = "application/rss+xml"; }
      { exact = "application/xhtml+xml"; }
      { exact = "application/xhtml_xml"; }
      { exact = "application/xml"; }
      { exact = "text/html"; }
      { exact = "text/xml"; }
      {
        prefix = "x-scheme-handler";
        suffixes = [
          "http"
          "https"
        ];
      }
    ];

    images = generateMimeTypes [
      {
        prefix = "image";
        suffixes = [
          "gif"
          "jpeg"
          "png"
          "webp"
          "avif"
          "bmp"
          "heic"
          "heif"
          "jxl"
          "tiff"
          "x-eps"
          "x-ico"
          "x-portable-bitmap"
          "x-portable-graymap"
          "x-portable-pixmap"
          "x-xbitmap"
          "x-xpixmap"
          "x-nikon-ref"
        ];
      }
    ];

    # Audio files
    audio = generateMimeTypes [
      {
        filepath = ./data/audio.csv;
      }
    ];

    # Video files
    video = generateMimeTypes [
      {
        filepath = ./data/video.csv;
      }
    ];

    # Application-specific multimedia types
    multimedia = generateMimeTypes [
      {
        prefix = "application";
        suffixes = [
          "ogg"
          "x-ogg"
          "mxf"
          "sdp"
          "smil"
          "x-smil"
          "streamingmedia"
          "x-streamingmedia"
          "vnd.rn-realmedia"
          "vnd.rn-realmedia-vbr"
          "x-extension-m4a"
          "x-extension-mp4"
          "vnd.ms-asf"
          "x-matroska"
          "x-ogm"
          "x-ogm-audio"
          "x-ogm-video"
          "x-shorten"
          "x-mpegurl"
          "vnd.apple.mpegurl"
          "x-cue"
        ];
      }
    ];

    # Document files (high priority for PDF to override browser)
    documents = generateMimeTypes [
      { exact = "application/pdf"; }
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
