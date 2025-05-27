let
  # Helper function to set many mime types to the same application
  setMany =
    app: types:
    (builtins.listToAttrs (
      map (x: {
        name = x;
        value = app;
      }) types
    ));

  # Helper function to generate mime types by pattern
  generateMimeTypes =
    patterns:
    builtins.concatLists (
      map (
        pattern:
        if builtins.hasAttr "prefix" pattern && builtins.hasAttr "suffixes" pattern then
          map (suffix: "${pattern.prefix}/${suffix}") pattern.suffixes
        else if builtins.hasAttr "exact" pattern then
          [ pattern.exact ]
        else
          [ ]
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

    # Web/browser content (prioritized over image viewer for web images)
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
      # Web images that should open in browser
      {
        prefix = "image";
        suffixes = [
          "gif"
          "jpeg"
          "png"
          "webp"
        ];
      }
    ];

    # Image files (excluding web images handled by browser)
    images = generateMimeTypes [
      {
        prefix = "image";
        suffixes = [
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
        prefix = "audio";
        suffixes = [
          "aac"
          "x-aac"
          "vnd.dolby.heaac.1"
          "vnd.dolby.heaac.2"
          "aiff"
          "x-aiff"
          "m4a"
          "x-m4a"
          "mp1"
          "x-mp1"
          "mp2"
          "x-mp2"
          "mp3"
          "x-mp3"
          "mpeg"
          "mpeg2"
          "mpeg3"
          "mpegurl"
          "x-mpegurl"
          "mpg"
          "x-mpg"
          "rn-mpeg"
          "musepack"
          "x-musepack"
          "ogg"
          "scpls"
          "x-scpls"
          "vnd.rn-realaudio"
          "wav"
          "x-pn-wav"
          "x-pn-windows-pcm"
          "x-realaudio"
          "x-pn-realaudio"
          "x-ms-wma"
          "x-pls"
          "x-wav"
          "vorbis"
          "x-vorbis"
          "x-vorbis+ogg"
          "x-shorten"
          "x-ape"
          "x-wavpack"
          "x-tta"
          "AMR"
          "ac3"
          "eac3"
          "amr-wb"
          "flac"
          "mp4"
          "x-pn-au"
          "3gpp"
          "3gpp2"
          "dv"
          "opus"
          "vnd.dts"
          "vnd.dts.hd"
          "x-adpcm"
          "m3u"
          "x-matroska"
        ];
      }
    ];

    # Video files
    video = generateMimeTypes [
      {
        prefix = "video";
        suffixes = [
          "mpeg"
          "x-mpeg2"
          "x-mpeg3"
          "mp4v-es"
          "x-m4v"
          "mp4"
          "divx"
          "vnd.divx"
          "msvideo"
          "x-msvideo"
          "ogg"
          "quicktime"
          "vnd.rn-realvideo"
          "x-ms-afs"
          "x-ms-asf"
          "x-ms-wmv"
          "x-ms-wmx"
          "x-ms-wvxvideo"
          "x-avi"
          "avi"
          "x-flic"
          "fli"
          "x-flc"
          "flv"
          "x-flv"
          "x-theora"
          "x-theora+ogg"
          "x-matroska"
          "mkv"
          "webm"
          "x-ogm"
          "x-ogm+ogg"
          "mp2t"
          "3gp"
          "3gpp"
          "3gpp2"
          "dv"
          "vnd.mpegurl"
        ];
      }
    ];

    # Application-specific multimedia types
    multimedia = generateMimeTypes [
      { exact = "application/ogg"; }
      { exact = "application/x-ogg"; }
      { exact = "application/mxf"; }
      { exact = "application/sdp"; }
      { exact = "application/smil"; }
      { exact = "application/x-smil"; }
      { exact = "application/streamingmedia"; }
      { exact = "application/x-streamingmedia"; }
      { exact = "application/vnd.rn-realmedia"; }
      { exact = "application/vnd.rn-realmedia-vbr"; }
      { exact = "application/x-extension-m4a"; }
      { exact = "application/x-extension-mp4"; }
      { exact = "application/vnd.ms-asf"; }
      { exact = "application/x-matroska"; }
      { exact = "application/x-ogm"; }
      { exact = "application/x-ogm-audio"; }
      { exact = "application/x-ogm-video"; }
      { exact = "application/x-shorten"; }
      { exact = "application/x-mpegurl"; }
      { exact = "application/vnd.apple.mpegurl"; }
      { exact = "application/x-cue"; }
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
