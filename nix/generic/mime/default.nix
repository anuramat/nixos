let
  splitString = with builtins; x: (split "\n" x |> filter (y: typeOf y == "string" && y != ""));
  # or just use lib.splitString
  # reimpl so that we don't depend on lib, so that we can eval from bash scripts
  fileLines = path: (builtins.readFile path |> splitString);

  equalKeys =
    let
      getSortedKeys =
        with builtins;
        keySource:
        let
          type = typeOf keySource;
          keyList =
            if type == "list" then
              keySource
            else if type == "set" then
              attrNames keySource
            else
              throw "illegal key source of type ${type}";
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
    exact = "string";
    file = "path";
  };

  # TODO recursively do patternSignatures.smth = { field = "type"; }; then
  # verify type compatibility recursively

  mkmatches =
    with builtins;
    pat:
    mapAttrs (
      n: v: if typeOf v == "list" && typeOf pat == "set" then equalKeys pat v else (v == typeOf pat)
    ) patternSignatures;

  generateMimeTypes =
    patterns:
    builtins.concatLists (
      map (
        pattern:
        let
          matches = mkmatches pattern;
        in
        if matches.parts then
          map (suffix: "${pattern.prefix}/${suffix}") pattern.suffixes
        else if matches.exact then
          [ pattern ]
        else if matches.file then
          fileLines pattern
        else
          throw "illegal pattern: ${builtins.toJSON pattern}"
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
