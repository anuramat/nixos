{
  helpers,
  pkgs,
  inputs,
  ...
}:
let
  inherit (helpers.mime) setMany generateMimeTypes mimeFromDesktop;

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
    text = generateMimeTypes [
      # TODO somehow abstract this away
      (mimeFromDesktop inputs.neovim-nightly-overlay.packages.${pkgs.system}.default)
    ];

    browser = generateMimeTypes [
      (mimeFromDesktop pkgs.librewolf)
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
    # TODO test if these were required after all
    # "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
    # "x-scheme-handler/vscode" = "code-url-handler.desktop";
    "x-scheme-handler/magnet" = applications.torrentClient;
    "inode/directory" = applications.fileManager;
  };

  bulk =
    setMany applications.textEditor mimeTypes.text
    // setMany applications.imageViewer mimeTypes.images
    // setMany applications.videoPlayer mimeTypes.video
    // setMany applications.browser mimeTypes.browser
    // setMany applications.documentViewer mimeTypes.documents;
in
{
  xdg.mime = {
    enable = true;
    defaultApplications = special // bulk;
  };
}
