{ pkgs, ... }:
{
  # TODO euporie (tui jupyter notebooks)
  home.packages = with pkgs; [
    # development
    gcc
    gomodifytags
    ast-grep # structural regex
    bats # bash testing
    bear # compilation database generator for clangd
    lspmux
    makefile2graph
    sem # NOTE this is from the overlay, not nixpkgs

    # kubernetes
    kubectl
    kubectx

    # network
    aircrack-ng
    ddgr # ddg search
    grpcui
    grpcurl
    mitmproxy
    nmap
    openconnect_openssl
    tshark

    # cloud/sync
    firefox-sync-client
    proton-drive-cli

    # terminal recording
    asciinema
    vhs # terminal gif generator

    # misc
    caut # codex/claude usage
    exercism # cli for exercism.org
    libqalculate # `qalc` - advanced calculator
    qrrs # generate/read QR codes
    xdg-ninja # checks $HOME for junk
    yt-dlp # download youtube videos

    # img
    exiftool # read/write EXIF metadata
    imagemagickBig # CLI image manipulation
    libwebp # tools for WebP image format

    # terminal image viewers
    chafa
    timg
    viu

    # video
    ffmpeg

    # audio
    lame # mp3
    sox # cli audio processing

    # documents
    djvulibre # djvu tools
    ghostscript # postscript/pdf utils
    glow # markdown tui viewer
    markdown-link-check # find dead md links
    mermaid-cli
    pandoc # document converter
    pdftk # more pdf tools
    poppler-utils # pdf utils
    readability-cli # extracts main content from pages
    slides # markdown presentation in terminal
    # lookatme -- slides with images; not in nixpkgs yet
    # texliveFull

    # visualization/graphics
    gnuplot
    graph-easy
    graphviz

    # fun
    banner
    cowsay
    fastfetch
    figlet # fancy banners
    fortune # random quotes
  ];
}
