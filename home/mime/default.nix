{
  helpers,
  pkgs,
  lib,
  ...
}:
let
  inherit (import ./helpers.nix { inherit lib; }) setMany generateMimeTypes mimeFromDesktop;

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
      (mimeFromDesktop pkgs.neovim)
    ];

    browser = generateMimeTypes [
      (mimeFromDesktop pkgs.librewolf)
      # (mimeFromDesktop pkgs.google-chrome) # errors out due to context TODO
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
    defaultApplications = special // bulk;
  };
}
