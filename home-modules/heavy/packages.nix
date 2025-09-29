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
    chafa # sixel, kitty, iterm2, blocks; faster than timg atm (ll7, 2025-06-20)
    viu # kitty, iterm2, blocks, SOON sixel
    timg # sixel, kitty, iterm2, blocks
    fontpreview

    # video
    ffmpeg-full

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
    poppler_utils # pdf utils
    pdftk # more pdf tools
    ghostscript # postscript/pdf utils
    readability-cli # extracts main content from pages
    easyocr # neural ocr
    pandoc # document converter
    typst # better latex
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
  ];
}
