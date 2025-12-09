{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    # fonts
    fira-code
    fira-code-symbols
    nerd-fonts.symbols-only
    monaspace
    iosevka

    # img
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format
    exiftool # read/write EXIF metadata
    fontpreview

    # terminal image viewers
    chafa
    viu
    timg

    # video
    ffmpeg
    losslesscut-bin

    # hardware
    libusb1 # user-mode USB access lib
    pciutils
    procps # info from /proc
    smartmontools # storage
    usbutils

    # office
    slides # markdown presentation in terminal
    # lookatme -- slides with images; not in nixpkgs yet
    tidy-viewer # csv viewer
    glow # markdown tui viewer
    poppler-utils # pdf utils
    pdftk # more pdf tools
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    pandoc # document converter
    # texliveFull
    typst # better latex
    typstyle # typst formatter TODO move/add to nixvim
    djvulibre # djvu tools
    markdown-link-check # find dead md links
    mermaid-cli

    # visualization/graphics
    graphviz
    graph-easy
    gnuplot

    # audio
    sox # cli audio processing
    lame # mp3
    audacity
  ];
}
